/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

// This manager makes sure an attached page is always
// properly pushed to the stack, even if the stack is busy,
// the page status changes, or the attached page changes.

Item {
    id: root

    property Page page
    property Page nextPage
    property var nextPageProperties: ({})
    property string coverText

    function pushAttached(nextPage) {
        if (  !!nextPage
            && status === PageStatus.Active
            && !pageStack.busy
            && (   !forwardNavigation
                || !pageStack.nextPage()
                || !pageStack.nextPage().objectName)
        ) {
            console.log("[attached] pushing attached page:", nextPage,
                        "with current forward", pageStack.nextPage(),
                        forwardNavigation)
            pageStack.completeAnimation()
            pageStack.pushAttached(nextPage, nextPageProperties)
        }
    }

    onNextPageChanged: {
        pushAttached(nextPage)
    }

    Connections {
        target: status === PageStatus.Active ? pageStack : null
        onBusyChanged: pushAttached(nextPage)
    }

    Connections {
        target: page
        onStatusChanged: {
            if (status === PageStatus.Active && !!coverText) {
                main.coverText = coverText
            }
            pushAttached(nextPage)
        }
    }
}
