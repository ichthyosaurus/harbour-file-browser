/*
 * This file is part of File Browser.
 * SPDX-FileCopyrightText: 2020-2022 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Repository: https://github.com/ichthyosaurus/harbour-file-browser
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
    setuid(0);
    system("su -c 'mkdir -p /run/user/0/dconf' && su -c 'invoker --type=silica-qt5 -n /usr/bin/harbour-file-browser'");
    exit(0);
}
