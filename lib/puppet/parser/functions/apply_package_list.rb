# Dynamically create package resources from encoded lists
#
# @author    Ryan Uber <ryan@blankbmx.com>
# @license   Apache License, Version 2.0
# @category  functions
# @package   apply_package_list
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

module Puppet::Parser::Functions
  newfunction(:apply_package_list, :type => :statement, :doc =>
    "Dynamcially creates a package resource for each element in an encoded
    object, and ensures that each version is enforced. Any package not
    defined in your package list will automatically generate a package
    resource with an ensure => absent, giving you the power to define
    exactly what you want on your system in one list and enforce it using
    Puppet.

    Basic Syntax:
    apply_package_list('/path/to/list/file', '[encoding=yaml]', '[purge=nopurge]')

    The encoding option will default to YAML if omitted, but can optionally
    be set to JSON to decode a JSON file instead. JSON decoding requires the
    json gem to be installed.

    The purge option determines whether or not to purge packages that do not
    appear in your package set. It defaults to nopurge.

    You need to feed in one encoded object containing a structure
    of package data. Examples follow.

    YAML:
    -
      name: \"kernel\"
      version: \"2.6.32\"
      release: \"220.4.1.el6\"
      arch: \"x86_64\"
    -
      name: \"grub\"
      version: \"0.97\"
      release: \"75.el6\"
      arch: \"x86_64\"

    JSON:
    [
      {
        \"name\":\"kernel\",
        \"version\":\"2.6.32\",
        \"release\":\"220.4.1.el6\",
        \"arch\":\"x86_64\"
      },
      {
        \"name\":\"grub\",
        \"version\":\"0.97\",
        \"release\":\"75.el6\",
        \"arch\":\"x86_64\"
      }
    ]

    This would ensure that kernel and grub matched the versions specified.
    You can also use keywords rather than versions by passing in an empty
    release, and using the keyword you want in the version section. For
    example, you could pass an empty release and \"latest\" as the version.
    This would ensure that the latest version of the package is installed.

    The architecture is not required on any package. However, if present,
    it does affect the way this function operates. If a non-null value
    other than the rare '(none)' architecture type is specified, the
    arch will be appended to the package name, creating a way for puppet
    to enforce architecture.

    Limitations:
    1) When checking installed packages against the provided list, only the
    name is validated. If there are multiple versions of an RPM installed,
    versions other than what is specified in your list would not be flagged
    for removal.
    2) Only RPM-based operating systems are supported at this time.") do |args|

    if args.length == 0
      raise Puppet::ParseError, "No package list specified during apply_package_list()"
    end

    file  = args[0]
    type  = args.length > 1 ? args[1] : 'yaml'
    purge = args.length > 2 ? args[2] : 'nopurge'

    if not File.exists?(file)
      raise Puppet::ParseError, "File '#{file}' not found during apply_package_list()"
    end

    if type == 'yaml'
      require 'yaml'
      packages = YAML.load_file(file)
    elsif type == 'json'
      require 'json'
      packages = JSON.parse(open(file).read)
    else
      raise Puppet::ParseError, "Encoding type '#{type}' not recognized during apply_package_list()"
    end

    if not ['purge', 'nopurge'].include?(purge)
      raise Puppet::ParseError, "Invalid argument '#{purge}' during apply_package_list()"
    end

    os = lookupvar('osfamily')
    if not ['RedHat', 'Debian'].include?(os)
      raise Puppet::ParseError, "Unsupported operating system detected during apply_package_list()"
    end
 
    allowed = Array.new

    packages.each do |package|
      ['name', 'version', 'release', 'arch'].each do |index|
        if not package.has_key?(index) or not package[index].kind_of?(String)
          raise Puppet::ParseError, "Unrecognized package format in file '#{file}' during apply_package_list()"
        end
      end
      e_name = package['name'] + ((package['arch'] != '') ? '.' + package['arch'] : '')
      e_version = package['version'] + (package['release'] != '' ? '-' + package['release'] : '')
      catalog.add_resource Puppet::Type.type(:package).hash2resource(
        {:name => e_name, :ensure => e_version}
      )
      allowed << package['name']
    end

    if purge == 'purge'
      installed = %x(rpm -qa --qf='%{name}\n').split("\n") if os == 'RedHat'
      installed = %x(dpkg --get-selections | awk '/install$/ {print $1}').split("\n") if os == 'Debian'
      if installed == nil
        raise Puppet::ParseError, "Could not query local package database during apply_package_list()"
      end
      installed.each do |package|
        # In RHEL, GPG keys show up in this output, so skip them (we really don't want
        # to uninstall imported GPG keys)
        next if os == 'RedHat' and package.start_with?('gpg-pubkey')
        if not allowed.include?(package)
          catalog.add_resource Puppet::Type.type(:package).hash2resource(
            {:name => package, :ensure => "absent"}
          )
        end
      end
    end

  end
end
