# puppet-packagelist - Dynamically create package resources from lists
#
# @author     Ryan Uber <ryuber@cisco.com>
# @link       https://github.com/ryanuber/puppet-packagelist
# @license    http://opensource.org/licenses/MIT
# @category   modules
# @package    packagelist
#
# MIT LICENSE
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
    if purge?
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
