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

Creating package lists
----------------------

An easy way to create a package list for an entire system is using RPM
directly. Examples follow.

With versions:
    rpm -qa > my-packages.lst

Without versions (to get latest):

    rpm -qa --qf="%{name}\n" > my-packages.lst

Examples
--------
Keep kernel and grub at latest, don't purge other packages:

    packagelist { 'mypackagelist': packages => [ 'kernel', 'grub' ] }

Keep kernel at a specific version, grub at latest, don't purge:

    packagelist { 'mypackagelist': packages => [ 'kernel-2.6.32-279.el6.x86_64', 'grub' ]

Load in a packagelist from a list file (one package per line):

    packagelist { '/root/my-packages.lst': }

Load in a packagelist file, purging anything not mentioned within it:

    packagelist { '/root/my-packages.lst': purge => true }

Pass in a packagelist loaded from somewhere else:

    packagelist { 'mypackagelist': packages => $packages }
