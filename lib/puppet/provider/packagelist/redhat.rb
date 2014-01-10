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

  commands :yum => "yum"

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

  def get_verify_failed_packages(packages)
    result = []
    packages.each do |package|
      result << package if not verify_package(package)
    end
    result
  end

  def verify_package(package)
    errors = Array(Puppet::Util::Execution.execute("rpm -V #{package}", :failonfail => false))
    errors.each do |error|
      errors.delete(error) if error.split[1] == 'c'
    end
    return errors.length == 0
  end

  def reinstall_packages(packages)
    packages.each do |package|
      reinstall_package(package)
    end
  end

  def reinstall_package(package)
    Puppet.notice "Package verification for #{package} failed, reinstalling"
    begin
      yum "-d", "0", "-e", "0", "-y", "reinstall", package
    rescue Puppet::ExecutionFailure
      fail Puppet::Error, "Failed to reinstall package #{package}"
    end
  end
end
