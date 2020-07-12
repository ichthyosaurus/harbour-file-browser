#ifndef GLOBALS_H
#define GLOBALS_H

#include <QString>
#include <QDateTime>
#include <QDir>
#include "statfileinfo.h"

// Global functions

QString suffixToIconName(QString suffix);
QString permissionsToString(QFile::Permissions permissions);
QString filesizeToString(qint64 filesize);
QString datetimeToString(QDateTime datetime, bool longFormat = false);

QString infoToIconName(const StatFileInfo &info);

// Always make sure to use the correct APIs!
// Since SailfishOS 3.3.x.x, GNU coreutils has been replaced by BusyBox.
QString execute(QString command, QStringList arguments, bool mergeErrorStream);

#endif // GLOBALS_H
