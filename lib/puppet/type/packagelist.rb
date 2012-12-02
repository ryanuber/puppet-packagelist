# Dynamically create package resources from list files
#
# @author    Ryan Uber <ryan@blankbmx.com>
# @license   Apache License, Version 2.0
# @category  functions
# @package   apply_packagelist
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

    Basic Syntax:
    apply_packagelist('/path/to/list/file', '[purge=nopurge]')

    The purge option determines whether or not to purge packages that do not
    appear in your package set. It defaults to nopurge. Set it to 'purge' to
    enable pruning, or omit it to skip the purging stage.

    You need to pass in the path of a file that contains a newline-delimited
    list of package names to apply. For each package in this list, an ensure
    will be dynamically created to latest. This allows you to either place
    an exact package version in (along with the name), or simply the package
    name if you want the latest from your mirror. Example follows:

      kernel-2.6.32-220.4.1.el6.x86_64
      grub-0.97-75.el6.x86_64
      vim-enhanced

    This would ensure that kernel and grub matched the versions specified, and
    the latest vim-enhanced from your configured mirrors.

    An easy way to create a package list for an entire system is using RPM
    directly. Examples follow.

    With versions:
    rpm -qa > /path/to/list/file

    Without versions (to get latest):
    rpm -qa --qf='%{name}\\n' > /path/to/list/file

    Limitations
    1) Inability to pass plain package names (without version/arch/release etc) with the \"purge\" option
    2) Only RPM-based operating systems are supported at this time."

  def self.title_patterns
    [ [ /^(.*?)\/*\Z/m, [ [ :source ] ] ] ]
  end

  newparam(:purge, :boolean => true) do
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:source) do
    isnamevar
    validate do
      unless Puppet::Util.absolute_path?(value)
        fail Puppet::Error, "Source file path must be fully qualified, not '#{value}'"
      end
    end
    munge do |value|
      ::File.expand_path(value)
    end
  end

  newparam(:packages) do
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
    if self.value(:packages) != nil
      packages = self.value(:packages)
    elsif self.value(:source) != nil
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
