#!/bin/bash

AEGIR_VERSION=7.x-3.x
AEGIR_HOSTMASTER_ROOT=hostmaster-$AEGIR_VERSION

echo "==========================ÆGIR=========================="
echo " Hello there.                                           "
echo " Let's prepare a development environment for you.       "
echo "--------------------------------------------------------"

if [ ! -d aegir-home ]; then
  echo "Æ | Creating aegir-home directory..."
  mkdir aegir-home
fi

cd aegir-home

# Build a full hostmaster frontend on the host with drush make, with working-copy option.
#if [ ! -d $AEGIR_HOSTMASTER_ROOT ]; then
#   echo "Æ | Building hostmaster with drush make..."
#   drush make ../aegir-dev.make $AEGIR_HOSTMASTER_ROOT --working-copy --no-gitinfofile
#fi


DRUPALORG_PREFIX=https://git.drupal.org/project/
GITHUB_PREFIX=https://github.com/aegir-project/

# Uncomment to clone git repositories via SSH.
#DRUPALORG_PREFIX=git@git.drupal.org:project/
#GITHUB_PREFIX=git@github.com:aegir-project/

# Clone drush packages.
if [ ! -d .drush ]; then
    echo "Æ | Creating .drush/commands folder..."
    mkdir -p .drush/commands
    cd .drush/commands
    echo "Æ | Cloning Provision..."
    git clone ${DRUPALORG_PREFIX}provision.git
    cd provision
    git checkout $AEGIR_VERSION

    cd ..
    echo "Æ | Cloning Registry Rebuild..."
    git clone ${DRUPALORG_PREFIX}registry_rebuild.git --branch 7.x-2.x
    cd ../..
fi

cd ../

# Clone tests
if [ ! -d aegir-home/tests ]; then
  echo "Æ | Cloning tests..."
  git clone ${GITHUB_PREFIX}tests.git aegir-home/tests
fi

# Clone documentation
if [ ! -d documentation ]; then
  echo "Æ | Cloning documentation..."
  git clone ${GITHUB_PREFIX}documentation.git
fi

# Clone dockerfiles
if [ ! -d dockerfiles ]; then
  echo "Æ | Cloning dockerfiles..."
  git clone ${GITHUB_PREFIX}dockerfiles.git
fi

# Make symlinks for easy access to important repos
if [ ! -L tests ]; then
  echo "Æ | Creating symlinks to all git repos..."
  ln -s aegir-home/tests 2> /dev/null
  ln -s aegir-home/.drush/commands/provision  2> /dev/null
  ln -s aegir-home/hostmaster-$AEGIR_VERSION/profiles/hostmaster 2> /dev/null
  ln -s aegir-home/hostmaster-$AEGIR_VERSION/profiles/hostmaster/modules/aegir/hosting  2> /dev/null
fi;
echo "==========================ÆGIR=========================="
echo "Codebase preparation complete."

USER_UID=`id -u`

echo "--------------------------------------------------------"
echo " About to run 'docker build' command to create a custom image for you."
echo " If you wish to abort, now is the time to hit CTRL-C "
echo ""
echo " Found UID: $USER_UID "
echo ""
echo " Waiting 5 seconds..."
echo "--------------------------------------------------------"
sleep 5

echo "Æ | Running docker build ..."

cd dockerfiles
docker build -t aegir/hostmaster:dev .

# @TODO: Do we need to do this? Or can we just specify volume to /var/aegir in the compose file?
docker build -t aegir/hostmaster:local --build-arg NEW_UID=$USER_UID -f Dockerfile-local .
cd ..

echo "==========================ÆGIR=========================="
echo " About to run 'docker compose up -d && docker-logs -f'"
echo " If you wish to abort, now is the time to hit CTRL-C "
echo ""
echo " To cancel following docker logs, hit CTRL-C. The containers will still run."
echo ""
echo " Waiting 5 seconds..."
sleep 5

docker-compose up -d

if [ "$TRAVIS" == 'true' ]; then
  echo "We're in Travis mode ... skipping 'docker-compose logs -ft'"
else
  docker-compose logs -f
fi

echo "==========================ÆGIR=========================="
echo " Stopped following logs. To view logs again:     "
echo "    docker-compose logs -f                       "
echo "                                                 "
echo " To stop the containers:                         "
echo "    docker-compose kill                          "
echo "                                                 "
echo " To start the same containers again and watch the logs, run: "
echo "    docker-compose up -d ; docker-compose logs -f "
echo "                                                 "
echo " To fully destroy the containers and volumes, run:"
echo "    docker-compose rm -v"
echo "                                                 "
echo " If you destroy the containers, in order to start"
echo " again, you will have to  delete the "
echo " sites/aegir.local.computer folder:   "
echo "    rm -rf aegir-home/hostmaster-7.x-3.x/sites/aegir.local.computer"
echo "                                                 "
echo " To 'log in' to the container, run 'bash' with docker-compose exec.: "
echo "    docker-compose exec hostmaster bash            "
echo "                                                   "
echo " Then, you can run drush directly.                 "
echo "    drush @hostmaster uli                          "
echo "                                                   "
echo " To run drush from the host using docker:          "
echo "    docker-compose exec hostmaster drush @hostmaster uli  "
echo "                                                   "
echo "-----------------------------------------------------"
echo " Testing                                           "
echo " We have behat tests you can run from inside the container:"
echo "    docker-compose exec hostmaster bash           "
echo "    cd tests                                     "
echo "    composer install                               "
echo "    bin/behat                               "
echo ""
echo " You can edit the tests that run in 'tests/features'."
echo "-----------------------------------------------------"
echo " Thanks! Please report any issues to http://github.com/aegir-project/development/issues"
echo "==========================ÆGIR=========================="
