/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2023-2025 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef CONFIGFILEMONITOR_H
#define CONFIGFILEMONITOR_H

#include <QObject>
#include <QPointer>
#include <QJsonValue>

class ConfigFileMonitorPrivate;

/**
 * @brief The ConfigFileMonitor class watches a file for modifications.
 *
 * The signal \c configChanged is emitted when the config file
 * changes on disk. Unless the \c NotifyWhenRemoved option is set,
 * it will not be emitted when the file is removed.
 *
 * File contents can be accessed as plain text or as JSON data.
 *
 * @section JSON
 *
 * Two shortcut methods are available for reading and writing JSON
 * configuration files. These methods automatically check versions
 * and handle pause/resume: \c readJson, \c writeJson.
 *
 * @subsection Version migrations
 *
 * Config files can be migrated through \c readJson. Backups are
 * created automatically.
 *
 * @section Plain text
 *
 * The file contents can be accessed using \c readFile, if the
 * file is smaller than the maximum file size (default: 200 KiB).
 *
 * Use \c writeFile for saving. This method automatically handles
 * pause/resume.
 *
 * @subsection Saving manually
 *
 * If \c writeFile and \c writeJson are insufficient for some reason,
 * use the \l QSaveFile class for saving, and use the \c QIODevice::Unbuffered
 * option when opening the save file.
 *
 * Always pause the monitor using \c pause before starting the
 * save operation, and resume it afterwards using \c resume. To
 * simplify this, you can use a \c ConfigFileMonitorBlocker
 * that automatically resumes monitoring when it is destroyed.
 *
 * @section Backups
 *
 * The \c backupFile method allows creating numbered backups of
 * existing config files.
 *
 */
class ConfigFileMonitor : public QObject {
    Q_OBJECT
    Q_DECLARE_PRIVATE(ConfigFileMonitor)
    QScopedPointer<ConfigFileMonitorPrivate> const d_ptr;

public:  // flags
    enum ConfigFileMonitorOption {
        /**
         * @brief Emit a signal when the config file is removed.
         *
         * By default, only modifications will be signalled. Don't
         * enable this unless you have a way to prevent loaded models
         * from being cleared while another process is saving etc.
         */
        NotifyWhenRemoved = 0x01,

        /**
         * @brief Do not start monitoring until \c resume is called.
         *
         * By default, monitoring starts immediately when \c reset is
         * called. With this option, you have to call \c resume after
         * \c reset to start monitoring.
         */
        InitiallyPaused = 0x02,
    };
    Q_DECLARE_FLAGS(ConfigFileMonitorOptions, ConfigFileMonitorOption)

    enum ReadErrorState {
        NoError = 0,
        FileNotDefined,
        FileNotFound,
        FailedToOpen,
        FileTooLarge,
    };
    Q_ENUM(ReadErrorState)

public:  // interface
    explicit ConfigFileMonitor(QObject* parent = nullptr);
    virtual ~ConfigFileMonitor();

    /**
     * @brief Start monitoring a file.
     *
     * Monitoring will start immediately unless \c InitiallyPaused is passed.
     *
     * @param configFile File to monitor (may not exist yet).
     * @param options Optional options.
     * @param maximumSize Maximum file size in bytes for \c readFile and
     *    \c readJson, must not exceed an absolute maximum of 1 MiB.
     */
    void reset(const QString& configFile,
               const ConfigFileMonitorOptions& options = 0,
               int maximumSize = -1);

    /**
     * @brief Get the current config file path.
     */
    QString file() const;

    /**
     * @brief Check whether the currently set config file exists on disk.
     */
    bool fileExists() const;

    /**
     * @brief Check options for this monitor.
     */
    ConfigFileMonitorOptions options() const;

    /**
     * @brief Check whether the monitor is active.
     */
    bool isRunning() const;

    /**
     * @brief Read config file contents.
     *
     * @note Use @c readJson to read structured data with
     * version checking.
     *
     * @param state
     * @return Data, or empty string in case of errors.
     */
    QString readFile(ConfigFileMonitor::ReadErrorState& state) const;
    QString readFile() const;

    /**
     * @brief Check the currently defined maximum file size.
     *
     * Files larger than this cannot be loaded for performance
     * reasons. It is not recommended to change this value.
     */
    int maximumFileSize() const;

    /**
     * @brief Write config file contents.
     *
     * Set @c createBackup to @c true to automatically create
     * a backup if the file already exists.
     *
     * @return @c true on success, @c false if nothing was saved
     */
    bool writeFile(const QByteArray& value, ConfigFileMonitor::ReadErrorState& state, bool createBackup = false);
    bool writeFile(const QByteArray& value, bool createBackup = false);

    /**
     * @brief Create a numbered copy of the config file.
     *
     * The copy is placed in the same folder as the original file.
     * If the original file does not exist, nothing happens and the
     * method returns @c true.
     */
    bool backupFile(ConfigFileMonitor::ReadErrorState& state) const;
    bool backupFile() const;

    /**
     * @brief Read JSON formatted config files.
     *
     * @section Important note
     *
     * This method reads existing JSON config files. If the file does not
     * exist yet, make sure to save an empty value using @c writeJson({}, 0)
     * first to create a new file.
     *
     * @code
     * if (!myMonitor.fileExists()) {
     *     myMonitor.writeJson({}, 0);
     * }
     * @endcode
     *
     * @section Structure
     *
     * JSON formatted config files have a standard structure that
     * is managed by the @c writeJson and @c readJson methods.
     * Custom data can have any structure.
     *
     * @code
     * {
     *     "version": 1,
     *     "data": {},
     * }
     * @endcode
     *
     * The @c readJson method returns data in the @c data key,
     * while @c writeJson writes data to the @c data key.
     *
     * @section Migrations
     *
     * Optional config migrations can be applied through the custom
     * @c migrator function.
     *
     * @code
     * auto exampleMigrator = [](int& version, QJsonValue& data){
     *  if (version <= 0) {
     *      // initialize data...
     *      version = 1;
     *  }
     *
     *  if (version == 1) {
     *      // modify data...
     *      version = 2;
     *  }
     *
     *  if (version == 2) {
     *      return true;  // final version
     *  }
     *
     *  return false;  // got an unsupported version
     * };
     * @endcode
     *
     * @note The config file will be saved and a backup will be
     * created automatically if a migration is applied.
     */
    QJsonValue readJson(std::function<bool(int&, QJsonValue&)> migrator);

    /**
     * @brief Read JSON formatted files without migrations.
     *
     * Use this function if no migrations are needed. The fallback
     * value is returned if loading fails or if loaded version and
     * expected version do not match.
     */
    QJsonValue readJson(int expectedVersion, QJsonValue fallback = {});

    /**
     * @brief Save JSON formatted data.
     *
     * This method saves the @c data value opaquely and sets the
     * config file version to @c version.
     *
     * If @c createBackup is @c true, a backup will be created if
     * the config file already exists on disk.
     *
     * @sa readJson
     */
    bool writeJson(QJsonValue data, int version, bool createBackup = false);

public slots:
    void pause();
    void resume();
    void setRunning(bool running);

signals:
    void configChanged();

private:
    QJsonValue makeFallbackJson(std::function<bool(int&, QJsonValue&)> migrator);
};
Q_DECLARE_OPERATORS_FOR_FLAGS(ConfigFileMonitor::ConfigFileMonitorOptions)


/**
 * @brief The ConfigFileMonitorBlocker class pauses monitoring until it is destroyed.
 *
 * \c ConfigFileMonitorBlocker can be used instead of a pair of calls to
 * \c ConfigFileMonitor::pause and \c ConfigFileMonitor::resume.
 * This ensures that the monitor is always resumed after it has been paused.
 *
 * Use this helper when manually saving config files like this:
 *
 * \code
 * void save() {
 *     ConfigFileMonitorBlocker blocker(myMonitor);
 *
 *     // ... save stuff ...
 *
 *     if (errorOccurred) {
 *         // return without having to worry about resuming the monitor
 *         return;
 *     }
 *
 *     // ... more stuff ...
 * }
 * \endcode
 *
 * @note this helper does \em not restore the previous state. It always
 * calls \c resume when it goes out of scope. This is different from
 * e.g. \l QSignalBlocker.
 *
 * Without the blocker, you would have to manually pause and resume
 * the monitor. This causes issues when exceptions occur during saving.
 *
 * \code
 * void save() {
 *     myMonitor->pause();
 *
 *     // ... save stuff ...
 *
 *     if (errorOccurred) {
 *         myMonitor->resume();
 *         return;
 *     }
 *
 *     // ... more stuff ...
 *     myMonitor->resume();
 * }
 * \endcode
 *
 * @note Using the blocker is not necessary when saving config
 * files using the @c writeJson or @c writeFile methods.
 */
class ConfigFileMonitorBlocker
{
    Q_DISABLE_COPY(ConfigFileMonitorBlocker)

public:
    explicit ConfigFileMonitorBlocker(ConfigFileMonitor* monitor) noexcept;
    inline explicit ConfigFileMonitorBlocker(ConfigFileMonitor& monitor) noexcept :
        ConfigFileMonitorBlocker(&monitor) {}
    ~ConfigFileMonitorBlocker();

private:
    QPointer<ConfigFileMonitor> m_monitor;
};

#endif  // CONFIGFILEMONITOR_H
