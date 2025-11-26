/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2025 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Repository: https://github.com/ichthyosaurus/harbour-file-browser
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main()
{
    setuid(0);
    system("su -c 'mkdir -p /run/user/0/dconf' && \
            su -c 'env XDG_RUNTIME_DIR=/run/user/0 \
                   WAYLAND_DISPLAY=/run/display/wayland-0 \
                   /usr/bin/harbour-file-browser'");
    exit(0);
}
