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
 * @section Reading
 *
 * The file contents can be accessed using \c readFile, if the
 * file is smaller than the maximum file size (default: 200 KiB).
 *
 * @section Writing
 *
 * Use the \l QSaveFile class for saving, and use the \c QIODevice::Unbuffered
 * option when opening the save file.
 *
 * Always pause the monitor using \c pause before starting the
 * save operation, and resume it afterwards using \c resume. To
 * simplify this, you can use a \c ConfigFileMonitorBlocker
 * that automatically resumes monitoring when it is destroyed.
 *
 * @section JSON
 *
 * Two shortcut methods are available for reading and writing JSON
 * configuration files. These methods automatically check versions
 * and handle pause/resume: \c readJson, \c writeJson.
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

    QString file() const;
    bool fileExists() const;
    ConfigFileMonitorOptions options() const;
    bool isRunning() const;

    /**
     * @brief Read config file contents.
     * @param state
     * @return Data, or empty string in case of errors.
     */
    QString readFile(ConfigFileMonitor::ReadErrorState& state) const;
    QString readFile() const;
    int maximumFileSize() const;

    bool writeFile(const QByteArray& value, ConfigFileMonitor::ReadErrorState& state, bool createBackup = false);
    bool writeFile(const QByteArray& value, bool createBackup = false);

    bool backupFile(ConfigFileMonitor::ReadErrorState& state) const;
    bool backupFile() const;

    // TODO: docs
    // - how to use migrator functions
    // - version must be int
    // - readJson saves the file if migrations were applied!
    // - readJson fails if the file does not exist -> check fileExists and save an empty value using writeJson({}, -1) to create a new config file
    QJsonValue readJson(std::function<bool(int&, QJsonValue&)> migrator);

    // TODO: docs
    // - does not apply migrations
    // - returns fallback if loaded version does not match expected version
    QJsonValue readJson(int expectedVersion, QJsonValue fallback = {});

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
 * Use this helper when saving config files like this:
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
