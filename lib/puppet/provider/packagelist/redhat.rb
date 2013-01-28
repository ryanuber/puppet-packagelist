# puppet-packagelist - Dynamically create package resources from lists
#
# @author     Ryan Uber <ru@ryanuber.com>
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

require 'puppet/provider'
require 'puppet/util/execution'

Puppet::Type.type(:packagelist).provide :redhat do
  confine :osfamily => :redhat
  defaultfor :osfamily => :redhat

  def get_package_name(package)
    case package
    when /^(.+)-\d+[^-]*-\d+[^-]*/, /^(.+)-\d+[^-]*/, /^(.+)\Z/
      $1
    else
      package
    end
  end

  def get_package_version(package)
    case package
    when /^.+-(\d+[^-]*-\d+[^-]*)/, /^.+-(\d+[^-]*)-/, /^.+-(\d+[^-]*)\Z/
      $1
    else
      "latest"
    end
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
