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

#include "texteditor.h"

#include <QFileInfo>
#include <QFile>

TextEditor::TextEditor(QObject *parent) : QObject(parent)
{
    //
}

QString TextEditor::contents()
{
    if (m_cachedContents.isEmpty()) {
        reload(false);
    }

    return m_cachedContents;
}

bool TextEditor::isReadOnly() const
{
    if (m_file.isEmpty()) return true;

    QFileInfo info(m_file);
    if (info.isWritable()) return false;
    if (info.size() > m_maximumFileSize) return false;

    return true;
}

void TextEditor::reload(bool notify)
{
    if (m_file.isEmpty()) {
        clearCachedContents(notify);
        return;
    }

    QFile file(m_file);

    if (!file.open(QFile::ReadOnly)) {
        setErrorMessage(tr("Cannot open “%1”").arg(m_file), m_readError);
        clearCachedContents(notify);
        return;
    }

    if (file.size() > m_maximumFileSize) {
        setErrorMessage(tr("File “%1” is too large to be edited").arg(m_file), m_readError);
        return;
    }

    QTextStream stream(&file);
    m_cachedContents = file.readAll();
    file.close();

    if (notify) emit contentsChanged();
}

bool TextEditor::save()
{
    if (m_file.isEmpty()) {
        setErrorMessage(tr("No file name specified"), m_writeError);
        return false;
    }

    if (isReadOnly()) {
        setErrorMessage(tr("No permission to write to “%1”").arg(m_file), m_writeError);
        return false;
    }

    QFile file(m_file);
    if (!file.open(QFile::WriteOnly | QFile::Truncate)) {
        setErrorMessage(tr("Cannot open “%1” for writing").arg(m_file), m_writeError);
        return false;
    }

    QTextStream out(&file);
    out << m_cachedContents;
    file.close();

    return true;
}

void TextEditor::setFile(QString file)
{
    m_file = file;
    emit fileChanged();
    emit isReadOnlyChanged();

    reload(true);
}

void TextEditor::setContents(QString newContents)
{
    if (newContents.isEmpty()) newContents = QLatin1Literal("\n");
    m_cachedContents = newContents;
    emit contentsChanged();
}

void TextEditor::setErrorMessage(QString message, QString category)
{
    m_errorMessage = message;
    m_errorCategory = category;
    emit errorMessageChanged();
    emit errorCategoryChanged();
}

void TextEditor::clearCachedContents(bool notify)
{
    if (m_cachedContents.isEmpty()) {
        return;
    } else {
        m_cachedContents.clear();
        if (notify) emit contentsChanged();
    }
}
