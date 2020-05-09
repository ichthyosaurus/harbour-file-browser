#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
    setuid(0);
    system("su -c 'mkdir -p /run/user/0/dconf' && su -c 'invoker --type=silica-qt5 -n /usr/bin/harbour-file-browser-beta'");
    exit(0);
}
