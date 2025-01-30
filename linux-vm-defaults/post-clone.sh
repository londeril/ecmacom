#!/bin/bash
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure
dpkg-reconfigure openssh-server
