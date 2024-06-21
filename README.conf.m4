dnl/// SPDX-FileCopyrightText: 2023-2024 Mirian Margiani
dnl/// SPDX-License-Identifier: GFDL-1.3-or-later

dnl///
dnl/// Notes:
dnl/// - remove unused definitions unless they must not change when the template changes
dnl/// - use ifdef(${__X_*}) with one of store, summary, description, readme, or, harbour
dnl///   to include sections conditionally
dnl///

dnl/// [PRETTY PROJECT NAME](required): set to the human-readable name of the project, e.g. "Example App"
define(${__name}, ${File Browser})

dnl/// [PROJECT SLUG](required): set to the computer-readable name used in URLs, e.g. "harbour-example"
define(${__slug}, ${harbour-file-browser})

dnl/// [PROJECT's FIRST COPYRIGHT YEAR](required)
define(${__copyright_start}, ${2019})

dnl/// [FORUM THREAD](required)
define(${__forum}, ${https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566})

dnl/// [ABOUT PAGE FILE PATH](required)
define(${__about_page}, ${qml/pages/AboutPage.qml})

dnl/// [WEBLATE PROJECT](optional): set to __slug for most apps
define(${__weblate_project}, __slug)

dnl/// [WEBLATE COMPONENT](required if using Weblate): ignored if Weblate is disabled
define(${__weblate_component}, ${main-translations})

dnl/// [SUBMODULES](optional): set to "true" to enable docs for cloning with submodules
define(${__have_submodules}, ${true})

dnl/// [PATCHES](optional): set to "true" to enable docs for applying patches
define(${__have_patches}, ${true})

dnl/// [PROJECT STATUS](optional): string for the "development" badge, either "active" or "stable"
define(${__devel_status}, ${active})

dnl/// [FAQ URL](optional): full url to a FAQ, can be a forum thread or a file in the repo
define(${__faq_url}, ${https://github.com/ichthyosaurus/harbour-file-browser/blob/main/FAQ.md})

dnl/// [EXTRA COPYRIGHT INFO](optional): one additional main copyright line, e.g. "2020 Woof Bark"
define(${__extra_copyright}, ${2013-2019  karip})

dnl/// [EXTRA README FILE COPYRIGHT INFO](optional):
dnl///          additional copyright lines for the readme file
dnl///          note: lines must be in the format "SPDX-FileCopyrightText: year name"
define(${__extra_readme_file_copyright}, ${
SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
})
