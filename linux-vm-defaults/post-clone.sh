#!/bin/bash
rm /etc/machine-id
rm /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure
dpkg-reconfigure openssh-server
