#!/bin/bash
sed -i '7s/.*/SELINUX=disabled/' /etc/selinux/config
