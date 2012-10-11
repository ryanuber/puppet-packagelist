Puppet Package Lists
====================

apply_package_list
------------------
Dynamcially creates a package resource for each element in an encoded
object, and ensures that each version is enforced. Any package not
defined in your package list will automatically generate a package
resource with an ensure => absent, giving you the power to define
exactly what you want on your system in one list and enforce it using
Puppet.

### Basic Syntax

    apply_package_list('/path/to/list/file', '[encoding=yaml]', '[purge=nopurge]')

The encoding option will default to YAML if omitted, but can optionally
be set to JSON to decode a JSON file instead. JSON decoding requires the
json gem to be installed.

The purge option determines whether or not to purge packages that do not
appear in your package set. It defaults to nopurge.

You need to feed in one encoded object containing a structure
of package data. Examples follow.

### YAML
    -
      name: "kernel"
      version: "2.6.32"
      release: "220.4.1.el6"
      arch: "x86_64"
    -
      name: "grub"
      version: "0.97"
      release: "75.el6"
      arch: "x86_64"

### JSON
    [
      {
        "name":"kernel",
        "version":"2.6.32",
        "release":"220.4.1.el6",
        "arch":"x86_64"
      },
      {
        "name":"grub",
        "version":"0.97",
        "release":"75.el6",
        "arch":"x86_64"
      }
    ]

This would ensure that kernel and grub matched the versions specified.
You can also use keywords rather than versions by passing in an empty
release, and using the keyword you want in the version section. For
example, you could pass an empty release and "latest" as the version.
This would ensure that the latest version of the package is installed.
  
The architecture is not required on any package. However, if present,
it does affect the way this function operates. If a non-null value
other than the rare '(none)' architecture type is specified, the
arch will be appended to the package name, creating a way for puppet
to enforce architecture.
  
### Limitations

* When checking installed packages against the provided list, only the
  name is validated. If there are multiple versions of an RPM installed,
  versions other than what is specified in your list would not be flagged
  for removal.

* Only RPM-based operating systems are supported at this time.
