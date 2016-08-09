#!/usr/bin/env bash

AEGIR_VERSION=7.x-3.x

if [ ! -d aegir-home ]; then
  mkdir aegir-home
fi

cd aegir-home

# Build a full hostmaster frontend on the host with drush make, with working-copy option.
if [ ! -d hostmaster-$AEGIR_VERSION ]; then
   drush make http://cgit.drupalcode.org/provision/plain/aegir.make?h=$AEGIR_VERSION hostmaster-$AEGIR_VERSION --working-copy --no-gitinfofile
#   cp hostmaster-$DEVMASTER_VERSION/sites/default/default.settings.php devmaster-$DEVMASTER_VERSION/sites/default/settings.php
#   mkdir hostmaster-$AEGIR_VERSION/sites/devshop.site
fi

# Clone drush packages.
if [ ! -d .drush ]; then
    mkdir -p .drush/commands
    cd .drush/commands
    git clone git@git.drupal.org:project/provision.git
    cd provision
    git checkout $AEGIR_VERSION

    cd ..
    git clone git@git.drupal.org:project/registry_rebuild.git --branch 7.x-2.x
    cd ../..
fi

cd ../

# Clone tests
git clone git@github.com:aegir-project/tests.git aegir-home/tests

# Clone documentation
git clone git@github.com:aegir-project/documentation.git

# Clone dockerfiles
git clone git@github.com:aegir-project/dockerfiles.git

# Make symlinks for easy access to important repos
ln -s aegir-home/tests
ln -s aegir-home/.drush/commands/provision
ln -s aegir-home/hostmaster-$AEGIR_VERSION/profiles/hostmaster
ln -s aegir-home/hostmaster-$AEGIR_VERSION/profiles/hostmaster/modules/aegir/hosting

echo "================================================="
echo " Codebase preparation complete..."
echo "-------------------------------------------------"
echo " Preparing to build local docker image..."

USER_UID=`id -u`

echo " Found UID: $USER_UID "
echo "-------------------------------------------------"
echo " About to run 'docker build' command to create a custom image for you."
echo " If you wish to abort, now is the time to hit CTRL-C "
echo ""
echo " Waiting 5 seconds..."
sleep 5

docker build --build-arg AEGIR_UID=$USER_UID --build-arg AEGIR_GID=$USER_UID -t aegir/hostmaster:local dockerfiles

echo "================================================="
echo " All setup! Now run this command to launch: "
echo "                                                 "
echo "   docker-compose up -d                          "
echo "                                                 "
echo " Use this command to follow the logs:             "
echo ""
echo "    docker-compose logs -f                      "
echo ""
echo " You need to follow the logs to know when the container is ready."
echo ""
echo " Execute this command to enter the aegir container:"
echo "                                                 "
echo "   docker-compose exec hostmaster bash           "
echo "                                                 "
echo "-------------------------------------------------"
echo " NOTE: On some hosts (like Fedora) you might get "
echo "   an error on docker-compose up:                 "
echo "                                                 "
echo "      opendir(/var/aegir/.drush): failed to open dir: Permission denied  "
echo "                                                 "
echo "   This is likely because you have SELinux setup."
echo "   To fix, run the following command:            "
echo "                                                 "
echo "   chcon -Rt svirt_sandbox_file_t aegir-home     "
echo "-------------------------------------------------"
echo " Thanks! Please report any issues to http://github.com/aegir-project/development "
echo "================================================="
