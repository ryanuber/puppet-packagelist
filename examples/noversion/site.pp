# Apply the "packages.yml" list, which contains no hardcoded version numbers,
# but rather keywords. This package list will pull in the latest GRUB, and
# park the kernel on whichever version was initially installed.
apply_package_list("packages.yml", "yaml", "nopurge")

