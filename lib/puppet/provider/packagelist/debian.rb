# puppet-packagelist - Dynamically create package resources from lists
#
# @author     Ryan Uber <ru@ryanuber.com>
# @link       https://github.com/ryanuber/puppet-packagelist
# @license    http://opensource.org/licenses/MIT
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
