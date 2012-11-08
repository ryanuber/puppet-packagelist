Apply list with purging
=======================

Apply the "packages.lst" list, *PURGING* any packages that are
not present in the list. Notice how explicit and lengthy this
list is. It is definig exactly which packages should be installed.
Anything *not* in this list would have an ensure => absent
dynamically generated for it.
