#
# This file is part of File Browser.
#
# SPDX-FileCopyrightText: 2013 Kari Pihkala
# SPDX-FileCopyrightText: 2019-2020 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

# TRANSLATORS
# If you added a new translation catalog, please append its file name to this
# list. Just copy the last line and modify it as needed.
# Do not forget to modify the localized app name in the the .desktop file.
TRANSLATIONS = \
    translations/harbour-file-browser-de_CH.ts \
    translations/harbour-file-browser-de_DE.ts \
    translations/harbour-file-browser-el.ts \
    translations/harbour-file-browser-en_US.ts \
    translations/harbour-file-browser-es.ts \
    translations/harbour-file-browser-fi.ts \
    translations/harbour-file-browser-fr.ts \
    translations/harbour-file-browser-it_IT.ts \
    translations/harbour-file-browser-nl.ts \
    translations/harbour-file-browser-ru_RU.ts \
    translations/harbour-file-browser-sv.ts \
    translations/harbour-file-browser-zh_CN.ts \

# ------------------------------------------------------------------------------

# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed
TARGET = harbour-file-browser

# Note:
# Current version number and whether or not to include features
# agains Jolla Harbour's rules can be configured in the yaml-file.
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
DEFINES += HARBOUR_COMPLIANCE=\\\"$$HARBOUR_COMPLIANCE\\\"
HARBOUR_COMPLIANCE=$$HARBOUR_COMPLIANCE

OLD_DEFINES = "$$cat($$OUT_PWD/requires_defines.h)"
!equals(OLD_DEFINES, $$join(DEFINES, ";", "//")) {
    NEW_DEFINES = "$$join(DEFINES, ";", "//")"
    write_file("$$OUT_PWD/requires_defines.h", NEW_DEFINES)
    message("DEFINES changed..." $$DEFINES)
}

equals(HARBOUR_COMPLIANCE, off) {
    DEFINES += NO_HARBOUR_COMPLIANCE
    message("Harbour compliance disabled")
} else {
    message("Harbour compliance enabled")
}

# copy change log file to build root;
# needed for generating rpm change log entries
CONFIG += file_copies
COPIES += changelog
changelog.files = CHANGELOG.md
changelog.path = $$OUT_PWD

CONFIG += sailfishapp

SOURCES += src/harbour-file-browser.cpp \
    src/filemodel.cpp \
    src/filedata.cpp \
    src/engine.cpp \
    src/fileworker.cpp \
    src/searchengine.cpp \
    src/searchworker.cpp \
    src/consolemodel.cpp \
    src/statfileinfo.cpp \
    src/globals.cpp \
    src/settingshandler.cpp \

HEADERS += src/filemodel.h \
    src/filedata.h \
    src/engine.h \
    src/fileworker.h \
    src/searchengine.h \
    src/searchworker.h \
    src/consolemodel.h \
    src/statfileinfo.h \
    src/globals.h \
    src/settingshandler.h \

SOURCES += src/jhead/jhead-api.cpp \
    src/jhead/exif.c \
    src/jhead/gpsinfo.c \
    src/jhead/iptc.c \
    src/jhead/jpgfile.c \
    src/jhead/jpgqguess.c \
    src/jhead/makernote.c \

HEADERS += src/jhead/jhead-api.h \
    src/jhead/jhead.h \

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

DISTFILES += qml/*.qml \
    qml/cover/*.qml \
    qml/pages/*.qml \
    qml/components/*.qml \
    qml/js/*.js \
    qml/images/*.png \
    qml/pages/license.html \
    rpm/harbour-file-browser.changes.run \
    rpm/harbour-file-browser.spec \
    rpm/harbour-file-browser.yaml \
    translations/*.ts \
    harbour-file-browser.desktop \

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
