/*
 * This file is part of File Browser.
 *
 * SPDX-FileCopyrightText: 2013-2014 Kari Pihkala
 * SPDX-FileCopyrightText: 2019-2024 Mirian Margiani
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef FILEDATA_H
#define FILEDATA_H

#include <QObject>
#include <QMimeType>
#include "statfileinfo.h"

/**
 * @brief The FileData class provides info about one file.
 */
class FileData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString file READ file() WRITE setFile(QString) NOTIFY fileChanged())
    Q_PROPERTY(bool exists READ exists() NOTIFY existsChanged())
    Q_PROPERTY(bool isDir READ isDir() NOTIFY isDirChanged())
    Q_PROPERTY(bool isFile READ isFile() NOTIFY isFileChanged())
    Q_PROPERTY(bool isSymLink READ isSymLink() NOTIFY isSymLinkChanged())
    Q_PROPERTY(QString kind READ kind() NOTIFY kindChanged())
    Q_PROPERTY(QString category READ typeCategory NOTIFY categoryChanged)
    Q_PROPERTY(QString icon READ icon() NOTIFY iconChanged())
    Q_PROPERTY(QString permissions READ permissions() NOTIFY permissionsChanged())
    Q_PROPERTY(bool isWritable READ isWritable() NOTIFY isWritableChanged())
    Q_PROPERTY(bool isReadable READ isReadable() NOTIFY isReadableChanged())
    Q_PROPERTY(bool isExecutable READ isExecutable() NOTIFY isExecutableChanged())
    Q_PROPERTY(bool isSafeToOpen READ isSafeToOpen() NOTIFY isSafeToOpenChanged())
    Q_PROPERTY(bool isSafeToEdit READ isSafeToEdit() NOTIFY isSafeToEditChanged())
    Q_PROPERTY(bool isSafeToChangeLink READ isSafeToChangeLink() NOTIFY isSafeToChangeLinkChanged())
    Q_PROPERTY(QString owner READ owner() NOTIFY ownerChanged())
    Q_PROPERTY(QString group READ group() NOTIFY groupChanged())
    Q_PROPERTY(QString size READ size() NOTIFY sizeChanged())
    Q_PROPERTY(QString dirSize READ dirSize() NOTIFY dirSizeChanged())
    Q_PROPERTY(QString modified READ modified() NOTIFY modifiedChanged())
    Q_PROPERTY(QString modifiedLong READ modifiedLong() NOTIFY modifiedChanged())
    Q_PROPERTY(QString created READ created() NOTIFY createdChanged())
    Q_PROPERTY(QString createdLong READ createdLong() NOTIFY createdChanged())
    Q_PROPERTY(QString absolutePath READ absolutePath() NOTIFY absolutePathChanged())
    Q_PROPERTY(QString absoluteFilePath READ absoluteFilePath() NOTIFY absoluteFilePathChanged())
    Q_PROPERTY(QString name READ name() NOTIFY nameChanged())
    Q_PROPERTY(QString suffix READ suffix() NOTIFY suffixChanged())
    Q_PROPERTY(QString symLinkTarget READ symLinkTarget() NOTIFY symLinkTargetChanged())
    Q_PROPERTY(bool isSymLinkBroken READ isSymLinkBroken() NOTIFY isSymLinkBrokenChanged())
    Q_PROPERTY(QString mimeType READ mimeType() NOTIFY mimeTypeChanged())
    Q_PROPERTY(QString mimeTypeComment READ mimeTypeComment() NOTIFY mimeTypeCommentChanged())
    Q_PROPERTY(bool isAnimatedImage READ isAnimatedImage() NOTIFY isAnimatedImageChanged())
    Q_PROPERTY(QStringList metaData READ metaData() NOTIFY metaDataChanged())
    Q_PROPERTY(int dirsCount READ dirsCount NOTIFY dirsCountChanged)
    Q_PROPERTY(int filesCount READ filesCount NOTIFY filesCountChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage() NOTIFY errorMessageChanged())

    Q_PROPERTY(QString STRING_SEP READ stringSeparator() NOTIFY stringSepChanged())

public:
    explicit FileData(QObject *parent = nullptr);
    ~FileData();

    // property accessors
    QString file() const { return m_file; }
    void setFile(QString file);

    bool exists() const { return m_fileInfo.exists(); }
    bool isDir() const { return m_fileInfo.isDirAtEnd(); }
    bool isFile() const { return m_fileInfo.isFileAtEnd(); }
    bool isSymLink() const { return m_fileInfo.isSymLink(); }
    QString kind() const { return m_fileInfo.kind(); }
    QString icon() const;
    QString permissions() const;
    bool isWritable() const { return m_fileInfo.isWritable(); }
    bool isReadable() const { return m_fileInfo.isReadable(); }
    bool isExecutable() const { return m_fileInfo.isExecutable(); }
    bool isSafeToOpen() const { return m_fileInfo.isSafeToRead(); }
    bool isSafeToEdit() const;
    bool isSafeToChangeLink() const;
    QString owner() const;
    QString group() const;
    QString size() const;
    QString dirSize() const;
    QString modified(bool longFormat = false) const;
    QString modifiedLong() const;
    QString created(bool longFormat = false) const;
    QString createdLong() const;
    QString absolutePath() const;
    QString absoluteFilePath() const;
    QString name() const { return m_fileInfo.fileName(); }
    QString suffix() const { return m_fileInfo.suffix().toLower(); }
    QString symLinkTarget() const { return m_fileInfo.symLinkTarget(); }
    bool isSymLinkBroken() const { return m_fileInfo.isSymLinkBroken(); }
    QString mimeType() const { return m_mimeTypeName; }
    QString mimeTypeComment() const { return m_mimeTypeComment; }
    bool isAnimatedImage() const { return m_isAnimatedImage; }
    QStringList metaData() const { return m_metaData; }
    uint dirsCount() const;
    uint filesCount() const;
    QString errorMessage() const { return m_errorMessage; }

    const QString STRING_SEP;
    QString stringSeparator() const { return STRING_SEP; }

    // methods accessible from QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool mimeTypeInherits(QString parentMimeType) const;
    Q_INVOKABLE QString typeCategory() const;

    Q_INVOKABLE bool checkSafeToEdit(QString file) const;
    Q_INVOKABLE bool checkSafeToChangeLink(QString file) const;
    Q_INVOKABLE bool checkIsDir(QString file) const;

signals:
    void fileChanged();
    void existsChanged();
    void isDirChanged();
    void isFileChanged();
    void isSymLinkChanged();
    void kindChanged();
    void categoryChanged();
    void iconChanged();
    void permissionsChanged();
    void isWritableChanged();
    void isReadableChanged();
    void isExecutableChanged();
    void isSafeToOpenChanged();
    void isSafeToEditChanged();
    void isSafeToChangeLinkChanged();
    void ownerChanged();
    void groupChanged();
    void sizeChanged();
    void dirSizeChanged();
    void modifiedChanged();
    void createdChanged();
    void nameChanged();
    void suffixChanged();
    void absolutePathChanged();
    void absoluteFilePathChanged();
    void symLinkTargetChanged();
    void isSymLinkBrokenChanged();
    void metaDataChanged();
    void mimeTypeChanged();
    void mimeTypeCommentChanged();
    void isAnimatedImageChanged();
    void dirsCountChanged();
    void filesCountChanged();
    void errorMessageChanged();
    void stringSepChanged();

private:
    void readInfo();
    void readMetaData();
    QString calculateAspectRatio(int width, int height) const;
    void addMetaData(uint priority, QString label, QString value);

#ifndef FILEDATA_NO_EXIF
    QStringList readExifData(QString filename);
#endif

    QString m_file;
    StatFileInfo m_fileInfo;
    QMimeType m_mimeType;
    QString m_mimeTypeName;
    QString m_mimeTypeComment;
    QStringList m_metaData;
    QString m_errorMessage;
    bool m_isAnimatedImage = {false};
};

#endif // FILEDATA_H
