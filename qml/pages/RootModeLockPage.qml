/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0

Item {
    id: page
    anchors.fill: parent

    property QtObject _lock: null
    property bool _setupFinished: false
    property bool _setupTimerFinished: false

    property string _message: qsTr("Unable to authenticate")
    property string _messageDetails: qsTr("It is not possible to use File Browser in Root Mode without authentication.")
    property bool _allowEntry: false

    signal authenticated
    onAuthenticated: cautionNotification.publish()

    Timer {
        // allow a grace period before showing the busy indicator
        // when loading the device lock component takes a long time
        interval: 500
        running: true
        onTriggered: _setupTimerFinished = true
    }

    Notification {
        id: cautionNotification
        previewSummary: qsTr("Root Mode: be careful, you could break your system.")
        isTransient: true
        appIcon: "icon-lock-warning"
        icon: "icon-lock-warning"
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: page.height

        PageBusyIndicator {
            id: busyIndicator
            running: !_setupFinished && _setupTimerFinished
        }

        ViewPlaceholder {
            enabled: !busyIndicator.running && _setupTimerFinished
            text: _message
            hintText: _messageDetails
        }

        ButtonLayout {
            visible: !busyIndicator.running && _setupTimerFinished
            preferredWidth: Theme.buttonWidthMedium
            anchors {
                bottom: parent.bottom
                bottomMargin: (page.orientation & Orientation.LandscapeMask && Screen.sizeCategory <= Screen.Medium) ?
                                  Theme.itemSizeExtraSmall : Theme.itemSizeMedium
            }

            Button {
                visible: _allowEntry
                text: qsTr("Understood!")
                onClicked: {
                    page.authenticated()
                }
            }
        }
    }

    Connections {
        target: _lock

        onAuthenticated: {
            _lock.destroy()

            if (byUserInput) {
                page.authenticated()
            } else {
                _allowEntry = true
                _message = qsTr("Root Mode")
                _messageDetails = qsTr("Be careful when using File Browser in Root Mode. " +
                                    "Actions may unexpectedly break your system.")
            }
        }
    }

    Component.onCompleted: {
        try {
            _lock = Qt.createQmlObject("
                import QtQuick 2.2
                import Sailfish.Silica 1.0
                import %1 1.0
                import %2 1.0

                DeviceLockQuery {
                    id: query
                    returnOnAccept: true
                    returnOnCancel: true

                    signal authenticated(var byUserInput)

                    function getAuthentication(prompt) {
                        if (query._availableMethods !== Authenticator.NoAuthentication) {
                            query.requestPermission(prompt, {}, function () { query.authenticated(true) })
                        } else {
                            authenticated(false)
                        }
                    }
                }
                ".arg("org.nemomobile.devicelock").arg("com.jolla.settings.system"),
                                       page, 'RootModeDeviceLock [inline]')
        } catch(err) {
            console.error("[root] failed to create dynamic authentication request")
            console.error("[root] %1 [at %2:%3]".arg(err.message).arg(err.lineNumber).arg(err.columnNumber))
            _lock = null
        }

        _setupFinished = true

        if (_lock != null) {
            _lock.getAuthentication(qsTr("Start File Browser in Root Mode"))
        } else {
            _allowEntry = false
        }
    }
}
