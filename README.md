Puppet Package Lists
====================

Dynamcially creates a package resource for each element in a list, and
ensures that each version is enforced. Any package not defined in your
package list will automatically generate a package resource with an
ensure => absent, giving you the power to define exactly what you want
on your system in one list and enforce it using Puppet.

For each package in a package list, an ensure will be dynamically created
to "latest". This allows you to either place an exact package version in
(along with the name), or simply the package name if you want the latest
from your mirror.

Options
-------

### source
Defines the path to a package list file. This option can be passed as the
resource name as well. This argument conflicts with the packages argument.

### packages
A package list to pass directly in. This argument conflicts with the
source argument.

### purge
Whether or not to purge packages that are not present in the package list.

RedHat Support
--------------

RedHat OS family support is relatively sound and straightforward, and is the
distribution this module was originally written for.

Debian Support
---------------

Debian-based OS families are supported as of 0.2.2. The package list format
is a little different than RedHat's, but the tools and commands used are
quite similar in nature. The key difference is the delimiter between package
name and version.

Creating package lists
----------------------

An easy way to create a package list for an entire system is using RPM
directly. Examples follow.

With versions:

    # RedHat
    rpm -qa > my-packages-redhat.lst
    # Debian
    dpkg-query --show > my-packages-debian.lst

Without versions (to get latest):

    # RedHat
    rpm -qa --qf="%{name}\n" > my-packages-redhat.lst
    # Debian
    dpkg-query --show -f '${Package}\n' > my-packages-debian.lst

Examples
--------

Keep kernel and grub at latest, don't purge other packages:

    # RedHat
    packagelist { 'mypackagelist': packages => [ 'kernel', 'grub' ] }
    # Debian
    packagelist { 'mypackagelist': packages => [ 'linux-image-generic', 'grub-common' ] }

Keep kernel at a specific version, grub at latest, don't purge:

    # RedHat
    packagelist { 'mypackagelist': packages => [ 'kernel-2.6.32-279.el6.x86_64', 'grub' ] }
    # Debian
    packagelist { 'mypackagelist': packages => [ 'linux-image-generic 3.5.0.17.19', 'grub-common' ] }

Load in a packagelist from a list file (one package per line):

    # RedHat / Debian
    packagelist { '/root/my-packages.lst': }

Load in a packagelist file, purging anything not mentioned within it:

    # RedHat / Debian
    packagelist { '/root/my-packages.lst': purge => true }

Pass in a packagelist loaded from somewhere else:

    # RedHat / Debian
    packagelist { 'mypackagelist': packages => $packages }
