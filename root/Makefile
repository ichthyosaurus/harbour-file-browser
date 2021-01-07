#
# This file is part of File Browser.
#
# SPDX-FileCopyrightText: 2020-2021 Mirian Margiani
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# File Browser is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# File Browser is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#

.PHONY: default clean

SUFFIX=
SPEC=harbour-file-browser-root$(SUFFIX).spec
SOURCES=icons harbour-file-browser-root$(SUFFIX).desktop start-root-helper.c

default: $(SOURCES) $(SPEC)
	rm -rf build
	mkdir build
	cp -r $(SOURCES) build
	cd build && rpmbuild --define "debug_package %{nil}" --define "_rpmdir ../RPMS" --target "$(BUILDARCH)" -bb --build-in-place "../$(SPEC)"

clean:
	rm -rf build
