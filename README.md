Corkscrew Linux
===============

Single script to generate a custom preseeded debian installer.

Requirements
------------

```
sudo apt-get install isolinux xorriso qemu
```

Usage
-----

```
./generate-iso.sh [configuration file]
```

Configuration
-------------

Configuration is done via `conf` files. Ensure the following variables are defined:

```
INSTALLER_NAME - Name of the installer. Is also the output ISO name
INSTALLER_URL  - URL for the given installer (stable, testing, unstable etc)
PRESEED_FILE   - Location of preseed file. If it isn't an absolute directory, it is relative to conf file
```

Checkout the sample configurations under `./conf`

Example
-------

```
# Download debian testing and generate iso
./generate-iso.sh conf/sample.conf

# Test it quickly with qemu (choose text based install; graphic install not working)
qemu-system-x86_64 -cdrom tmp/test.iso
```

References
----------

- https://wiki.debian.org/DebianInstaller/Modify/CD
- https://wiki.debian.org/DebianInstaller/Preseed
- https://www.debian.org/releases/jessie/i386/apbs05.html.en
- http://askubuntu.com/questions/344702/is-it-possible-to-ask-arbitrary-questions-in-the-preseed-during-ubuntu-install
- http://www.fifi.org/doc/debconf-doc/tutorial.html
