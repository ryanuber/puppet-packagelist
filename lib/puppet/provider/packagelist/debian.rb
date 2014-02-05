require 'puppet/provider'
require 'puppet/util/execution'

Puppet::Type.type(:packagelist).provide :debian do
  confine :osfamily => :debian
  defaultfor :osfamily => :debian

  def get_package_name(package)
    if re = /^(.+)(\s+)(.+)\Z/.match(package)
      re.captures[0]
    else
      package
    end
  end

  def get_package_version(package)
    if re = /^(.+)(\s+)(.+)\Z/.match(package)
      re.captures[2]
    else
      "latest"
    end
  end

  def get_packages_list(packages)
    result = {}
    packages.each do |package|
      name = get_package_name(package)
      version = get_package_version(package)
      result[name] = version
    end
    result
  end

  def get_purge_list(allowed_packages)
    result = []
    installed = Puppet::Util::Execution.execute('dpkg-query --show', :failonfail => true,
      :combine => false).split("\n")
    if installed == nil 
      fail Puppet::Error, "Got 0-length list of installed packages from dpkg-query"
    end 
    installed.each do |package|
      name = get_package_name(package)
      version = get_package_version(package)

      # Account for packages specified by name-only in the package list
      if allowed_packages.include?(name)
        Puppet.debug("Not purging '#{package}' because '#{name}' found in package list")
        next
      end

      # Skip if exact package version is in package list
      if allowed_packages.collect { |p| p.gsub(/\s+/, ' ') }.include?("#{name} #{version}")
        Puppet.debug("Not purging '#{name} #{version}' because present in package list")
        next
      end

      Puppet.debug("Adding package '#{name}' to purge list")
      result << package
    end
    result
  end

end
