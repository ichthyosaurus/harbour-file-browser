#include "filemodel.h"
#include <QDateTime>
#include <QMimeType>
#include <QMimeDatabase>
#include <QSettings>
#include <QGuiApplication>
#include <unistd.h>
#include "settingshandler.h"
#include "globals.h"

enum {
    FilenameRole = Qt::UserRole + 1,
    FileKindRole = Qt::UserRole + 2,
    FileIconRole = Qt::UserRole + 3,
    PermissionsRole = Qt::UserRole + 4,
    SizeRole = Qt::UserRole + 5,
    LastModifiedRole = Qt::UserRole + 6,
    CreatedRole = Qt::UserRole + 7,
    IsDirRole = Qt::UserRole + 8,
    IsLinkRole = Qt::UserRole + 9,
    SymLinkTargetRole = Qt::UserRole + 10,
    IsSelectedRole = Qt::UserRole + 11,
    IsMatchedRole = Qt::UserRole + 12
};

FileModel::FileModel(QObject *parent) :
    QAbstractListModel(parent),
    m_selectedFileCount(0),
    m_active(false),
    m_dirty(false)
{
    m_dir = "";
    m_filterString = "";

    m_watcher = new QFileSystemWatcher(this);
    connect(m_watcher, SIGNAL(directoryChanged(const QString&)), this, SLOT(refresh()));
    connect(m_watcher, SIGNAL(fileChanged(const QString&)), this, SLOT(refresh()));

    // refresh model every time view settings are changed
    m_settings = qApp->property("settings").value<Settings*>();
    connect(m_settings, SIGNAL(viewSettingsChanged()), this, SLOT(refreshFull()));
    connect(this, SIGNAL(filterStringChanged()), this, SLOT(applyFilterString()));
}

FileModel::~FileModel()
{
}

int FileModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_files.count();
}

QVariant FileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() > m_files.size()-1)
        return QVariant();

    StatFileInfo info = m_files.at(index.row());
    switch (role) {

    case Qt::DisplayRole:
    case FilenameRole:
        return info.fileName();

    case FileKindRole:
        return info.kind();

    case FileIconRole:
        return infoToIconName(info);

    case PermissionsRole:
        return permissionsToString(info.permissions());

    case SizeRole:
        if (info.isSymLink() && info.isDirAtEnd()) return tr("dir-link");
        if (info.isDir()) return tr("dir");
        return filesizeToString(info.size());

    case LastModifiedRole:
        return datetimeToString(info.lastModified());

    case CreatedRole:
        return datetimeToString(info.created());

    case IsDirRole:
        return info.isDirAtEnd();

    case IsLinkRole:
        return info.isSymLink();

    case SymLinkTargetRole:
        return info.symLinkTarget();

    case IsSelectedRole:
        return info.isSelected();

    case IsMatchedRole:
        return info.isMatched();

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FileModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractListModel::roleNames();
    roles.insert(FilenameRole, QByteArray("filename"));
    roles.insert(FileKindRole, QByteArray("filekind"));
    roles.insert(FileIconRole, QByteArray("fileIcon"));
    roles.insert(PermissionsRole, QByteArray("permissions"));
    roles.insert(SizeRole, QByteArray("size"));
    roles.insert(LastModifiedRole, QByteArray("modified"));
    roles.insert(CreatedRole, QByteArray("created"));
    roles.insert(IsDirRole, QByteArray("isDir"));
    roles.insert(IsLinkRole, QByteArray("isLink"));
    roles.insert(SymLinkTargetRole, QByteArray("symLinkTarget"));
    roles.insert(IsSelectedRole, QByteArray("isSelected"));
    roles.insert(IsMatchedRole, QByteArray("isMatched"));
    return roles;
}

int FileModel::fileCount() const
{
    return m_files.count();
}

QString FileModel::errorMessage() const
{
    return m_errorMessage;
}

void FileModel::setDir(QString dir)
{
    if (m_dir == dir)
        return;

    // update watcher to watch the new directory
    if (!m_dir.isEmpty())
        m_watcher->removePath(m_dir);
    if (!dir.isEmpty())
        m_watcher->addPath(dir);

    m_dir = dir;

    readDirectory();
    m_dirty = false;

    emit dirChanged();
}

QString FileModel::appendPath(QString dirName)
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(dirName));
}

void FileModel::setActive(bool active)
{
    if (m_active == active)
        return;

    m_active = active;
    emit activeChanged();

    if (m_dirty)
        readDirectory();

    m_dirty = false;
}

void FileModel::setFilterString(QString newFilter)
{
    m_filterString = newFilter;
    emit filterStringChanged();
}

QString FileModel::parentPath()
{
    return QDir::cleanPath(QDir(m_dir).absoluteFilePath(".."));
}

QString FileModel::fileNameAt(int fileIndex)
{
    if (fileIndex < 0 || fileIndex >= m_files.count())
        return QString();

    return m_files.at(fileIndex).absoluteFilePath();
}

QString FileModel::mimeTypeAt(int fileIndex) {
    QString file = fileNameAt(fileIndex);

    if (file.isEmpty()) return QString();

    QMimeDatabase db;
    QMimeType type = db.mimeTypeForFile(file);
    return type.name();
}

void FileModel::toggleSelectedFile(int fileIndex)
{
    if (fileIndex >= m_files.length() || fileIndex < 0) return; // fail silently

    StatFileInfo info = m_files.at(fileIndex);

    if (!m_files.at(fileIndex).isSelected()) {
        info.setSelected(true);
        m_selectedFileCount++;
    } else {
        info.setSelected(false);
        m_selectedFileCount--;
    }

    m_files[fileIndex] = info;
    QModelIndex topLeft = index(fileIndex, 0);
    QModelIndex bottomRight = index(fileIndex, 0);
    emit dataChanged(topLeft, bottomRight);
    emit selectedFileCountChanged();
}

void FileModel::clearSelectedFiles()
{
    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        info.setSelected(false);
        // emit signal for views
        QModelIndex topLeft = index(row, 0);
        QModelIndex bottomRight = index(row, 0);
        emit dataChanged(topLeft, bottomRight);
        row++;
    }
    m_selectedFileCount = 0;
    emit selectedFileCountChanged();
}

void FileModel::selectAllFiles()
{
    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; uint count = 0;

    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        if (!info.isMatched()) {
            row++; continue;
        }

        info.setSelected(true);
        // emit signal for views
        QModelIndex topLeft = index(row, 0);
        QModelIndex bottomRight = index(row, 0);
        emit dataChanged(topLeft, bottomRight);
        row++; count++;
    }

    m_selectedFileCount = count;
    emit selectedFileCountChanged();
}

void FileModel::selectRange(int firstIndex, int lastIndex, bool selected)
{
    // fail silently if indices are invalid
    if (   firstIndex >= m_files.length()
        || firstIndex < 0
        || lastIndex >= m_files.length()
        || lastIndex < 0
       ) return;

    if (firstIndex > lastIndex) {
        int tmp = firstIndex;
        firstIndex = lastIndex;
        lastIndex = tmp;
    }

    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; int count = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();

        if (   row >= firstIndex
            && row <= lastIndex
            && info.isMatched()
            && info.isSelected() != selected) {
            info.setSelected(selected);
            // emit signal for views
            QModelIndex topLeft = index(row, 0);
            QModelIndex bottomRight = index(row, 0);
            emit dataChanged(topLeft, bottomRight);
        }

        if (info.isSelected()) count++;
        row++;
    }

    if (count != m_selectedFileCount) {
        m_selectedFileCount = count;
        emit selectedFileCountChanged();
    }
}

QStringList FileModel::selectedFiles() const
{
    if (m_selectedFileCount == 0)
        return QStringList();

    QStringList filenames;
    foreach (const StatFileInfo &info, m_files) {
        if (info.isSelected())
            filenames.append(info.absoluteFilePath());
    }
    return filenames;
}

void FileModel::refresh()
{
    if (!m_active) {
        m_dirty = true;
        return;
    }

    refreshEntries();
    m_dirty = false;
}

void FileModel::refreshFull()
{
    if (!m_active) {
        m_dirty = true;
        return;
    }

    readDirectory();
    m_dirty = false;
}

void FileModel::readDirectory()
{
    // wrapped in reset model methods to get views notified
    beginResetModel();

    m_files.clear();
    m_errorMessage = "";

    if (!m_dir.isEmpty())
        readAllEntries();

    endResetModel();
    emit fileCountChanged();
    emit errorMessageChanged();
    recountSelectedFiles();
}

void FileModel::recountSelectedFiles()
{
    int count = 0;
    foreach (const StatFileInfo &info, m_files) {
        if (info.isSelected())
            count++;
    }
    if (m_selectedFileCount != count) {
        m_selectedFileCount = count;
        emit selectedFileCountChanged();
    }
}

// see SETTINGS for details
void FileModel::applySettings(QDir &dir) {
    QString localPath = dir.absoluteFilePath(".directory");
    bool useLocal = m_settings->readVariant("View/UseLocalSettings", true).toBool();

    // filters
    bool hidden = m_settings->readVariant("View/HiddenFilesShown", false).toBool();
    if (useLocal) hidden = m_settings->readVariant("Settings/HiddenFilesShown", hidden, localPath).toBool();
    QDir::Filter hiddenFilter = hidden ? QDir::Hidden : (QDir::Filter)0;

    dir.setFilter(QDir::AllDirs | QDir::Files | QDir::NoDotAndDotDot | QDir::System | hiddenFilter);

    // sorting
    bool dirsFirst = m_settings->readVariant("View/ShowDirectoriesFirst", true).toBool();
    if (useLocal) dirsFirst = m_settings->readVariant("Sailfish/ShowDirectoriesFirst", dirsFirst, localPath).toBool();
    QDir::SortFlag dirsFirstFlag = dirsFirst ? QDir::DirsFirst : (QDir::SortFlag)0;

    QString sortSetting = m_settings->readVariant("View/SortRole", "name").toString();
    if (useLocal) sortSetting = m_settings->readVariant("Dolphin/SortRole", sortSetting, localPath).toString();
    QDir::SortFlag sortBy = QDir::Name;

    if (sortSetting == "name") {
        sortBy = QDir::Name;
    } else if (sortSetting == "size") {
        sortBy = QDir::Size;
    } else if (sortSetting == "modificationtime") {
        sortBy = QDir::Time;
    } else if (sortSetting == "type") {
        sortBy = QDir::Type;
    } else {
        sortBy = QDir::Name;
    }

    bool orderDefault = m_settings->readVariant("View/SortOrder", "default").toString() == "default";
    if (useLocal) orderDefault = m_settings->readVariant("Dolphin/SortOrder", 0, localPath) == 0 ? true : false;
    QDir::SortFlag orderFlag = orderDefault ? (QDir::SortFlag)0 : QDir::Reversed;

    bool caseSensitive = m_settings->readVariant("View/SortCaseSensitively", false).toBool();
    if (useLocal) caseSensitive = m_settings->readVariant("Sailfish/SortCaseSensitively", caseSensitive, localPath).toBool();
    QDir::SortFlag caseSensitiveFlag = caseSensitive ? (QDir::SortFlag)0 : QDir::IgnoreCase;

    dir.setSorting(sortBy | dirsFirstFlag | orderFlag | caseSensitiveFlag);
}

void FileModel::applyFilterString()
{
    QMutableListIterator<StatFileInfo> iter(m_files);
    int row = 0; int count = 0;
    while (iter.hasNext()) {
        StatFileInfo &info = iter.next();
        bool match = info.fileName().contains(m_filterString);

        if (   info.isMatched() != match
            || (!match && info.isSelected())) {

            info.setFilterMatched(match);
            if (!match) info.setSelected(false);

            // emit signal for views
            QModelIndex topLeft = index(row, 0);
            QModelIndex bottomRight = index(row, 0);
            emit dataChanged(topLeft, bottomRight);
        }

        if (info.isSelected()) count++;
        row++;
    }

    if (count != m_selectedFileCount) {
        m_selectedFileCount = count;
        emit selectedFileCountChanged();
    }
}

void FileModel::readAllEntries()
{
    QDir dir(m_dir);
    if (!dir.exists()) {
        m_errorMessage = tr("Folder does not exist");
        return;
    }
    if (!dir.isReadable()) {
        m_errorMessage = tr("No permission to read the folder");
        return;
    }

    applySettings(dir);

    QStringList fileList = dir.entryList();
    foreach (QString filename, fileList) {
        QString fullpath = dir.absoluteFilePath(filename);
        StatFileInfo info(fullpath);
        m_files.append(info);
    }

    applyFilterString();
}

void FileModel::refreshEntries()
{
    m_errorMessage = "";

    // empty dir name
    if (m_dir.isEmpty()) {
        clearModel();
        emit errorMessageChanged();
        return;
    }

    QDir dir(m_dir);
    if (!dir.exists()) {
        clearModel();
        m_errorMessage = tr("Folder does not exist");
        emit errorMessageChanged();
        return;
    }
    if (!dir.isReadable()) {
        clearModel();
        m_errorMessage = tr("No permission to read the folder");
        emit errorMessageChanged();
        return;
    }

    applySettings(dir);

    // read all files
    QList<StatFileInfo> newFiles;

    QStringList fileList = dir.entryList();
    foreach (QString filename, fileList) {
        QString fullpath = dir.absoluteFilePath(filename);
        StatFileInfo info(fullpath);
        newFiles.append(info);
    }

    int oldFileCount = m_files.count();

    // compare old and new files and do removes if needed
    for (int i = m_files.count()-1; i >= 0; --i) {
        StatFileInfo data = m_files.at(i);
        if (!filesContains(newFiles, data)) {
            beginRemoveRows(QModelIndex(), i, i);
            m_files.removeAt(i);
            endRemoveRows();
        }
    }
    // compare old and new files and do inserts if needed
    for (int i = 0; i < newFiles.count(); ++i) {
        StatFileInfo data = newFiles.at(i);
        if (!filesContains(m_files, data)) {
            beginInsertRows(QModelIndex(), i, i);
            m_files.insert(i, data);
            endInsertRows();
        }
    }

    applyFilterString();

    if (m_files.count() != oldFileCount)
        emit fileCountChanged();

    emit errorMessageChanged();
    recountSelectedFiles();
}

void FileModel::clearModel()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
    emit fileCountChanged();
}

bool FileModel::filesContains(const QList<StatFileInfo> &files, const StatFileInfo &fileData) const
{
    // check if list contains fileData with relevant info
    foreach (const StatFileInfo &f, files) {
        if (f.fileName() == fileData.fileName() &&
                f.size() == fileData.size() &&
                f.permissions() == fileData.permissions() &&
                f.lastModified() == fileData.lastModified() &&
                f.isSymLink() == fileData.isSymLink() &&
                f.isDirAtEnd() == fileData.isDirAtEnd()) {
            return true;
        }
    }
    return false;
}
