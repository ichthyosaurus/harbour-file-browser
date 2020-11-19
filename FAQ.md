
# FAQ for File Browser for Sailfish OS

### What is File Browser?

File Browser is a simple tool to access the file system without enabling
developer mode.

### What does error 'Failure to write block' mean (when copying files)?

Your storage (phone or SD card) is most likely full.

### What does error 'Unknown error' mean?

One reason for this error message can be that you tried to move a folder between
the phone and the SD Card. Instead of moving (cut-paste), you should copy the
folder. After successfully copying your files, you can delete the original files.

### What does error "No application to open the file" mean (when opening files)?

It means that the `xdg-open` command used to open files does not recognize
the file type or it doesn't find a preferred program to open it. You can use
[Mimer](https://openrepos.net/content/llelectronics/mimer) (in OpenRepos) to
configure preferred programs.

### What does error 'SD Card not found' mean?

Perhaps your SD Card is not properly inserted to the phone. Maybe it has a
file system which is not recognized by the phone.

You can also try to access the SD card with another file manager, such as
Cargo Dock. Please get in touch if it works with a different file manager but
not with File Browser.

### Why does installing RPM packages give error 'Installing untrusted software disabled'?

You need to enable installation of untrusted software in the phone. Go to
Settings -> System -> Untrusted software, and enable "Allow untrusted software".

### How can I copy multiple files?

Tap on the file or folder icons in the list view and you will see options to cut
or copy at the bottom of the page.

You can also press and hold the file or folder icon until it becomes bigger.
Now you can tap on another icon to select all files in between.

### Does it have XXX feature?

It can't change owners, edit files, send email, MMS or SMS, open ftp sites,
connect to samba server, simulate vi and it does not blend or make coffee.
Sorry.

It can however share files, preview PDF files, and directly open system storage
settings when using the version from OpenRepos. These features are not allowed
in Jolla store.

You can also install
[root mode for File Browser](https://openrepos.net/content/ichthyosaurus/root-mode-file-browser-v2)
from OpenRepos. *Beware:* this allows you to easily *brick* your phone!

### Are there any alternative apps?

There is the wonderful Cargo Dock file manager in the Jolla store.

There are a number of other file managers available in OpenRepos.
