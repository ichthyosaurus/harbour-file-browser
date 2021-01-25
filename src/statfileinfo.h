/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014 Kari Pihkala
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

#ifndef STATFILEINFO_H
#define STATFILEINFO_H

#include <QFileInfo>
#include <QDateTime>
#include <QDir>
#include <sys/stat.h>

/**
 * @brief The StatFileInfo class is like QFileInfo, but has more detailed information about file types.
 */
class StatFileInfo
{
public:
    explicit StatFileInfo();
    explicit StatFileInfo(const QString &filename);
    ~StatFileInfo();

    void setFile(QString filename);
    QString fileName() const { return m_fileInfo.fileName(); }

    // these inspect the file itself without following symlinks

    // directory
    bool isDir() const { return m_fileInfo.isDir(); /*S_ISDIR(m_lstat.st_mode);*/ }
    // symbolic link
    bool isSymLink() const { return m_fileInfo.isSymLink(); /*return S_ISLNK(m_lstat.st_mode);*/ }
    // block special file
    bool isBlk() const { return S_ISBLK(m_lstat.st_mode); }
    // character special file
    bool isChr() const { return S_ISCHR(m_lstat.st_mode); }
    // pipe of FIFO special file
    bool isFifo() const { return S_ISFIFO(m_lstat.st_mode); }
    // socket
    bool isSocket() const { return S_ISSOCK(m_lstat.st_mode); }
    // regular file
    bool isFile() const { return S_ISREG(m_lstat.st_mode); }
    // system file (not a dir, regular file or symlink)
    bool isSystem() const { return !S_ISDIR(m_lstat.st_mode) && !S_ISREG(m_lstat.st_mode) &&
                                   !S_ISLNK(m_lstat.st_mode); }

    // these inspect the file or if it is a symlink, then its target end point

    // directory
    bool isDirAtEnd() const { return m_fileInfo.isDir(); /*S_ISDIR(m_stat.st_mode);*/ }
    // block special file
    bool isBlkAtEnd() const { return S_ISBLK(m_stat.st_mode); }
    // character special file
    bool isChrAtEnd() const { return S_ISCHR(m_stat.st_mode); }
    // pipe of FIFO special file
    bool isFifoAtEnd() const { return S_ISFIFO(m_stat.st_mode); }
    // socket
    bool isSocketAtEnd() const { return S_ISSOCK(m_stat.st_mode); }
    // regular file
    bool isFileAtEnd() const { return S_ISREG(m_stat.st_mode); }
    // system file (not a dir or regular file)
    bool isSystemAtEnd() const { return !S_ISDIR(m_stat.st_mode) && !S_ISREG(m_stat.st_mode); }

    // these inspect the file or if it is a symlink, then its target end point

    QString kind() const;
    QFile::Permissions permissions() const { return m_fileInfo.permissions(); }
    QString group() const { return m_fileInfo.group(); }
    uint groupId() const { return m_fileInfo.groupId(); }
    QString owner() const { return m_fileInfo.owner(); }
    uint ownerId() const { return m_fileInfo.ownerId(); }
    qint64 size() const { return m_fileInfo.size(); }
    uint dirSize() const;
    qint64 lastModifiedStat() const { return m_stat.st_mtime; }
    QDateTime lastModified() const { return m_fileInfo.lastModified(); }
    QDateTime created() const { return m_fileInfo.created(); }
    bool exists() const;
    bool isSafeToRead() const;

    // path accessors

    QDir absoluteDir() const { return m_fileInfo.absoluteDir(); }
    QString absolutePath() const { return m_fileInfo.absolutePath(); }
    QString absoluteFilePath() const { return m_fileInfo.absoluteFilePath(); }
    QString suffix() const { return m_fileInfo.suffix(); }
    QString symLinkTarget() const { return m_fileInfo.symLinkTarget(); }
    bool isSymLinkBroken() const;

    // Doomed paths will become invalid soon because the file
    // is being moved or deleted. This is not real file metadata
    // and must be set manually.
    bool isDoomed() const { return m_doomed; }
    void setDoomed(bool doomed) { m_doomed = doomed; }

    // selection
    void setSelected(bool selected);
    bool isSelected() const { return m_selected; }

    void refresh();

private:
    QString m_filename;
    QFileInfo m_fileInfo;
    struct stat m_stat; // after following possible symlinks
    struct stat m_lstat; // file itself without following symlinks
    bool m_selected;
    bool m_doomed = {false};
};

inline bool operator==(const StatFileInfo& f1, const StatFileInfo& f2)
{
    return (f1.fileName() == f2.fileName() &&
            f1.size() == f2.size() &&
            f1.permissions() == f2.permissions() &&
            f1.lastModifiedStat() == f2.lastModifiedStat() &&
            f1.isSymLink() == f2.isSymLink() &&
            f1.isDirAtEnd() == f2.isDirAtEnd());
}

inline uint qHash(const StatFileInfo& key, uint seed=10)
{
    QByteArray result;
    result.reserve(45);
    result.append(QByteArray::number(qHash(key.fileName(), seed)));
    result.append('#');
    result.append(QByteArray::number(key.size()));
    result.append('#');
    result.append(QByteArray::number(qHash(key.permissions(), seed)));
    result.append('#');
    result.append(QByteArray::number(key.lastModifiedStat()));
    result.append('#');
    result.append(key.isSymLink());
    result.append('#');
    result.append(key.isDirAtEnd());
    // qDebug() << "hashed" << f.fileName() << "to" << result << "(" << result.size() << ")";
    return qHash(result, seed);
}

#endif // STATFILEINFO_H
