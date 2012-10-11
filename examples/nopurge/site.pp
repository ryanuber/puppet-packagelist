# Apply the "packages.yml" list, *not* purging packages that are
# not present in the list.
apply_package_list("packages.yml", "yaml", "nopurge")
