# Dynamically create package resources from list files
#
# @author    Ryan Uber <ryan@blankbmx.com>
# @license   Apache License, Version 2.0
# @category  modules
# @package   packagelist
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Puppet::Type.newtype(:packagelist) do
  @doc = 
    "Dynamcially creates a package resource for each element in a list, and
    ensures that each version is enforced. Any package not defined in your
    package list will automatically generate a package resource with an
    ensure => absent, giving you the power to define exactly what you want
    on your system in one list and enforce it using Puppet.

    For each package in a package list, an ensure will be dynamically created
    to 'latest'. This allows you to either place an exact package version in
    (along with the name), or simply the package name if you want the latest
    from your mirror.

    Options
    =======
    source
    Defines the path to a package list file. This option can be passed as the
    resource name as well. This argument conflicts with the packages argument.

    packages
    A package list to pass directly in. This argument conflicts with the
    source argument.

    purge
    Whether or not to purge packages that are not present in the package list.

    Creating package lists
    ======================
    An easy way to create a package list for an entire system is using RPM
    directly. Examples follow.

    With versions:
    rpm -qa > my-packages.lst

    Without versions (to get latest):
    rpm -qa --qf='%{name}\\n' > my-packages.lst

    Examples
    ========
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

    Limitations
    ===========
    1) Inability to pass plain package names (without version/arch/release etc) with the \"purge\" option"

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
    validate do |value|
      puts "name=#{value}"
    end
    isnamevar
  end

  newparam(:source) do
    desc "The path to a package list. This can be passed as a parameter or as
    the resource identifier. It must contain a fully-qualified path. You cannot
    use this argument in conjunction with the 'packages' argument."
    validate do |value|
      puts "source=#{value}"
      unless Puppet::Util.absolute_path?(value)
        fail Puppet::Error, "Source file path must be fully qualified, not '#{value}'"
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
      unless value.kind_of?(Array)
        raise ArgumentError, "Supplied package list is not an array"
      end
    end
    munge do |value|
      value
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

  def generate
    if self.value(:packages)
      packages = self.value(:packages)
    elsif self.value(:source)
      packages = File.read(self.value(:source)).split("\n")
    end
    result = []
    add_packages(packages).each do |package|
      result << package
    end
    if self.value(:purge)
      purge_packages(provider.get_purge_list(packages)).each do |package|
        result << package
      end
    end
    result
  end

  def add_packages(packages)
    result = []
    packages.each do |package|
      result << Puppet::Type.type(:package).new(:name => package, :ensure => :latest)
    end
    result
  end

  def purge_packages(packages)
    result = []
    packages.each do |package|
      result << Puppet::Type.type(:package).new(:name => package, :ensure => :absent)
    end
    result
  end

end
