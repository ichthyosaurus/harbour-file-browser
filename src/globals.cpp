/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
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

#include "globals.h"
#include <cmath>
#include <QCoreApplication>
#include <QLocale>
#include <QProcess>

QString suffixToIconName(QString suffix)
{
    // only formats that are understood by File Browser or Sailfish get a special icon
    if (suffix == "txt") return "file-txt";
    if (suffix == "rpm") return "file-rpm";
    if (suffix == "apk") return "file-apk";
    if (suffix == "pdf") return "file-pdf";
    if (   suffix == "png"
        || suffix == "jpeg"
        || suffix == "jpg"
        || suffix == "gif") return "file-image";
    // if (   suffix == "odt") return "file-document";
    if (   suffix == "mp3"
        || suffix == "ogg"
        || suffix == "opus"
        || suffix == "aac"
        || suffix == "flac"
        || suffix == "wav"
        || suffix == "m4a") return "file-audio";
    if (   suffix == "mp4"
        || suffix == "mkv"
        || suffix == "ogv"
        || suffix == "avi"
        || suffix == "m4v") return "file-video";
    if (   suffix == "zip"
        || suffix == "tar"
        || suffix == "gz"
        || suffix == "bz2"
        || suffix == "xz") return "file-compressed";

    return "file";
}

QString permissionsToString(QFile::Permissions permissions)
{
    char str[] = "---------";
    if (permissions & 0x4000) str[0] = 'r';
    if (permissions & 0x2000) str[1] = 'w';
    if (permissions & 0x1000) str[2] = 'x';
    if (permissions & 0x0040) str[3] = 'r';
    if (permissions & 0x0020) str[4] = 'w';
    if (permissions & 0x0010) str[5] = 'x';
    if (permissions & 0x0004) str[6] = 'r';
    if (permissions & 0x0002) str[7] = 'w';
    if (permissions & 0x0001) str[8] = 'x';
    return QString::fromLatin1(str);
}

namespace {
Q_GLOBAL_STATIC_WITH_ARGS(QStringList, fileSizeNames, ({
    QCoreApplication::translate("FileSize", "B"),
    QCoreApplication::translate("FileSize", "KiB"),
    QCoreApplication::translate("FileSize", "MiB"),
    QCoreApplication::translate("FileSize", "GiB"),
    QCoreApplication::translate("FileSize", "TiB"),
    QCoreApplication::translate("FileSize", "PiB"),
    QCoreApplication::translate("FileSize", "EiB"),
    QCoreApplication::translate("FileSize", "ZiB"),
    QCoreApplication::translate("FileSize", "YiB"),
}));
}

QString filesizeToString(qint64 filesize)
{
    // convert to KiB, MiB, GiB: we follow SI and use 1024 as divisor.
    // Values are called properly *bibyte instead of **byte, i.e. kibibyte.
    QLocale locale;
    QStringListIterator i(*fileSizeNames);
    QString unit(i.next()); // = first

    uint power = 0;
    while (filesize >= pow(1024, power+1) && i.hasNext()) {
        unit = i.next();
        power++;
    }

    if (filesize < 1024LL) {
        //: 1=file size (number), 2=unit (e.g. KiB)
        return QCoreApplication::translate("FileSize", "%1 %2").
                arg(locale.toString(filesize), unit);
    } else {
        auto num = static_cast<double>(filesize)/pow(1024, power);
        return QCoreApplication::translate("FileSize", "%1 %2").
                arg(locale.toString(num, 'f', 2), unit);
    }
}

QString datetimeToString(QDateTime datetime, bool longFormat)
{
    // return time for today or date+time for older
    // include more information if 'longFormat' is true
    if (datetime.date() == QDate::currentDate()) {
        return datetime.toString(QObject::tr("hh:mm:ss"));
    } else {
        if (longFormat) {
            return datetime.toString(QObject::tr("dd MMM yyyy, hh:mm:ss t"));
        } else {
            return datetime.toString(QObject::tr("dd.MM.yy, hh:mm"));
        }
    }
}

QString infoToIconName(const StatFileInfo &info)
{
    if (info.isSymLink() && info.isDirAtEnd()) return "folder-link";
    if (info.isDir()) return "folder";
    if (info.isSymLink()) return "link";
    if (info.isFileAtEnd()) {
        QString suffix = info.suffix().toLower();
        return suffixToIconName(suffix);
    }
    return "file";
}

QString execute(QString command, QStringList arguments, bool mergeErrorStream)
{
    // Always make sure to use the correct APIs!
    // Since SailfishOS 3.3.x.x, GNU coreutils has been replaced by BusyBox.

    QProcess process;
    process.setReadChannel(QProcess::StandardOutput);
    if (mergeErrorStream)
        process.setProcessChannelMode(QProcess::MergedChannels);
    process.start(command, arguments);
    if (!process.waitForStarted())
        return QString();
    if (!process.waitForFinished())
        return QString();

    QByteArray result = process.readAll();
    return QString::fromUtf8(result);
}
