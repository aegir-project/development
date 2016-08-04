#!/usr/bin/env bash

AEGIR_VERSION=7.x-3.x

if [ ! -d aegir-home ]; then
  mkdir aegir-home
  chmod 777 aegir-home
fi

cd aegir-home

# Build a full hostmaster frontend on the host with drush make, with working-copy option.
if [ ! -d hostmaster-$AEGIR_VERSION ]; then
   drush make http://cgit.drupalcode.org/provision/plain/aegir.make?h=$AEGIR_VERSION hostmaster-$AEGIR_VERSION --working-copy --no-gitinfofile
#   cp hostmaster-$DEVMASTER_VERSION/sites/default/default.settings.php devmaster-$DEVMASTER_VERSION/sites/default/settings.php
#   mkdir hostmaster-$AEGIR_VERSION/sites/devshop.site
   chmod 777 hostmaster-$AEGIR_VERSION/sites -R
fi

# Clone drush packages.
if [ ! -d .drush ]; then
    mkdir .drush
    cd .drush
    git clone git@git.drupal.org:project/provision.git
    cd provision
    git checkout $AEGIR_VERSION

    git clone git@git.drupal.org:project/registry_rebuild.git --branch 7.x-2.x

    cd ../../../
fi

# Clone tests
git clone git@github.com:aegir-project/tests.git aegir-home/tests

# Clone documentation
git clone git@github.com:aegir-project/documentation.git

# Clone dockerfiles
git clone git@github.com:aegir-project/dockerfiles.git
