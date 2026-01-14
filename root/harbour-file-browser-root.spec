# This file is part of File Browser.
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2020-2024 Mirian Margiani

%define appname harbour-file-browser-root
Name: %{appname}
Summary: File Browser with root privileges
Version: 1.4.0
Release: 1
Group: System/Tools
License: GPL-3.0-or-later
Vendor: ichthyosaurus
Packager: ichthyosaurus
Source0: %{name}-%{version}.tar.xz
Provides:      application(%{appname}.desktop)
Requires:      harbour-file-browser >= 2.0.0

# It appears Obsoletes is wrongly interpreted as Conflicts by Sailfish when
# installing packages via File Browser or Storeman. This means users will have
# to manually remove obsolete packages.

# (Remove this line if there's a new beta version around.)
# (Obsoletes:     harbour-file-browser-root-beta)

# These two packages only work with legacy File Browser and are
# no longer needed.
# (Obsoletes:     sailfishos-filebrowserroot-patch)
# (Obsoletes:     filebrowserroot)
Conflicts:     sailfishos-filebrowserroot-patch
Conflicts:     filebrowserroot

%description
Run File Browser with super user privileges. (For version 2.0.0+.)

A setuid helper binary is used to start the app. The source file is included
in this package:
    /usr/share/%appname/start-root-helper.c

The start helper is built using these steps in the Sailfish SDK:
    $ gcc "/usr/share/%appname/start-root-helper.c" -o "/usr/share/%appname/start-root"
    $ chmod 4755 "/usr/share/%appname/start-root"

Sources and documentation can be found online at:
    https://github.com/ichthyosaurus/harbour-file-browser/

The repository contains a helper script for cross-compiling the root starter
using the Sailfish SDK. Prefer this over trying to build it on your phone.


%prep
%setup -q -n %{name}-%{version}

%build
gcc start-root-helper.c -o start-root
chmod 4755 start-root

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/%appname

for d in "86x86" "108x108" "128x128" "172x172"; do
    mkdir -p "%{buildroot}/usr/share/icons/hicolor/$d/apps"
    cp "icons/$d/"*.png "%{buildroot}/usr/share/icons/hicolor/$d/apps"
done

cp %appname.desktop %{buildroot}/usr/share/applications/
cp start-root start-root-helper.c %{buildroot}/usr/share/%appname/

%changelog

* Wed Jan 14 2026 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.4.0-1
- Fixed dconf issues after running File Browser in Root Mode
- Rebuilt with latest SDK for SFOS 5.x

* Sat Jan 06 2024 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.3.0-1
- Fixed root mode for SFOS 4.x

* Sun Apr 03 2022 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.2.1-1
- Added a Sailjail profile so root mode can be used on SFOS 4.x
- Updated the build process

* Thu Jan 07 2021 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.2.0-1
- Renamed to harbour-file-browser-root (dropped beta suffix)
- Marked as conflicting with legacy root app/patch
- Switched versioning scheme to use three digits

* Sun May 10 2020 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.1-1
- Fixed starting from the terminal

* Sat May 02 2020 Mirian Margiani <mixosaurus+ichthyo@pm.me> 1.0-1
- Fixed building
- Added and improved documentation
- Included in harbour-file-browser's main repository

* Mon Dec 30 2019 Mirian Margiani <mixosaurus+ichthyo@pm.me> 0.4-1
- Made compatible with released version 2.0.0+ (beta) of File Browser
- Renamed and rebuilt package
- Added re-build instructions to RPM description

* Tue Jun 04 2019 Mirian Margiani <mixosaurus+ichthyo@pm.me> 0.3-1
- Forked version 0.2-5 of filebrowserroot by Schturman
- Refactored using correct icons and fixed launcher entry
- Renamed to be more similar to File Browser

* Wed Feb 06 2019 schturman <schturman@hotmail.com> 0.2-5
- Changes in SPEC file. Obsoletes changed to Conflicts.

%files
%attr(0644, root, root) "/usr/share/applications/%appname.desktop"
%attr(0644, root, root) "/usr/share/icons/hicolor/86x86/apps/%appname.png"
%attr(0644, root, root) "/usr/share/icons/hicolor/108x108/apps/%appname.png"
%attr(0644, root, root) "/usr/share/icons/hicolor/128x128/apps/%appname.png"
%attr(0644, root, root) "/usr/share/icons/hicolor/172x172/apps/%appname.png"
%attr(4755, root, root) "/usr/share/%appname/start-root"
%attr(0644, root, root) "/usr/share/%appname/start-root-helper.c"
