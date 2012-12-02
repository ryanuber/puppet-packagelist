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

Puppet::Type.type(:packagelist).provide :redhat do
  defaultfor :osfamily => :redhat

  def get_purge_list(allowed_packages)
    result = []
    installed = %x(rpm -qa).split("\n")
    if installed == nil 
      fail Puppet::Error, "Could not query local RPM database"
    end 
    installed.each do |package|
      # In RHEL, GPG keys show up in this output, so skip them (we really don't want
      # to uninstall imported GPG keys)
      next if package.start_with?('gpg-pubkey')
      if not allowed_packages.include?(package)
        nameonly = %(rpm -q --qf "%{name}" #{package})
        if not allowed_packages.include?(nameonly)
          result << package
       end
      end
    end
    result
  end

end
