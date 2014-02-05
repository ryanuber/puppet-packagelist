require 'puppet/provider'
require 'puppet/util/execution'

Puppet::Type.type(:packagelist).provide :redhat do
  confine :osfamily => :redhat
  defaultfor :osfamily => :redhat

  def get_package_name(package)
    if re = /^(.+)-([^-]+)-([^-]+)\.(\w+)\Z/.match(package)
      re.captures[0]
    else
      package
    end
  end

  def get_package_version(package)
    if re = /^(.+)-([^-]+)-([^-]+)\.(\w+)\Z/.match(package)
      sprintf('%s-%s', re.captures[1], re.captures[2])
    else
      "latest"
    end
  end

  def get_packages_list(packages)
    result = {}
    packages.each do |package|
      name = get_package_name(package)
      version = get_package_version(package)

      # Because of puppet bug #1720, we need to rewrite the kernel
      # package name into name-version format.
      if name == 'kernel' and version != 'latest'
        name = "#{name}-#{version}"
        version = 'installed'
      end

      result[name] = version
    end
    result
  end

  def get_purge_list(allowed_packages)
    result = []
    installed = Puppet::Util::Execution.execute('rpm -qa', :failonfail => true,
      :combine => false).split("\n")
    if installed == nil 
      fail Puppet::Error, "Could not query local RPM database"
    end 
    installed.each do |package|
      # In RHEL, GPG keys show up in this output, so skip them (we really don't want
      # to uninstall imported GPG keys)
      if package.start_with?('gpg-pubkey')
        Puppet.debug("Not purging gpg-pubkey package '#{package}'")
        next
      end

      # Account for packages specified by name-only in the package list
      name = get_package_name(package)
      if allowed_packages.include?(name)
        Puppet.debug("Not purging '#{package}' because '#{name}' found in package list")
        next
      end

      if allowed_packages.include?(package)
        Puppet.debug("Not purging '#{package}' because present in package list")
        next
      end

      Puppet.debug("Adding package '#{package}' to purge list")
      result << package
    end
    result
  end

end
