require 'puppet/type'

Puppet::Type.newtype(:packagelist) do
  @doc = "
Dynamcially creates a package resource for each element in a list, and
ensures that each version is enforced. Any package not defined in your
package list will automatically generate a package resource with an
ensure => absent, giving you the power to define exactly what you want
on your system in one list and enforce it using Puppet.

For each package in a package list, an ensure will be dynamically created
to 'latest'. This allows you to either place an exact package version in
(along with the name), or simply the package name if you want the latest
from your mirror."

  def self.title_patterns
    [
      [ /^((^\/(.*)\/?)*)\Z/m, [ [ :source ], [ :name ] ] ],
      [ /^(.*)\Z/m, [ :name ] ]
    ]
  end

  newparam(:purge, :boolean => true) do
    desc "Purge any installed packages that are not present in the list"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:name) do
    isnamevar
  end

  newparam(:source) do
    desc "The path to a package list. This can be passed as a parameter or as
    the resource identifier. It must contain a fully-qualified path. You cannot
    use this argument in conjunction with the 'packages' argument."
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        self.fail "Source file path must be fully qualified, not '#{value}'"
      end
    end
    munge do |value|
      ::File.expand_path(value)
    end
  end

  newparam(:packages) do
    desc "A packagelist. This is a simple list containing package strings. You
    cannot use this argument in conjunction with the 'source' argument."
    validate do |value|
      unless value.kind_of?(Array) or value.kind_of?(String)
        self.fail "packagelist must be string or array"
      end
    end
    munge do |value|
      value.kind_of?(String) ? [value] : value
    end
  end

  validate do
    creator_count = 0
    creators = [:source, :packages]
    creators.each do |param|
      creator_count += 1 if self.value(param)
    end
    self.fail "You cannot specify more than one of #{creators.collect { |p| p.to_s}.join(", ")}" if creator_count > 1
  end

  def eval_generate
    if self.value(:packages)
      packages = self.value(:packages)
    elsif self.value(:source)
      packages = File.read(self.value(:source)).split("\n")
    end
    result = add_packages(packages)
    if purge?
      purge_packages(provider.get_purge_list(packages)).each do |package|
        result << package
      end
    end
    result
  end

  def add_packages(packages)
    result = []
    provider.get_packages_list(packages).each do |name, version|
      self.debug "ensuring #{name} => #{version}"
      result << Puppet::Type.type(:package).new(:name => name, :ensure => version)
    end
    self.debug "adding #{result.count} package resources"
    result
  end

  def purge_packages(packages)
    result = []
    packages.each do |package|
      name = provider.get_package_name(package)
      self.debug "ensuring #{name} => purged"
      result << Puppet::Type.type(:package).new(:name => name, :ensure => :purged)
    end
    self.debug "purging #{result.count} total packages"
    result
  end

end
