#
# This file is part of File Browser.
#
# SPDX-FileCopyrightText: 2013 Kari Pihkala
# SPDX-FileCopyrightText: 2019-2022 Mirian Margiani
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

# require the C++17 standard to be able to use std::as_const
# Note: old Qt only recognizes up to "c++14" as valid config options
CONFIG += c++1z

QT += concurrent

# configure Harbour compliance:
# some features must be disabled for the official store
HARBOUR_COMPLIANCE=$$HARBOUR_COMPLIANCE
equals(HARBOUR_COMPLIANCE, off) {
    DEFINES += NO_HARBOUR_COMPLIANCE
    message("Harbour compliance disabled")

    CONF_DESKTOP_MIME_TYPE = "MimeType=inode/directory;"

    # possibly required extra permissions (to be checked):
    # ApplicationInstallation       for installing packages when opening them
    # Calendar                      for importing ics calendar files
    # Contacts                      for importing vcs contact files
    # Email                         for sharing to email
    # Internet                      for fetching license texts (and maybe for cloud integration)
    # Sharing                       for sharing (implicitly allowed already?)
    #
    # Sailjail prevents most filesystem access. Thus, enabling the Sailjail
    # profile will break the app's core functionality outside of a small subset
    # of folders in $HOME.
    CONF_SAILJAIL_DETAILS = "Sandboxing=Disabled"
} else {
    message("Harbour compliance enabled")

    CONF_DESKTOP_MIME_TYPE=""
    CONF_SAILJAIL_DETAILS = "Permissions=Audio;MediaIndexing;RemovableMedia;UserDirs;PublicDir"
}

FEATURE_PDF_VIEWER=$$FEATURE_PDF_VIEWER
equals(FEATURE_PDF_VIEWER, off) {
    DEFINES += NO_FEATURE_PDF_VIEWER
    message("feature flags: Integrated PDF viewer disabled")
} else {
    message("feature flags: Integrated PDF viewer enabled")
}

FEATURE_STORAGE_SETTINGS=$$FEATURE_STORAGE_SETTINGS
equals(FEATURE_STORAGE_SETTINGS, off) {
    DEFINES += NO_FEATURE_STORAGE_SETTINGS
    message("feature flags: Integrated system storage settings disabled")
} else {
    message("feature flags: Integrated system storage settings enabled")
}

FEATURE_SHARING=$$FEATURE_SHARING
equals(FEATURE_SHARING, off) {
    DEFINES += NO_FEATURE_SHARING
    message("feature flags: File sharing disabled")
} else {
    message("feature flags: File sharing enabled")
}

# Note: compile-time options can be configured in the yaml file.
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
DEFINES += RELEASE_TYPE=\\\"$$RELEASE_TYPE\\\"

OLD_DEFINES = "$$cat($$OUT_PWD/requires_defines.h)"
!equals(OLD_DEFINES, $$join(DEFINES, ";", "//")) {
    NEW_DEFINES = "$$join(DEFINES, ";", "//")"
    write_file("$$OUT_PWD/requires_defines.h", NEW_DEFINES)
    message("DEFINES changed..." $$DEFINES)
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

SOURCES += \
    src/harbour-file-browser.cpp \
    src/filemodel.cpp \
    src/filemodelworker.cpp \
    src/filedata.cpp \
    src/fileoperations.cpp \
    src/fileclipboardmodel.cpp \
    src/engine.cpp \
    src/fileworker.cpp \
    src/texteditor.cpp \
    src/searchengine.cpp \
    src/searchworker.cpp \
    src/consolemodel.cpp \
    src/statfileinfo.cpp \
    src/globals.cpp \
    src/settings.cpp \
    \
    src/configfilemonitor.cpp \

HEADERS += \
    src/filemodel.h \
    src/filemodelworker.h \
    src/filedata.h \
    src/fileoperations.h \
    src/fileclipboardmodel.h \
    src/engine.h \
    src/enumcontainer.h \
    src/fileworker.h \
    src/texteditor.h \
    src/searchengine.h \
    src/searchworker.h \
    src/consolemodel.h \
    src/statfileinfo.h \
    src/globals.h \
    src/settings.h \
    src/overload_of.h \
    \
    src/configfilemonitor.h \

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

# Build submodules
include(libs/SortFilterProxyModel/SortFilterProxyModel.pri)
