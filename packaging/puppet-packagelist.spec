%define realname packagelist
%define _module_dir /etc/puppet/modules

name: puppet-packagelist
summary: Dynamically create package resources from lists
version: 0.2.7
release: 1%{?dist}
buildarch: noarch
license: MIT
source0: %{name}.tar.gz
requires: puppet

%description
Dynamcially creates a package resource for each element in a list, and ensures
that each version is enforced. Any package not defined in your package list will
automatically generate a package resource with an ensure => absent, giving you
the power to define exactly what you want on your system in one list and enforce
it using Puppet.

For each package in a package list, an ensure will be dynamically created to
"latest". This allows you to either place an exact package version in (along
with the name), or simply the package name if you want the latest from your
mirror.

%prep
%setup -n %{name}

%install
%{__mkdir_p} %{buildroot}/%{_module_dir}/%{realname}
%{__cp} -R lib %{buildroot}/%{_module_dir}/%{realname}

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(0644,root,root,0755)
%dir %{_module_dir}/%{realname}
%{_module_dir}/%{realname}/*

%changelog
* %(date "+%a %b %d %Y") %{name} - %{version}-%{release}
- Automatic build
