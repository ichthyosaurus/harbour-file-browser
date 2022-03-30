#
# This file is part of File Browser.
#
# SPDX-FileCopyrightText: 2013 Kari Pihkala
# SPDX-FileCopyrightText: 2019-2021 Mirian Margiani
# SPDX-License-Identifier: GPL-3.0-or-later
#

# TRANSLATORS
# If you added a new translation catalog, please append its file name to this
# list. Just copy the last line and modify it as needed.
# Do not forget to modify the localized app name in the the .desktop file.
TRANSLATIONS = \
    translations/harbour-file-browser-cs.ts       \
    translations/harbour-file-browser-de_CH.ts    \
    translations/harbour-file-browser-de_DE.ts    \
    translations/harbour-file-browser-el.ts       \
    translations/harbour-file-browser-en_US.ts    \
    translations/harbour-file-browser-es.ts       \
    translations/harbour-file-browser-et.ts       \
    translations/harbour-file-browser-fi.ts       \
    translations/harbour-file-browser-fr.ts       \
    translations/harbour-file-browser-hu.ts       \
    translations/harbour-file-browser-id.ts       \
    translations/harbour-file-browser-it_IT.ts    \
    translations/harbour-file-browser-nb_NO.ts    \
    translations/harbour-file-browser-nl_BE.ts    \
    translations/harbour-file-browser-nl.ts       \
    translations/harbour-file-browser-pl.ts       \
    translations/harbour-file-browser-ru_RU.ts    \
    translations/harbour-file-browser-sk.ts       \
    translations/harbour-file-browser-sv.ts       \
    translations/harbour-file-browser-tr.ts       \
    translations/harbour-file-browser.ts          \
    translations/harbour-file-browser-zh_CN.ts    \

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

# Note: compile-time options can be configured in the yaml file.
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
DEFINES += RELEASE_TYPE=\\\"$$RELEASE_TYPE\\\"
DEFINES += HARBOUR_COMPLIANCE=\\\"$$HARBOUR_COMPLIANCE\\\"
HARBOUR_COMPLIANCE=$$HARBOUR_COMPLIANCE

OLD_DEFINES = "$$cat($$OUT_PWD/requires_defines.h)"
!equals(OLD_DEFINES, $$join(DEFINES, ";", "//")) {
    NEW_DEFINES = "$$join(DEFINES, ";", "//")"
    write_file("$$OUT_PWD/requires_defines.h", NEW_DEFINES)
    message("DEFINES changed..." $$DEFINES)
}

# configure Harbour compliance:
# some features must be disabled for the official store
equals(HARBOUR_COMPLIANCE, off) {
    DEFINES += NO_HARBOUR_COMPLIANCE
    message("Harbour compliance disabled")

    CONF_DESKTOP_MIME_TYPE = "MimeType=inode/directory;"

    # some permissions:
    # ApplicationInstallation;Audio;Calendar;Contacts;Email;Internet;MediaIndexing;RemovableMedia;UserDirs;Sharing
    #
    # Sailjail prevents most filesystem access. Thus, enabling the Sailjail
    # profile will break the app's core functionality.
    CONF_SAILJAIL_DETAILS = "Sandboxing=Disabled"
} else {
    message("Harbour compliance enabled")

    CONF_DESKTOP_MIME_TYPE=""
    CONF_SAILJAIL_DETAILS = "Permissions=Audio;MediaIndexing;RemovableMedia;UserDirs;PublicDir"
}

# copy change log file to build root;
# needed for generating rpm change log entries
CONFIG += file_copies
COPIES += changelog
changelog.files = CHANGELOG.md
changelog.path = $$OUT_PWD

CONFIG += sailfishapp

# generate files based on build configuration
QMAKE_SUBSTITUTES += harbour-file-browser.desktop.in \

SOURCES += src/harbour-file-browser.cpp \
    src/filemodel.cpp \
    src/filemodelworker.cpp \
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
    src/filemodelworker.h \
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
    qml/pages/LICENSE.html \
    rpm/harbour-file-browser.changes.run \
    rpm/harbour-file-browser.spec \
    rpm/harbour-file-browser.yaml \
    translations/*.ts \
    harbour-file-browser.desktop \

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
