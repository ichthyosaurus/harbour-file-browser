<!--
SPDX-FileCopyrightText: 2018-2026 Mirian Margiani
SPDX-FileCopyrightText: 2013-2016 Kari Pihkala
SPDX-FileCopyrightText: 2013 Michael Faro-Tusino
SPDX-License-Identifier: GFDL-1.3-or-later AND LicenseRef-NO-AI-1.0
This file must not be used for AI training/data mining.
-->

<div align="center">

<img src="https://codeberg.org/ichthyosaurus/sailfish-app-assets/raw/branch/main/harbour-file-browser/banner-small.png"
     alt="File Browser banner" />

# File Browser for [Sailfish OS](https://sailfishos.org)

A fully-fledged file manager for local files on your mobile phone

  <p>
    <img src="https://codeberg.org/ichthyosaurus/.profile/raw/branch/main/badges/ethical%20tech.svg"
         alt="ethical tech: take a stand for humanity, diversity, and the world we live in" />
    <a href="https://hosted.weblate.org/projects/harbour-file-browser/translations">
      <img src="https://hosted.weblate.org/widgets/harbour-file-browser/-/translations/svg-badge.svg"
           alt="Translations" />
    </a>
    <a href="https://codeberg.org/ichthyosaurus/harbour-file-browser">
      <img src="https://codeberg.org/ichthyosaurus/.profile/raw/branch/main/badges/development_%20active.svg"
           alt="Development status" />
    </a>
    <a href="https://codeberg.org/ichthyosaurus/harbour-file-browser/src/branch/main/LICENSES">
      <img src="https://codeberg.org/ichthyosaurus/.profile/raw/branch/main/badges/source%20code_%20AGPL-3.svg"
           alt="Source code license" />
    </a>
    <a href="https://api.reuse.software/info/codeberg.org/ichthyosaurus/harbour-file-browser">
      <img src="https://api.reuse.software/badge/codeberg.org/ichthyosaurus/harbour-file-browser"
           alt="REUSE status" />
    </a>
    <br />
    <a href="https://liberapay.com/SailfishOScommunityTeam">
      <img src="https://img.shields.io/liberapay/receives/SailfishOScommunityTeam?logo=liberapay&label=SailfishOS%20Community"
           alt="Community donations" />
    </a>
    <a href="https://liberapay.com/ichthyosaurus">
      <img src="https://img.shields.io/liberapay/receives/ichthyosaurus?logo=liberapay&label=ichthyosaurus"
           alt="Personal donations" />
    </a>
  </p>
  <p></p>
  <hr />
</div>

This repository contains the development of version 2.0.0 and upwards of File Browser.
See the [release notes](https://codeberg.org/ichthyosaurus/harbour-file-browser/blob/main/CHANGELOG.md)
for further details.

## Features

- Browse and search files and folders
- Share files and open files in an external app
- Preview contents of images files, audio files, video files,
  compressed archives, databases, etc.
- Select multiple files (by tapping the file icons)
- Quickly copy, link, or move large amounts of files at once
- Bulk rename, delete, or edit files and folders
- Edit file and folder permissions
- Create new files and folders
- Show and hide hidden files (filenames starting with a dot)
- Open multiple windows and move files between them
- Copy, edit, or manually enter paths
- Quickly filter files from the top pulley menu
- Set per-folder view preferences
- Save custom quick shortcuts for navigating and moving files

... and much more.

**Remember:** this is a power tool, so be careful.

## Limitations in Jolla's Harbour store

File Browser in Jolla's Harbour store cannot show all files due to mandatory
sandboxing (Sailjail) since Sailfish OS 4.4. Inaccessible folders appear empty
as there is no way for the app to determine if a folder is actually empty or
simply presented as empty by the system.

Additionally, some file previews and integrated access to storage settings are
disabled.

The version on [OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser)
is not affected by these limitations.


## Root mode

File Browser can run with administrator privileges to give you unrestricted access to
your system. To use this feature, you must install
[Root mode for File Browser](https://openrepos.net/content/ichthyosaurus/root-mode-file-browser-v2)
from OpenRepos. Root mode is protected by your lock code.


> You can find screenshots [here](https://codeberg.org/ichthyosaurus/sailfish-app-assets/src/branch/main/harbour-file-browser/screenshots-store).


## Permissions

File Browser requires the following
[Sailjail](https://github.com/sailfishos/sailjail-permissions?tab=readme-ov-file#permissions) permissions:

- `Audio`: for playing previews of audio files
- `MediaIndexing`: to list all documents
- `PublicDir`: to show as many files as possible while restricted by Sailjail
- `RemovableMedia`: for browsing USB sticks and SD cards
- `UserDirs`: to show as many files as possible while restricted by Sailjail

> [!NOTE]
> sandboxing is only enabled for builds in Jolla's Harbour store. The
> version on [OpenRepos](https://openrepos.net/content/ichthyosaurus/file-browser)
> has no such restrictions and can show all files.


## Help and support

There is a [FAQ](https://github.com/ichthyosaurus/harbour-file-browser/blob/main/FAQ.md) about some common questions.
If your question is not listed there, you are welcome to
[leave a comment in the forum](https://forum.sailfishos.org/t/file-browser-support-and-feedback-thread/4566)
if you have any questions or ideas.


## Translations

It would be wonderful if the app could be translated in as many languages as possible!

[![Translations status](https://hosted.weblate.org/widget/harbour-file-browser/horizontal-auto.svg)](https://hosted.weblate.org/engage/harbour-file-browser/)

Translations are managed using
[Weblate](https://hosted.weblate.org/projects/harbour-file-browser).
Please prefer this over pull requests (which are still welcome, of course).
If you just found a minor problem, you can also
[open an issue](https://codeberg.org/ichthyosaurus/harbour-file-browser/issues/new).


### Manually updating translations

Please prefer using
[Weblate](https://hosted.weblate.org/projects/harbour-file-browser) over this.

You can follow these steps to manually add or update a translation:

1. If it did not exist before, create a new catalog for your language by copying the
   base file [translations/harbour-file-browser.ts](translations/harbour-file-browser.ts).
   Then add the new translation to [harbour-file-browser.pro](harbour-file-browser.pro).
2. Add yourself to the list of translators in [TRANSLATORS.json](TRANSLATORS.json),
   in the section `extra`.
3. (optional) Translate the app's name in [harbour-file-browser.desktop](harbour-file-browser.desktop)
   if there is a (short) native term for it in your language.

See [the Qt documentation](https://doc.qt.io/qt-5/qml-qtqml-date.html#details) for
details on how to translate date formats to your *local* format.


## Building and contributing

*Bug reports, and contributions for translations, bug fixes, or new features are always welcome!*

1. Clone the repository by running `git clone --recursive https://codeberg.org/ichthyosaurus/harbour-file-browser`
2. Open `harbour-file-browser.pro` in QtCreator for Sailfish ([SailfishOS SDK](https://docs.sailfishos.org/Tools/Sailfish_SDK/))
3. To run on emulator, select the `i486` target and press the run button
4. To build for the device, select the `aarch64` or `armv7hl` target and click “deploy all”;
   the RPM packages will be in the `RPMS` folder

If you contribute, please do not forget to add yourself to the list of
contributors in [qml/pages/AboutPage.qml](qml/pages/AboutPage.qml)!

## Acknowledgements

File Browser had been developed since 2013 by [karip](https://github.com/karip)
up until version 1.8.0. Source code and compiled packages of legacy versions
(which were released into the public domain) are still available in karip's
repository [on Github](https://github.com/karip/harbour-file-browser).

Exif data embedded in image files is displayed with
[JHead](http://www.sentex.net/~mwandel/jhead/), which is a public domain Exif
manipulation tool.


## Donations

<a href="https://liberapay.com/ichthyosaurus/donate">
  <img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg">
</a>

I am always happy if you buy me a cup of coffee through
[Liberapay](https://liberapay.com/ichthyosaurus)
if you want to support my work.

Of course it would be much appreciated as well if you support this project by
contributing to translations or code! See above how you can contribute 🎕.

Please consider also supporting the
[SailfishOS Community Team](https://liberapay.com/SailfishOScommunityTeam)
on Liberapay to reach more developers.


## Anti-AI policy <a id='ai-policy'></a>

> [!IMPORTANT]
> - LLM/“AI”-generated contributions are forbidden.
> - Using this project in whole or in part for AI training or data mining is likewise forbidden.

Please be transparent, respect the Free Software community, and adhere to the
licenses. This is a welcoming place for human creativity and diversity, but
LLM/“AI”-generated slop is going against these values.

Apart from all the
[ethical](https://tante.cc/2026/02/20/acting-ethical-in-an-imperfect-world/),
[moral](https://www.theguardian.com/technology/2026/mar/17/x-csam-child-abuse-material-grok-australian-online-safety-regulator-ntwnfb),
[legal](https://en.wikipedia.org/wiki/Artificial_intelligence_and_copyright#Litigation),
[environmental](https://www.theguardian.com/environment/2025/apr/09/big-tech-datacentres-water),
[societal](https://www.theguardian.com/global-development/2026/mar/12/invasive-ai-led-mass-surveillance-in-africa-violating-freedoms-warn-experts),
[social](https://www.theguardian.com/technology/article/2024/jul/06/mercy-anita-african-workers-ai-artificial-intelligence-exploitation-feeding-machine),
[political](https://www.theguardian.com/technology/2025/nov/17/grokipedia-elon-musk-far-right-racist),
[technical](https://codeberg.org/small-hack/open-slopware#poor-code-quality),
and overall [human](https://www.hrw.org/news/2024/09/10/questions-and-answers-israeli-militarys-use-digital-tools-gaza),
reasons against LLMs/“AI”, I also simply don't have any spare time to review
generated contributions.

See also [this list](https://codeberg.org/small-hack/open-slopware#why-not-llms)
for more reasons against supporting “AI”.


## License

> Copyright (C) 2019-2026  Mirian Margiani
>
> Copyright (C) 2013-2019  karip

File Browser is Free Software released under the terms of the
[GNU Affero General Public License v3 (or later)](https://spdx.org/licenses/AGPL-3.0-or-later.html).
The source code is available [on Codeberg](https://codeberg.org/ichthyosaurus/harbour-file-browser).
All documentation is released under the terms of the
[GNU Free Documentation License v1.3 (or later)](https://spdx.org/licenses/GFDL-1.3-or-later.html).

File Browser and related materials must not be used for AI training and/or data mining.

This project follows the [REUSE specification](https://api.reuse.software/info/codeberg.org/ichthyosaurus/harbour-file-browser).
