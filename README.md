Puppet Package Lists
====================

apply_package_list
------------------
Dynamcially creates a package resource for each element in a list
and ensures that each version is enforced. Any package not
defined in your package list will automatically generate a package
resource with an ensure => absent, giving you the power to define
exactly what you want on your system in one list and enforce it using
Puppet.

### Basic Syntax

    apply_package_list('/path/to/list/file', '[purge=nopurge]')

The purge option determines whether or not to purge packages that do not
appear in your package set. It defaults to nopurge.

You need to feed in one list containing a structure of package data.
Examples follow.

With versions:

    avahi-libs-0.6.25-11.el6.i686
    augeas-libs-0.9.0-4.el6.i686
    dhcp-common-4.1.1-31.P1.el6_3.1.i686
    pulseaudio-utils-0.9.21-13.el6.i686
    ...
    ...

Without versions:

    avahi-libs
    augeas-libs
    dhcp-common
    pulseaudio

Combination:

    avahi-libs-0.6.25-11.el6.i686
    augeas-libs-0.9.0-4.el6.i686
    dhcp-common
    pulseaudio-utils

This would ensure that the listed packages were installed and were at
their associated version numbers. If no version number is specified,
the package would be installed from the latest version available in
your system's configured repositories.

### Limitations

* Inability to pass plain package names (without version/arch/release etc) with the "purge" option
* Only RPM-based operating systems are supported at this time.
