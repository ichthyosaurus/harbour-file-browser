# Root mode for File Browser

Run File Browser with super user privileges. (For version 2.0.0+.)

A setuid helper binary is used to start the app. The source file is also
included in the package at: `/usr/share/%appname/start-root-helper.c`


## ** Warning **

*USE AT YOUR OWN RISK*. This app can be used to corrupt files on the phone
and make the phone *unusable*. The author of File Browser does not take any
responsibility if that happens. So, be very careful.


## Building

You can either use the `build.sh` script, or follow the steps manually. Note:
before using the script, you have to adapt the paths to your setup:

```
SFDK=<path to SDK>/bin/sfdk
TARGETS=(<list of targets you want to build for>)
```

Use this to get a list of installed targets (or use the SDK maintenance tool):

`<sfdk> tools list`


Steps for manual builing:

1. Checkout this repository to get the source code
2. Open the Sailfish OS IDE and start the Build Engine or run: `<path to SDK>/bin/sfdk engine start`
3. Run the following in the directory where this README file is located to
   build the package: `<path to SDK>/bin/sfdk engine exec sb2 -t <target> make`
4. Results are in `RPMS/<target>/`
5. Stop the Build Engine in the IDE or by running: `<path to SDK>/bin/sfdk engine stop`

If you installed the IDE to `/opt/SailfishOS-SDK` you can build RPM packages for
both the emulator (`i486`) and your device (`armv7hl`) like this:

```
/opt/SailfishOS-SDK/bin/sfdk engine exec sb2 -t SailfishOS-3.2.1.20-armv7hl make BUILDARCH=armv7hl &&\
/opt/SailfishOS-SDK/bin/sfdk engine exec sb2 -t SailfishOS-3.2.1.20-i486 make BUILDARCH=i486
```


## License

Just as File Browser, this is released under the terms of the GNU GPL v3+. See
the main repository for more information.
