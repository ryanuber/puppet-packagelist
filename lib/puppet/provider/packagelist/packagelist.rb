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
