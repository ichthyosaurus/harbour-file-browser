/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2016 Malte Veerman
 * SPDX-FileCopyrightText: 2019-2023 Mirian Margiani
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

#include <unistd.h>
#include <QDateTime>
#include <QTextStream>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QProcess>
#include <QtConcurrent/QtConcurrent>
#include <QFuture>
#include <QFutureWatcher>
#include <QStorageInfo>

#include "globals.h"
#include "fileworker.h"
#include "statfileinfo.h"

Engine::Engine(QObject *parent) :
    QObject(parent),
    m_progress(0),
    m__isUsingBusybox(QStringList()),
    m__checkedBusybox(false)
{
    m_diskSpaceWorkers.reserve(600);
    m_fileWorker = new FileWorker;

    // update progress property when worker progresses
    connect(m_fileWorker, &FileWorker::progressChanged, this, &Engine::setProgress);

    // pass worker end signals to QML
    connect(m_fileWorker, &FileWorker::done, this, &Engine::workerDone);
    connect(m_fileWorker, &FileWorker::errorOccurred, this, &Engine::workerErrorOccurred);
    connect(m_fileWorker, &FileWorker::fileDeleted, this, &Engine::fileDeleted);
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

void Engine::pasteFiles(QStringList files, QString destDirectory, FileClipMode::Enum mode)
{
    // TODO use FileOperations directly from QML instead

    bool isCopy = (mode == FileClipMode::Copy);
    bool isCut = (mode == FileClipMode::Cut);
    bool isLink = (mode == FileClipMode::Link);

    if (files.isEmpty()) {
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
    for (const auto& filename : std::as_const(files)) {
        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());

        // moving and source and dest filenames are the same?
        if (!(isCopy || isLink) && filename == newname) {
            emit workerErrorOccurred(tr("Cannot overwrite itself"), newname);
            return;
        }

        // dest is under source? (directory)
        if (newname.startsWith(filename) && newname != filename) {
            emit workerErrorOccurred(tr("Cannot move/copy to itself"), filename);
            return;
        }
    }

    if (isLink) {
        m_fileWorker->startSymlinkFiles(files, destDirectory);
    } else if (isCopy) {
        m_fileWorker->startCopyFiles(files, destDirectory);
    } else if (isCut) {
        m_fileWorker->startMoveFiles(files, destDirectory);
    } else {
        emit workerErrorOccurred(QStringLiteral("Bug: unknown file operation mode requested: %1").arg(mode), destDirectory);
    }
}

int Engine::runDiskSpaceWorker(std::function<void (int, QStringList)> signal,
                               std::function<QStringList (void)> function)
{
    m_diskSpaceWorkers.append({
        QSharedPointer<QFutureWatcher<QStringList>>{new QFutureWatcher<QStringList>},
        QtConcurrent::run(function)
    });

    auto& worker = m_diskSpaceWorkers.last();
    auto& future = worker.second;
    int index = m_diskSpaceWorkers.length() - 1;

    connect(worker.first.data(), &QFutureWatcherBase::finished, this, [=](){
        emit signal(index, future.result());
        m_diskSpaceWorkers[index] = {};
    });

    worker.first->setFuture(future);
    return index;
}

int Engine::requestDiskSpaceInfo(const QString& path)
{
    return runDiskSpaceWorker([&](int handle, QStringList result){
        emit diskSpaceInfoReady(handle, result);
    }, [path]() -> QStringList {
        QStorageInfo info(path);

        if (!info.isValid()) {
            return {{}, {}, {}, {}};
        }

        while (!info.isReady()) {
            qDebug() << "waiting for device to become ready..." << path;
            sleep(2);
        }

        info.refresh();
        info.bytesAvailable();

        auto total = info.bytesTotal();
        auto free = info.bytesAvailable();
        auto used = total - free;
        auto usedPercent = used / (total / 100);

        return {
            QStringLiteral("ok"),
            QStringLiteral("%1%%").arg(usedPercent),
            QStringLiteral("%1/%2").arg(filesizeToString(used), filesizeToString(total)),
            filesizeToString(free)
        };
    });
}

int Engine::requestFileSizeInfo(const QStringList& paths)
{
    return runDiskSpaceWorker([&](int handle, QStringList result){
        emit fileSizeInfoReady(handle, result);
    }, [paths]() -> QStringList {
        if (paths.isEmpty()) {
            return {{}, {}, {}, {}};
        }

        int files = 0;
        int dirs = 0;
        qint64 bytes = 0;

        auto process = [&files, &dirs, &bytes](const QString& dir){
            QDirIterator it(dir, QDir::AllEntries | QDir::System | QDir::NoDotAndDotDot | QDir::Hidden,
                            QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
            while (!it.next().isEmpty()) {
                const auto& info = it.fileInfo();
                bytes += info.size();
                if (info.isDir()) ++dirs;
                else ++files;
            }
        };

        for (const auto& i : paths) {
            auto info = QFileInfo(i);
            bytes += info.size();

            if (info.isDir()) {
                ++dirs;
                process(i);
            } else {
                ++files;
            }
        }

        return {
            QStringLiteral("ok"),
            filesizeToString(bytes),
            QString::number(dirs),
            QString::number(files)
        };
    });
}

void Engine::cancel()
{
    m_fileWorker->cancel();
}

bool Engine::exists(QString filename)
{
    if (filename.isEmpty())
        return false;

    return QFile::exists(filename);
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

QString Engine::createDirectory(QString path, QString name)
{
    if (path.isEmpty() || name.isEmpty()) {
        qWarning() << "bug: Engine::createDirectory: path or name is empty --" << path << name;
        return QLatin1Literal("");
    }

    QDir dir(path);

    if (!dir.mkpath(name)) {
        QFileInfo info(path);

        if (!info.isWritable()) {
            return tr("No permissions to create %1").arg(name);
        }
        return tr("Cannot create folder %1").arg(name);
    }

    return QLatin1Literal("");
}

QString Engine::createFile(QString path, QString name)
{
    if (path.isEmpty() || name.isEmpty()) {
        qWarning() << "bug: Engine::createFile: path or name is empty --" << path << name;
        return QLatin1Literal("");
    }

    QFileInfo info(path);

    if (!info.isWritable()) {
        return tr("No permissions to create “%1” in “%2”").arg(name, path);
    }

    QFile file(path + QStringLiteral("/") + name);

    if (file.exists()) {
        qWarning() << "bug: Engine::createFile: file already exists --" << path << name;
        return QLatin1Literal("");
    }

    if (!file.open(QFile::WriteOnly | QFile::Truncate)) {
        return tr("Cannot create file “%1” in “%2”").arg(name, path);
    }

    QTextStream out(&file);
    out << QStringLiteral("\n");
    file.close();

    return QLatin1Literal("");
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
