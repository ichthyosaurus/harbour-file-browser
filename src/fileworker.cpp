/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014, 2019 Kari Pihkala
 * SPDX-FileCopyrightText: 2018 Marcin Mielniczuk
 * SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
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

#include "fileworker.h"
#include <QDateTime>

// creates a "Document (2)" numbered name from the given filename
static QString createNumberedFilename(QString filename)
{
    if (filename.isEmpty()) {
        return {}; // TODO notify
    } else if (filename.endsWith(QChar('/'))) {
        filename.chop(1);
    }

    QFileInfo fileinfo(filename);
    QString path = fileinfo.path();
    QString suffix, basename;

    if (fileinfo.isDir()) {
        basename = fileinfo.fileName();
        // there's no suffix
    } else {
        basename = fileinfo.baseName();
        suffix = fileinfo.completeSuffix();
    }

    if (!suffix.isEmpty()) {
        suffix = QStringLiteral(".")+suffix;
    }

    int number = 2;
    QString numberedFilename = QStringLiteral("%1 (%2)%3").arg(basename).arg(number).arg(suffix);
    QFileInfo newInfo(path+QStringLiteral("/")+numberedFilename);

    while (newInfo.exists() || newInfo.isSymLink()) {
        ++number;
        numberedFilename = QStringLiteral("%1 (%2)%3").arg(basename).arg(number).arg(suffix);
        newInfo.setFile(path+QStringLiteral("/")+numberedFilename);
    }

    return newInfo.absoluteFilePath();
}

FileWorker::FileWorker(QObject *parent) :
    QThread(parent),
    m_mode(DeleteMode),
    m_cancelled(KeepRunning),
    m_progress(0)
{
}

FileWorker::~FileWorker()
{
}

void FileWorker::startDeleteFiles(QStringList filenames)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    if (!validateFilenames(filenames))
        return;

    m_mode = DeleteMode;
    m_filenames = filenames;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::startCopyFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    if (!validateFilenames(filenames))
        return;

    m_mode = CopyMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::startMoveFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    if (!validateFilenames(filenames))
        return;

    m_mode = MoveMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::startSymlinkFiles(QStringList filenames, QString destDirectory)
{
    if (isRunning()) {
        emit errorOccurred(tr("File operation already in progress"), "");
        return;
    }

    if (!validateFilenames(filenames))
        return;

    m_mode = SymlinkMode;
    m_filenames = filenames;
    m_destDirectory = destDirectory;
    m_cancelled.storeRelease(KeepRunning);
    start();
}

void FileWorker::cancel()
{
    m_cancelled.storeRelease(Cancelled);
}

void FileWorker::run()
{
    switch (m_mode) {
    case SymlinkMode:
        symlinkFiles();
        break;

    case DeleteMode:
        deleteFiles();
        break;

    case MoveMode:
    case CopyMode:
        copyOrMoveFiles();
        break;
    }
}

bool FileWorker::validateFilenames(const QStringList &filenames)
{
    // basic validity check
    for (const auto& filename : filenames) {
        if (filename.isEmpty()) {
            emit errorOccurred(tr("Empty filename"), "");
            return false;
        }
    }
    return true;
}

void FileWorker::symlinkFiles()
{
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    QDir dest(m_destDirectory);
    for (const auto& filename : std::as_const(m_filenames)) {
        m_progress = 100 * fileIndex / fileCount;
        emit progressChanged(m_progress, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit errorOccurred(tr("Cancelled"), filename);
            return;
        }

        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());
        QFileInfo newInfo(newname);

        if (filename == newname) { // pasting over the source file, so copy a renamed file
            if (newInfo.exists() || newInfo.isSymLink()) {
                newname = createNumberedFilename(newname);
            }
        } else {
            // the destination exists either as a regular file/folder or as a symlink: abort
            if (newInfo.exists() || newInfo.isSymLink()) {
                emit errorOccurred(QString("Unable to overwrite existing file with symlink"), filename);
                return;
            }
        }

        QFile file(filename);
        if (!file.link(newname)) {
            emit errorOccurred(file.errorString(), filename);
            return;
        }

        fileIndex++;
    }

    m_progress = 100;
    emit progressChanged(m_progress, "");
    emit done();
}

QString FileWorker::deleteFile(QString filename)
{
    QFileInfo info(filename);
    if (!info.exists() && !info.isSymLink()) {
        return tr("File not found");
    }

    if (info.isDir() && info.isSymLink()) {
        // only delete the link and do not remove recursively subfolders
        QFile file(info.absoluteFilePath());
        bool ok = file.remove();
        if (!ok)
            return file.errorString();

    } else if (info.isDir()) {
        // this should be custom function to get better error reporting
        bool ok = QDir(info.absoluteFilePath()).removeRecursively();
        if (!ok)
            return tr("Folder delete failed");

    } else {
        QFile file(info.absoluteFilePath());
        bool ok = file.remove();
        if (!ok)
            return file.errorString();
    }
    return QString();
}

void FileWorker::deleteFiles()
{
    int fileIndex = 0;
    int fileCount = m_filenames.count();

    for (const auto& filename : std::as_const(m_filenames)) {
        m_progress = 100 * fileIndex / fileCount;
        emit progressChanged(m_progress, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit errorOccurred(tr("Cancelled"), filename);
            return;
        }

        // delete file and stop if errors
        QString errMsg = deleteFile(filename);
        if (!errMsg.isEmpty()) {
            emit errorOccurred(errMsg, filename);
            return;
        }
        emit fileDeleted(filename);

        fileIndex++;
    }

    m_progress = 100;
    emit progressChanged(m_progress, "");
    emit done();
}

void FileWorker::copyOrMoveFiles() {
    if (m_mode != CopyMode && m_mode != MoveMode) {
        emit errorOccurred("Bug: copyOrMoveFiles was called with "
                           "an invalid clipboard mode", "");
    }

    int fileIndex = 0;
    int fileCount = m_filenames.count();

    QDir dest(m_destDirectory);

    for (const auto& filename : std::as_const(m_filenames)) {
        m_progress = 100 * fileIndex / fileCount;
        emit progressChanged(m_progress, filename);

        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            emit errorOccurred(tr("Cancelled"), filename);
            return;
        }

        QFileInfo fileInfo(filename);
        QString newname = dest.absoluteFilePath(fileInfo.fileName());
        QFileInfo newInfo(newname);

        if (filename == newname) { // pasting over the source file, so copy a renamed file
            if (newInfo.exists() || newInfo.isSymLink()) {
                newname = createNumberedFilename(newname);
            }
        } else {
            // not pasting over the source file, but the destination already has the file: delete it
            if (newInfo.exists() || newInfo.isSymLink()) {
                QString errorString = deleteFile(newname);
                if (!errorString.isEmpty()) {
                    emit errorOccurred(errorString, filename);
                    return;
                }
            }
        }

        // move or copy and stop if errors

        // FIXME broken symlinks are not copied at all!

        QString errmsg = copyOrMove(filename, newname);

        if (!errmsg.isEmpty()) {
            emit errorOccurred(errmsg, filename);
            return;
        }

        fileIndex++;
    }

    m_progress = 100;
    emit progressChanged(m_progress, "");
    emit done();
}

QString FileWorker::copyOrMoveDirRecursively(QString srcDirectory, QString destDirectory)
{
    QFileInfo srcInfo(srcDirectory);
    if (srcInfo.isSymLink()) {
        // copy dir symlink by creating a new link
        QFile targetFile(srcInfo.symLinkTarget());
        if (!targetFile.link(destDirectory)) {
            return targetFile.errorString();
        }

        // move dir symlink by removing the old link
        // after creating the new link
        QFile srcFile(srcDirectory);
        if (m_mode == MoveMode && !srcFile.remove()) {
            return srcFile.errorString();
        }

        return {};
    }

    QDir srcDir(srcDirectory);
    if (!srcDir.exists()) {  // cannot be a symlink
        return tr("Source folder does not exist");
    }

    QDir destDir(destDirectory);
    if (!destDir.exists()) {  // cannot be a symlink
        QDir d(destDir);
        d.cdUp();

        if (!d.mkdir(destDir.dirName())) {
            return tr("Cannot create target folder %1").arg(destDirectory);
        }
    }

    // copy/move files
    QStringList names = srcDir.entryList(
        // the System filter is required to include broken symlinks
        QDir::Files | QDir::Hidden | QDir::System);

    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            return tr("Cancelled");
        }

        QString filename = names.at(i);
        emit progressChanged(m_progress, filename);
        QString spath = srcDir.absoluteFilePath(filename);
        QString dpath = destDir.absoluteFilePath(filename);

        // We do not (yet) support copying recursively
        // into a target folder, so we don't have to
        // handle overwriting here.
        QString errmsg = copyOrMove(spath, dpath);

        if (!errmsg.isEmpty()) {
            return errmsg;
        }
    }

    // copy/move dirs
    names = srcDir.entryList(QDir::NoDotAndDotDot | QDir::AllDirs | QDir::Hidden);
    for (int i = 0 ; i < names.count() ; ++i) {
        // stop if cancelled
        if (m_cancelled.loadAcquire() == Cancelled) {
            return tr("Cancelled");
        }

        QString filename = names.at(i);
        emit progressChanged(m_progress, filename);
        QString spath = srcDir.absoluteFilePath(filename);
        QString dpath = destDir.absoluteFilePath(filename);
        QString errmsg = copyOrMoveDirRecursively(spath, dpath);

        if (!errmsg.isEmpty()) {
            return errmsg;
        }
    }

    if (m_mode == MoveMode) {
        if (!srcDir.removeRecursively()) {
            return tr("Failed to remove source folder "
                      "“%1” after moving.").arg(srcDirectory);
        }
    }

    return {};
}

QString FileWorker::copyOrMove(QString src, QString dest) {
    // IMPORTANT This method does *not* overwrite existing
    // items. Make sure to either remove existing targets,
    // or generate a non-colliding target name before
    // calling this method.
    //
    // IMPORTANT This method does *not* verify that the
    // current mode is MoveMode or CopyMode. It copies by
    // default, and moves if mode is MoveMode.

    QFileInfo fileInfo(src);

    if (fileInfo.isSymLink()) {
        // copy symlink by creating a new link
        QFile linkTarget(fileInfo.symLinkTarget());
        if (!linkTarget.link(dest)) {
            return linkTarget.errorString();
        }

        // move symlink by removing the old link
        // after creating the new link
        QFile srcFile(src);
        if (m_mode == MoveMode && !srcFile.remove()) {
            return srcFile.errorString();
        }

        return {};
    } else if (fileInfo.isDir()) {
        return copyOrMoveDirRecursively(src, dest);
    } else {
        QFile sfile(src);

        if (m_mode == MoveMode) {
            if (!sfile.rename(dest)) {
                return sfile.errorString();
            }
        } else { // CopyMode
            if (!sfile.copy(dest)) {
                return sfile.errorString();
            }
        }
    }

    return {};
}
