/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
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

#ifndef TEXTEDITOR_H
#define TEXTEDITOR_H

#include <QObject>
#include <QTextStream>
#include <QFile>

class TextEditor : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString file READ file WRITE setFile NOTIFY fileChanged)
    Q_PROPERTY(QString contents READ contents WRITE setContents NOTIFY contentsChanged)
    Q_PROPERTY(bool isReadOnly READ isReadOnly NOTIFY isReadOnlyChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString errorCategory READ errorCategory NOTIFY errorCategoryChanged)

public:
    explicit TextEditor(QObject* parent = nullptr);

    QString file() const { return m_file; }
    QString contents();
    bool isReadOnly() const;
    QString errorMessage() const { return m_errorMessage; }
    QString errorCategory() const { return m_errorCategory; }

public slots:
    Q_INVOKABLE void reload(bool notify = true);
    Q_INVOKABLE bool save();
    void setFile(QString file);
    void setContents(QString newContents);

signals:
    void fileChanged();
    void contentsChanged();
    void isReadOnlyChanged();
    void errorMessageChanged();
    void errorCategoryChanged();

private:
    void setErrorMessage(QString message, QString category);
    void clearCachedContents(bool notify);

    QString m_file;
    QString m_cachedContents;
    QString m_errorMessage;
    QString m_errorCategory;

    const QString m_readError {QStringLiteral("read")};
    const QString m_writeError {QStringLiteral("write")};
    const int m_maximumFileSize {200*1024} /* 200 KiB */;
};

#endif // FILEIO_H
