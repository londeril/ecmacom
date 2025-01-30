#!/bin/bash
rm /etc/machine-id
rm /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure
rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
