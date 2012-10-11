#!/bin/bash
# A very quick script to make a YAML package list of everything installed on a machine
rpm -qa --qf='-\n  "name": "%{name}"\n  "version": "%{version}"\n  "release": "%{release}"\n  "arch": "%{arch}"\n'
