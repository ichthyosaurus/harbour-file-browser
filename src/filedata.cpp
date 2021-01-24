/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2015 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
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

#include "filedata.h"
#include <QDir>
#include <QDateTime>
#include <QMimeDatabase>
#include <QImageReader>
#include <QSettings>
#include "globals.h"
#include "jhead/jhead-api.h"

FileData::FileData(QObject *parent) :
    QObject(parent),
    STRING_SEP(METADATA_SEPARATOR)  // defined in jhead-api.h
{
    m_file = "";
}

FileData::~FileData()
{
}

void FileData::setFile(QString file)
{
    if (m_file == file)
        return;

    m_file = file;
    readInfo();
}

QString FileData::icon() const
{
    return infoToIconName(m_fileInfo);
}

QString FileData::permissions() const
{
    return permissionsToString(m_fileInfo.permissions());
}

QString FileData::owner() const
{
    QString owner = m_fileInfo.owner();
    if (owner.isEmpty()) {
        uint id = m_fileInfo.ownerId();
        if (id != (uint)-2)
            owner = QString::number(id);
    }
    return owner;
}

QString FileData::group() const
{
    QString group = m_fileInfo.group();
    if (group.isEmpty()) {
        uint id = m_fileInfo.groupId();
        if (id != (uint)-2)
            group = QString::number(id);
    }
    return group;
}

QString FileData::size() const
{
    if (m_fileInfo.isDirAtEnd()) return "-";
    return filesizeToString(m_fileInfo.size());
}

QString FileData::modified(bool longFormat) const
{
    return datetimeToString(m_fileInfo.lastModified(), longFormat);
}

QString FileData::modifiedLong() const
{
    return modified(true);
}

QString FileData::created(bool longFormat) const
{
    return datetimeToString(m_fileInfo.created(), longFormat);
}

QString FileData::createdLong() const
{
    return created(true);
}

QString FileData::absolutePath() const
{
    if (m_file.isEmpty())
        return QString();
    return m_fileInfo.absolutePath();
}

int FileData::dirsCount() const
{
    if (!isDir()) return 0;
    QSettings settings;
    bool hiddenSetting = settings.value("View/HiddenFilesShown", false).toBool();
    QDir::Filter hidden = hiddenSetting ? QDir::Hidden : static_cast<QDir::Filter>(0);
    QDir dir(m_file);
    dir.setFilter(QDir::AllDirs | QDir::NoDotAndDotDot | hidden);
    dir.setSorting(QDir::NoSort);
    return dir.entryList().length();
}

int FileData::filesCount() const
{
    if (!isDir()) return 0;
    QSettings settings;
    bool hiddenSetting = settings.value("View/HiddenFilesShown", false).toBool();
    QDir::Filter hidden = hiddenSetting ? QDir::Hidden : static_cast<QDir::Filter>(0);
    QDir dir(m_file);
    return dir.entryList(QDir::Files | hidden, QDir::NoSort).length();
}

void FileData::refresh()
{
    readInfo();
}

bool FileData::mimeTypeInherits(QString parentMimeType) const
{
    return m_mimeType.inherits(parentMimeType);
}

QString FileData::typeCategory() const
{
    if (m_mimeTypeName.startsWith("image/")) {
        return "image";
    } else if (m_mimeTypeName.startsWith("audio/")) {
        return "audio";
    } else if (m_mimeTypeName.startsWith("video/")) {
        return "video";
    } else if (m_mimeTypeName == "application/pdf") {
        return "pdf";
    } else if (mimeTypeInherits("application/zip")) {
        return "zip";
    } else if (m_mimeTypeName == "application/vnd.sqlite3") {
        return "sqlite3";
    } else if (
           m_mimeTypeName == "application/x-tar"
        || m_mimeTypeName == "application/x-compressed-tar"
        || m_mimeTypeName == "application/x-bzip-compressed-tar") {
        return "tar";
    } else if (m_mimeTypeName == "application/x-rpm") {
        return "rpm";
    } else if (suffix() == "apk" && m_mimeTypeName == "application/vnd.android.package-archive") {
        return "apk";
    }

    return "none";
}

void FileData::readInfo()
{
    m_errorMessage = "";
    m_metaData.clear();

    m_fileInfo.setFile(m_file);

    // exists() checks for target existence in symlinks, so ignore it for symlinks
    if (!m_fileInfo.exists() && !m_fileInfo.isSymLink())
        m_errorMessage = tr("File does not exist");

    readMetaData();

    emit fileChanged();
    emit isDirChanged();
    emit isSymLinkChanged();
    emit kindChanged();
    emit iconChanged();
    emit permissionsChanged();
    emit ownerChanged();
    emit groupChanged();
    emit sizeChanged();
    emit modifiedChanged();
    emit createdChanged();
    emit absolutePathChanged();
    emit nameChanged();
    emit suffixChanged();
    emit symLinkTargetChanged();
    emit isSymLinkBrokenChanged();
    emit metaDataChanged();
    emit mimeTypeChanged();
    emit mimeTypeCommentChanged();
    emit errorMessageChanged();
}

void FileData::readMetaData()
{
    // special file types
    // do not sniff mimetype or metadata for these, because these can't really be read

    m_mimeType = QMimeType();
    if (m_fileInfo.isBlkAtEnd()) {
        m_mimeTypeName = "inode/blockdevice";
        m_mimeTypeComment = tr("block device");
        return;
    } else if (m_fileInfo.isChrAtEnd()) {
        m_mimeTypeName = "inode/chardevice";
        m_mimeTypeComment = tr("character device");
        return;
    } else if (m_fileInfo.isFifoAtEnd()) {
        m_mimeTypeName = "inode/fifo";
        m_mimeTypeComment = tr("pipe");
        return;
    } else if (m_fileInfo.isSocketAtEnd()) {
        m_mimeTypeName = "inode/socket";
        m_mimeTypeComment = tr("socket");
        return;
    } else if (m_fileInfo.isDirAtEnd()) {
        m_mimeTypeName = "inode/directory";
        m_mimeTypeComment = tr("folder");
        return;
    }

    if (!m_fileInfo.exists()) { // catch e.g. broken links
        m_mimeTypeName = "application/octet-stream";
        m_mimeTypeComment = tr("unknown");
        return;
    }

    // normal files - match content to find mimetype, which means that the file is read

    QMimeDatabase db;
    QString filename = m_fileInfo.isSymLink() ? m_fileInfo.symLinkTarget() :
                                                m_fileInfo.absoluteFilePath();
    m_mimeType = db.mimeTypeForFile(filename);
    m_mimeTypeName = m_mimeType.name();
    m_mimeTypeComment = m_mimeType.comment();

    // read metadata for images
    if (m_mimeTypeName == "image/jpeg" || m_mimeTypeName == "image/png" ||
            m_mimeTypeName == "image/gif" || m_mimeTypeName == "image/tiff" ) {
        // read size
        QImageReader reader(m_file);
        QSize s = reader.size();
        if (s.width() >= 0 && s.height() >= 0) {
            // we put these string manually in the "ImageMetaData" context
            // to reduce clutter in translation files
            QString label = QCoreApplication::translate("ImageMetaData", "Image Size");

            QString ar = calculateAspectRatio(s.width(), s.height());
            if (ar.isEmpty()) {
                addMetaData(0, label,
                            //: image size description without aspect ratio: 1=width, 2=height
                            QCoreApplication::translate("ImageMetaData", "%1 x %2").arg(s.width()).arg(s.height()));
            } else {
                addMetaData(0, label,
                            //: image size description: 1=width, 2=height, 3=aspect ratio, e.g. 16:9
                            QCoreApplication::translate("ImageMetaData", "%1 x %2 (%3)").arg(s.width()).arg(s.height()).arg(ar));
            }
        }

        // read exif data
        QStringList exif = readExifData(filename);
        foreach (QString e, exif) {
            auto split = e.split(STRING_SEP);
            QString label, value;

            if (split.length() >= 2) {
                label = split[0];
                split.removeFirst();
                value = split.join(QChar(' '));
            }

            addMetaData(8, label, value);
        }

        // read comments
        QStringList textKeys = reader.textKeys();
        foreach (QString key, textKeys) {
            QString value = reader.text(key);
            addMetaData(9, key, value);
        }
    }
}

const int aspectWidths[] = { 16, 4, 3, 5, 5,  -1 };
const int aspectHeights[] = { 9, 3, 2, 3, 4,  -1 };

QString FileData::calculateAspectRatio(int width, int height) const
{
    // Jolla Camera almost 16:9 aspect ratio
    if ((width == 3264 && height == 1840) || (height == 1840 && width == 3264)) {
        return QString("16:9");
    }

    int i = 0;
    while (aspectWidths[i] != -1) {
        if (width * aspectWidths[i] == height * aspectHeights[i] ||
                height * aspectWidths[i] == width * aspectHeights[i]) {
            return QString("%1:%2").arg(aspectWidths[i]).arg(aspectHeights[i]);
        }
        ++i;
    }
    return QString();
}

QStringList FileData::readExifData(QString filename)
{
    QByteArray ba = filename.toUtf8();
    const char *f = ba.data();
    bool error = false;
    return jhead_readJpegFile(f, &error);
}

// first char is priority (0-9), labels and values are delimited with STRING_SEP
// label and value are already translated strings
void FileData::addMetaData(uint priority, QString label, QString value)
{
    if (label.isEmpty() || value.isEmpty()) {
        // ignore: we don't want to include metadata
        // fields without value and/or without label
        return;
    }

    m_metaData.append(QString::number(priority)+label+STRING_SEP+value);
}
