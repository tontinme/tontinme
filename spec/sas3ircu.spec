Name:           sas3ircu
Version:        2.0
Release:        1%{?dist}
Summary:        LSI Corporation SAS3 IR Configuration Utility
License:        Unknown
URL:            http://www.avagotech.com/cs/Satellite?pagename=AVG2%2FsearchLayout&locale=avg_en&Search=sas3ircu&submit=search
Source0:        sas3ircu.tar.gz
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
LSI Corporation SAS3 IR Configuration Utility

%prep
rm -rf %{_builddir}/%{name}-%{version}
mkdir -p %{_builddir}/%{name}-%{version}
cd %{_builddir}/%{name}-%{version}
tar zxvf %{SOURCE0}

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{_sbindir}
cp %{_builddir}/%{name}-%{version}/sas3ircu %{buildroot}/%{_sbindir}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc
%attr(0755,root,root) %{_sbindir}/sas3ircu

%changelog
* Wed Jul 25 2012 Harvard University FAS Research Computing <rchelp@fas.harvard.edu> - 0.2-1
- use %{_sbindir}

* Fri Jul 20 2012 Harvard University FAS Research Computing <rchelp@fas.harvard.edu> - 0.1-1
- Initial package
