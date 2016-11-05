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
./generate-iso.sh [base_installer_url]
```

Example
-------

```
# Download debian testing and generate iso
./generate-iso.sh http://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso

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
