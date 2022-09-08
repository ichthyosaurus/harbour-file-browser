/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2014-2015 Kari Pihkala
 * SPDX-FileCopyrightText: 2015 Benna
 * SPDX-FileCopyrightText: 2020 Mirian Margiani
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

#include "consolemodel.h"
#include "globals.h"
#include "overload_of.h"

enum {
    ModelDataRole = Qt::UserRole + 1
};

ConsoleModel::ConsoleModel(QObject *parent) :
    QAbstractListModel(parent), m_process(nullptr)
{
}

ConsoleModel::~ConsoleModel()
{
}

int ConsoleModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_lines.count();
}

QVariant ConsoleModel::data(const QModelIndex &index, int role) const
{
    Q_UNUSED(role)
    if (!index.isValid() || index.row() > m_lines.count()-1)
        return QVariant();

    QString line = m_lines.at(index.row());
    return line;
}

QHash<int, QByteArray> ConsoleModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(ModelDataRole, QByteArray("modelData"));
    return roles;
}

void ConsoleModel::setLines(QStringList lines)
{
    if (m_lines == lines)
        return;

    beginResetModel();
    m_lines = lines;
    endResetModel();

    emit linesChanged();
}

void ConsoleModel::setLines(QString lines)
{
    beginResetModel();
    m_lines = lines.split(QRegExp("[\n\r]"));
    endResetModel();
    emit linesChanged();
}

void ConsoleModel::appendLine(QString line)
{
    beginInsertRows(QModelIndex(), m_lines.count(), m_lines.count());
    m_lines.append(line);
    endInsertRows();
}

bool ConsoleModel::executeCommand(QString command, QStringList arguments)
{
    // don't execute the command if an old command is still running
    if (m_process && m_process->state() != QProcess::NotRunning) {
        // if the old process doesn't stop in 1/2 secs, then don't run the new command
        if (!m_process->waitForFinished(500))
            return false;
    }
    setLines(QStringList());
    m_process = new QProcess(this);
    m_process->setReadChannel(QProcess::StandardOutput);
    m_process->setProcessChannelMode(QProcess::MergedChannels); // merged stderr channel with stdout channel
    connect(m_process, &QProcess::readyReadStandardOutput, this, &ConsoleModel::readProcessChannels);
    connect(m_process, choose<int, QProcess::ExitStatus>::overload_of(&QProcess::finished), this, &ConsoleModel::handleProcessFinish);
    connect(m_process, choose<QProcess::ProcessError>::overload_of(&QProcess::error), this, &ConsoleModel::handleProcessError);
    m_process->start(command, arguments);
    // the process is killed when ConsoleModel is destroyed (usually when Page is closed)
    // should we run the process in bg thread to allow the command to finish(?)

    return true;
}

void ConsoleModel::readProcessChannels()
{
    while (m_process->canReadLine()) {
        QString line = m_process->readLine();
        appendLine(line);
    }
}

void ConsoleModel::handleProcessFinish(int exitCode, QProcess::ExitStatus status)
{
    if (status == QProcess::CrashExit) {
        exitCode = -99999; // special error code to catch crashes
        appendLine(tr("** crashed"));
    } else if (exitCode != 0) {
        appendLine(tr("** error: %1").arg(exitCode));
    }
    emit processExited(exitCode);
}

void ConsoleModel::handleProcessError(QProcess::ProcessError error)
{
    if (error == QProcess::FailedToStart) {
        appendLine(tr("** command “%1” not found").arg(m_process->program()));
    } else if (error == QProcess::Crashed) {
        appendLine(tr("** crashed"));
    } else if (error == QProcess::Timedout) {
        appendLine(tr("** timeout reached"));
    } else if (error == QProcess::WriteError || error == QProcess::ReadError) {
        appendLine(tr("** internal communication failed"));
    } else /*if (error == QProcess::UnknownError)*/ {
        appendLine(tr("** an unknown error occurred"));
    }
    emit processExited(-88888); // special error code to catch process errors
}
