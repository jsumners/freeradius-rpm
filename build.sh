#!/bin/bash

freeradiusVersion="3.0.7"

freeradiusUrl="ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-${freeradiusVersion}.tar.bz2"

which wget > /dev/null
if [ $? -ne 0 ]; then
  echo "Aborting. Cannot continue without wget."
  exit 1
fi

which rpmbuild > /dev/null
if [ $? -ne 0 ]; then
  echo "Aborting. Cannot continue without rpmbuild. Please install the rpmdevtools package."
  exit 1
fi

# Let's get down to business
TOPDIR=$(pwd)

if [ -e rpmbuild ]; then
  rm -rf rpmbuild/* 2>&1 > /dev/null
fi

echo "Verifying dependencies..."
deps=(
  'autoconf'
  'freetds-devel'
  'gdbm-devel'
  'json-c-devel'
  'krb5-devel'
  'libidn-devel'
  'libcurl-devel'
  'libpcap-devel'
  'libtalloc-devel'
  'libtool'
  'libtool-ltdl-devel'
  'mysql-devel'
  'net-snmp'
  'net-snmp-devel'
  'net-snmp-utils'
  'openldap-devel'
  'openssl-devel'
  'pam-devel'
  'pcre-devel'
  'perl-devel'
  'perl-ExtUtils-Embed'
  'perl-ExtUtils-Install'
  'perl-ExtUtils-MakeMaker'
  'perl-ExtUtils-ParseXS'
  'postgresql-devel'
  'python-devel'
  'readline-devel'
  'ruby-devel'
  'sqlite-devel'
  'unixODBC-devel'
  'ykclient'
  'ykclient-devel'
  'zlib-devel'
)
missingDeps=false
depsToInstall=""
for d in "${deps[@]}"; do
  rpm -qi ${d} 2>&1 1>/dev/null
  depInstalled=$?
  if [ ${depInstalled} -eq 1 ]; then
    providesList=$(rpm -q --whatprovides ${d})
    if [ "$providesList" != "" ]; then
      depInstalled=0
      for p in ${providesList}; do
        rpm -qi ${p} 2>&1 1>/dev/null
        i=$?
        depInstalled=$((depInstalled + i))
      done
    fi

    if [ $depInstalled -gt 0 ]; then
      missingDeps=true
      echo "Missing dependency: ${d}"
      depsToInstall="${depsToInstall} ${d}"
    fi
  fi
done

if [ "${missingDeps}" == "true" ]; then
  echo "Can't continue until all dependencies are installed!"
  echo -e "Issue: \`yum install ${depsToInstall}\`"
  exit 1
fi

echo "Creating RPM build path structure..."
mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,tmp}

echo "Getting source and preparing it..."
cd ${TOPDIR}/rpmbuild/SOURCES/
wget ${freeradiusUrl}

tar jxf freeradius-server-${freeradiusVersion}.tar.bz2
cd freeradius-server-${freeradiusVersion}/redhat/
cp freeradius-* ${TOPDIR}/rpmbuild/SOURCES/
cp ${TOPDIR}/src/freeradius.service ${TOPDIR}/rpmbuild/SOURCES/
cp ${TOPDIR}/src/freeradius.spec ${TOPDIR}/rpmbuild/SPECS/

echo "Building Freeradius RPM ..."

cd ${TOPDIR}/rpmbuild/
rpmbuild --define "_topdir ${TOPDIR}/rpmbuild" -ba "SPECS/freeradius.spec"