/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2016, 2018-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Malte Veerman
 * SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * File Browser is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * File Browser is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <https://www.gnu.org/licenses/>.
 */

#include "engine.h"
#include <QDateTime>
#include <QTextStream>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QProcess>
#include <unistd.h>
#include "globals.h"
#include "fileworker.h"
#include "statfileinfo.h"
#include "settingshandler.h"

Engine::Engine(QObject *parent) :
    QObject(parent),
    m_clipboardContainsCopy(false),
    m_progress(0),
    m__isUsingBusybox(QStringList()),
    m__checkedBusybox(false)
{
    m_fileWorker = new FileWorker;
    m_settings = qApp->property("settings").value<Settings*>();

    // update progress property when worker progresses
    connect(m_fileWorker, SIGNAL(progressChanged(int, QString)),
            this, SLOT(setProgress(int, QString)));

    // pass worker end signals to QML
    connect(m_fileWorker, SIGNAL(done()), this, SIGNAL(workerDone()));
    connect(m_fileWorker, SIGNAL(errorOccurred(QString, QString)),
            this, SIGNAL(workerErrorOccurred(QString, QString)));
    connect(m_fileWorker, SIGNAL(fileDeleted(QString)), this, SIGNAL(fileDeleted(QString)));
}

Engine::~Engine()
{
    m_fileWorker->cancel(); // ask the background thread to exit its loop
    // is this the way to force stop the worker thread?
    m_fileWorker->wait();   // wait until thread stops
    m_fileWorker->deleteLater();    // delete it
}

void Engine::deleteFiles(QStringList filenames)
{
    setProgress(0, "");
    m_fileWorker->startDeleteFiles(filenames);
}

void Engine::cutFiles(QStringList filenames)
{
    m_clipboardFiles = filenames;
    m_clipboardContainsCopy = false;
    emit clipboardCountChanged();
    emit clipboardContainsCopyChanged();
}

void Engine::copyFiles(QStringList filenames)
{
    // don't copy special files (chr/blk/fifo/sock)
    QMutableStringListIterator i(filenames);
    while (i.hasNext()) {
        QString filename = i.next();
        StatFileInfo info(filename);
        if (info.isSystem())
            i.remove();
    }

    m_clipboardFiles = filenames;
    m_clipboardContainsCopy = true;
    emit clipboardCountChanged();
    emit clipboardContainsCopyChanged();
}

QStringList Engine::listExistingFiles(QString destDirectory)
{
    if (m_clipboardFiles.isEmpty()) {
        return QStringList();
    }
    QDir dest(destDirectory);
    if (!dest.exists()) {
        return QStringList();
    }

    QStringList existingFiles;
    foreach (QString filename, m_clipboardFiles) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // source and dest filenames are the same? let pasteFiles() create a numbered copy for it.
        if (filename == newname) {
            continue;
        }

        // dest is under source? (directory) let pasteFiles() return an error.
        if (newname.startsWith(filename)) {
            return QStringList();
        }
        if (QFile::exists(newname)) {
            existingFiles.append(fileInfo.fileName());
        }
    }
    return existingFiles;
}

void Engine::pasteFiles(QString destDirectory, bool asSymlinks)
{
    if (m_clipboardFiles.isEmpty()) {
        emit workerErrorOccurred(tr("No files to paste"), "");
        return;
    }

    setProgress(0, "");

    QDir dest(destDirectory);
    if (!dest.exists()) {
        emit workerErrorOccurred(tr("Destination does not exist"), destDirectory);
        return;
    }

    // validate that the files can be pasted
    foreach (QString filename, m_clipboardFiles) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // moving and source and dest filenames are the same?
        if (!m_clipboardContainsCopy && filename == newname) {
            emit workerErrorOccurred(tr("Cannot overwrite itself"), newname);
            return;
        }

        // dest is under source? (directory)
        if (newname.startsWith(filename) && newname != filename) {
            emit workerErrorOccurred(tr("Cannot move/copy to itself"), filename);
            return;
        }
    }

    QStringList files = m_clipboardFiles;
    m_clipboardFiles.clear();
    emit clipboardCountChanged();

    if (asSymlinks) {
        m_fileWorker->startSymlinkFiles(files, destDirectory);
    } else if (m_clipboardContainsCopy) {
        m_fileWorker->startCopyFiles(files, destDirectory);
    } else {
        m_fileWorker->startMoveFiles(files, destDirectory);
    }
}

void Engine::cancel()
{
    m_fileWorker->cancel();
}

static QStringList subdirs(const QString &dirname, bool includeHidden = false)
{
    QDir dir(dirname);
    if (!dir.exists()) return QStringList();

    QDir::Filter hiddenFilter = includeHidden ? QDir::Hidden : static_cast<QDir::Filter>(0);
    dir.setFilter(QDir::AllDirs | QDir::NoDotAndDotDot | hiddenFilter);

    QStringList list = dir.entryList();
    QStringList abslist;
    foreach (QString relpath, list) {
        abslist.append(dir.absoluteFilePath(relpath));
    }
    return abslist;
}

QString Engine::androidDataPath() const
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::HomeLocation)+"/android_storage";
    QDir dir(path);
    if (!dir.exists()) return QString();
    return path;
}

QVariantList Engine::externalDrives() const
{
    QVariantList devices;

    // from SailfishOS 2.2.0 onwards, "/media/sdcard" is
    // a symbolic link instead of a folder. In that case, follow the link
    // to the actual folder.
    QString sdcardFolder = "/media/sdcard";
    QFileInfo fileinfo(sdcardFolder);
    if (fileinfo.isSymLink()) sdcardFolder = fileinfo.symLinkTarget();

    // get sdcard dir candidates for "/media/sdcard" (or its symlink target)
    QStringList candidates = subdirs(sdcardFolder);

    // If the base folder is not already /run/media/USER, we add it too. This
    // is where OTG devices will be mounted.
    // Also, some users may have a symlink from "/media/sdcard/USER"
    // (not from "/media/sdcard"), which means no SD cards would be found before,
    // so we also get candidates for those users.
    QString expectedUserFolder = QString("/run/media/") + QDir::home().dirName();
    if (sdcardFolder != expectedUserFolder) candidates.append(subdirs(expectedUserFolder));

    // no candidates found, abort
    if (candidates.isEmpty()) return QVariantList();

    // remove all directories which are not mount points
    QMap<QString, QString> mps = mountPoints();
    QMutableStringListIterator i(candidates);
    while (i.hasNext()) {
        QString dirname = i.next();
        if (!mps.contains(dirname)) i.remove();
    }

    // all candidates eliminated, abort
    if (candidates.isEmpty()) return QVariantList();

    foreach (QString drive, candidates) {
        QVariantMap data;
        data.insert("path", drive);

        if (mps[drive].startsWith("/dev/mmc")) {
            data.insert("title", QObject::tr("SD card"));
        } else {
            data.insert("title", QObject::tr("Removable Media"));
        }

        devices << data;
    }

    return devices;
}

QString Engine::storageSettingsPath()
{
#ifdef NO_FEATURE_STORAGE_SETTINGS
    return QStringLiteral("");
#else
    if (!m_storageSettingsPath.isEmpty()) return m_storageSettingsPath;

    // This should normally be </usr/share/>jolla-settings/pages/storage/storage.qml.
    // The result will be empty if the file is missing or cannot be accessed, e.g
    // due to sandboxing. Therefore, we don't need compile-time switches to turn it off.
    m_storageSettingsPath = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                                                   "jolla-settings/pages/storage/storage.qml",
                                                   QStandardPaths::LocateFile);
    return m_storageSettingsPath;
#endif
}

QString Engine::pdfViewerPath()
{
#ifdef NO_FEATURE_PDF_VIEWER
    return QStringLiteral("");
#else
    if (!m_pdfViewerPath.isEmpty()) return m_pdfViewerPath;

    // This requires access to the system documents viewer.
    // The feature will be disabled if core QML files are missing or cannot be
    // accessed, e.g due to sandboxing. Therefore, we don't need compile-time
    // switches to turn it off.

    m_pdfViewerPath = QStringLiteral("Sailfish.Office.PDFDocumentPage");

    if (!QFileInfo::exists(
                QStringLiteral("/usr/lib/") +
                QStringLiteral("qt5/qml/Sailfish/Office/PDFDocumentPage.qml"))) {
        if (!QFileInfo::exists(
                    QStringLiteral("/usr/lib64/") +
                    QStringLiteral("qt5/qml/Sailfish/Office/PDFDocumentPage.qml"))) {
            m_pdfViewerPath = QStringLiteral("");
        }
    }

    return m_pdfViewerPath;
#endif
}

bool Engine::runningAsRoot()
{
    if (geteuid() == 0) return true;
    return false;
}

bool Engine::exists(QString filename)
{
    if (filename.isEmpty())
        return false;

    return QFile::exists(filename);
}

QStringList Engine::fileSizeInfo(QStringList paths)
{
    if (paths.isEmpty()) return QStringList() << "-" << "0" << "0";

    QStringList result;

    // determine disk usage
    // cf. docs on Engine::isUsingBusybox
    QString diskusage = execute("/usr/bin/du", QStringList() << paths <<
                                (isUsingBusybox("du") ? "-k" : "--bytes") <<
                                "-x" << "-s" << "-c" << "-L", false);
    QStringList duLines = diskusage.split(QRegExp("[\n\r]"));

    if (duLines.length() < 2) {
        result << "-"; // got an invalid result
    } else {
        QString duTotalStr = duLines.at(duLines.count()-2).split(QRegExp("[\\s]+"))[0].trimmed();
        qint64 duTotal = duTotalStr.toLongLong() * (isUsingBusybox("du") ? 1024LL : 1LL); // BusyBox cannot show the real byte count
        result << (duTotal > 0 ? filesizeToString(duTotal) : "-");
    }

    // count dirs
    QString dirs = execute("/bin/find", QStringList() << "-L" << paths << "-type" << "d", false); // same for BusyBox
    result << QString::number(dirs.split(QRegExp("[\n\r]")).count()-1);

    // count files
    QString files = execute("/bin/find", QStringList() << "-L" << paths << "(" << "-type" << "f" << "-or" << "-type" << "l" << ")", false); // same for BusyBox
    result << QString::number(files.split(QRegExp("[\n\r]")).count()-1);

    return result;
}

QStringList Engine::diskSpace(QString path)
{
    if (path.isEmpty())
        return QStringList();

    // return no disk space for sdcard parent directory
    if (path == "/media/sdcard")
        return QStringList();

    // run df in POSIX mode for the given path to get disk space
    // cf. docs on Engine::isUsingBusybox
    QString blockSize = isUsingBusybox("df") ? "-k" : "--block-size=1024";
    QString result = execute("/bin/df", QStringList() << "-P" << blockSize << path, false);
    if (result.isEmpty())
        return QStringList();

    // split result to lines
    QStringList lines = result.split(QRegExp("[\n\r]"));
    if (lines.count() < 2)
        return QStringList();

    // get second line and its columns
    QString line = lines.at(1);
    QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
    if (columns.count() < 5)
        return QStringList();

    QString totalString = columns.at(1);
    QString usedString = columns.at(2);
    QString percentageString = columns.at(4);
    qint64 total = totalString.toLongLong() * 1024LL;
    qint64 used = usedString.toLongLong() * 1024LL;

    return QStringList() << percentageString << filesizeToString(used)+"/"+filesizeToString(total);
}

QStringList Engine::readFile(QString filename)
{
    int maxLines = 1000;
    int maxSize = 10240;
    int maxBinSize = 2048;

    // check existence
    StatFileInfo fileInfo(filename);
    if (!fileInfo.exists()) {
        if (!fileInfo.isSymLink())
            return makeStringList(tr("File does not exist") + "\n" + filename);
        else
            return makeStringList(tr("Broken symbolic link") + "\n" + filename);
    }

    // don't read unsafe system files
    if (!fileInfo.isSafeToRead()) {
        return makeStringList(tr("Cannot read this type of file") + "\n" + filename);
    }

    // check permissions
    QFileInfo info(filename);
    if (!info.isReadable())
        return makeStringList(tr("No permission to read the file") + "\n" + filename);

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return makeStringList(tr("Error reading file") + "\n" + filename);

    // read start of file
    char buffer[maxSize+1];
    qint64 readSize = file.read(buffer, maxSize);
    if (readSize < 0)
        return makeStringList(tr("Error reading file") + "\n" + filename);

    if (readSize == 0)
        return makeStringList(tr("Empty file"));

    bool atEnd = file.atEnd();
    file.close();

    // detect binary or text file, it is binary if it contains zeros
    bool isText = true;
    for (int i = 0; i < readSize; ++i) {
        if (buffer[i] == 0) {
            isText = false;
            break;
        }
    }

    // binary output
    if (!isText) {
        // two different line widths
        if (readSize > maxBinSize) {
            readSize = maxBinSize;
            atEnd = false;
        }
        QString out8 = createHexDump(buffer, readSize, 8);
        QString out16 = createHexDump(buffer, readSize, 16);
        QString msg = "";

        if (!atEnd) {
            msg = tr("Binary file preview clipped at %1 kB").arg(maxBinSize/1024);
        }

        return QStringList() << msg << out8 << out16;
    }

    // read lines to a string list and join
    QByteArray ba(buffer, readSize);
    QTextStream in(&ba);
    QStringList lines;
    int lineCount = 0;
    while (!in.atEnd() && lineCount < maxLines) {
        QString line = in.readLine();
        lines.append(line);
        lineCount++;
    }

    QString msg = "";
    if (lineCount == maxLines) {
        msg = tr("Text file preview clipped at %1 lines").arg(maxLines);
    } else if (!atEnd) {
        msg = tr("Text file preview clipped at %1 kB").arg(maxSize/1024);
    }

    return makeStringList(msg, lines.join("\n"));
}

QString Engine::mkdir(QString path, QString name)
{
    QDir dir(path);

    if (!dir.mkdir(name)) {
        QFileInfo info(path);
        if (!info.isWritable())
            return tr("No permissions to create %1").arg(name);

        return tr("Cannot create folder %1").arg(name);
    }

    return QString();
}

QStringList Engine::rename(QString fullOldFilename, QString newName)
{
    QFile file(fullOldFilename);
    QFileInfo fileInfo(fullOldFilename);
    QDir dir = fileInfo.absoluteDir();
    QString fullNewFilename = dir.absoluteFilePath(newName);

    QString errorMessage;
    if (!file.rename(fullNewFilename)) {
        QString oldName = fileInfo.fileName();
        errorMessage = tr("Cannot rename %1").arg(oldName) + "\n" + file.errorString();
    }

    return QStringList() << fullNewFilename << errorMessage;
}

QString Engine::chmod(QString path,
                      bool ownerRead, bool ownerWrite, bool ownerExecute,
                      bool groupRead, bool groupWrite, bool groupExecute,
                      bool othersRead, bool othersWrite, bool othersExecute)
{
    QFile file(path);
    QFileDevice::Permissions p;
    if (ownerRead) p |= QFileDevice::ReadOwner;
    if (ownerWrite) p |= QFileDevice::WriteOwner;
    if (ownerExecute) p |= QFileDevice::ExeOwner;
    if (groupRead) p |= QFileDevice::ReadGroup;
    if (groupWrite) p |= QFileDevice::WriteGroup;
    if (groupExecute) p |= QFileDevice::ExeGroup;
    if (othersRead) p |= QFileDevice::ReadOther;
    if (othersWrite) p |= QFileDevice::WriteOther;
    if (othersExecute) p |= QFileDevice::ExeOther;
    if (!file.setPermissions(p))
        return tr("Cannot change permissions") + "\n" + file.errorString();

    return QString();
}

bool Engine::openNewWindow(QStringList arguments) const
{
    QFileInfo info(QCoreApplication::applicationFilePath());

    if (!info.exists() || !info.isFile()) {
        return false;
    } else {
        return QProcess::startDetached(info.absoluteFilePath(), arguments);
    }
}

bool Engine::pathIsDirectory(QString path) const
{
    StatFileInfo info(path);
    return info.isDirAtEnd();
}

bool Engine::pathIsFile(QString path) const
{
    StatFileInfo info(path);
    return info.isFileAtEnd();
}

void Engine::setProgress(int progress, QString filename)
{
    m_progress = progress;
    m_progressFilename = filename;
    emit progressChanged();
    emit progressFilenameChanged();
}

QMap<QString, QString> Engine::mountPoints() const
{
    // read /proc/mounts and return all mount points for the filesystem
    QFile file("/proc/mounts");
    if (!file.open(QFile::ReadOnly | QFile::Text))
        return QMap<QString, QString>();

    QTextStream in(&file);
    QString result = in.readAll();

    // split result to lines
    QStringList lines = result.split(QRegExp("[\n\r]"));

    // get columns
    QMap<QString, QString> paired;
    foreach (QString line, lines) {
        QStringList columns = line.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        if (columns.count() < 6) continue; // sanity check
        paired[columns.at(1)] = columns.at(0);
    }

    return paired;
}

QString Engine::createHexDump(char *buffer, int size, int bytesPerLine)
{
    QString out;
    QString ascDump;
    int i;
    for (i = 0; i < size; ++i) {
        if ((i % bytesPerLine) == 0) { // line change
            out += " "+ascDump+"\n"+
                    QString("%1").arg(QString::number(i, 16), 4, QLatin1Char('0'))+": ";
            ascDump.clear();
        }

        out += QString("%1").arg(QString::number((unsigned char)buffer[i], 16),
                                       2, QLatin1Char('0'))+" ";
        if (buffer[i] >= 32 && buffer[i] <= 126)
            ascDump += buffer[i];
        else
            ascDump += ".";
    }
    // write out remaining asc dump
    if ((i % bytesPerLine) > 0) {
        int emptyBytes = bytesPerLine - (i % bytesPerLine);
        for (int j = 0; j < emptyBytes; ++j) {
            out += "   ";
        }
    }
    out += " "+ascDump;

    return out;
}

QStringList Engine::makeStringList(QString msg, QString str)
{
    QStringList list;
    list << msg << str << str;
    return list;
}

bool Engine::isUsingBusybox(QString forCommand)
{
    // from SailfishOS 3.3.x.x onwards, GNU coreutils have been replaced
    // by BusyBox. This means e.g. 'du' no longer recognizes the options we need...

    if (m__checkedBusybox) return m__isUsingBusybox.contains(forCommand);

    if (!QFile::exists("/bin/busybox")) {
        m__isUsingBusybox = QStringList();
    } else {
        QString result = execute("/bin/busybox", QStringList() << "--list", false);
        if (result.isEmpty()) {
            m__isUsingBusybox = QStringList();
        } else {
            // split result to lines
            m__isUsingBusybox = result.split(QRegExp("[\n\r]"));
        }
    }

    m__checkedBusybox = true;
    return isUsingBusybox(forCommand);
}
