#!/bin/bash
#
# This file is part of File Browser and has been released into the public domain.
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2020-2022 Mirian Margiani

.PHONY: default clean

# NOTE Change SUFFIX when creating stable/dev builds. There is not need to
#      use the same suffix as File Browser because this helper is not allowed
#      in Jolla's Harbour store anyway.
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
