Aegir Development Environment
=============================

This repo is designed to make it easier to develop aegir and related tools.

Clone this repo and run the `prepare.sh` script to setup all of the required
source code.

The included `docker-compose.yml` file will launch a running Aegir instance 
with the `aegir-home` directory mapped to `/var/aegir` in the container.

Got feedback? Suggested changes? Visit the repo at http://github.com/aegir-project/development.

## Setup

0. Install pre-requisites:
  - git
  - drush (locally, for building the stack).
  - docker. Docker for Mac Beta now works great.
  - docker-compose. Get the latest stable docker-compose(> 1.6), to ensure version 2 compose.yml file compatibility.

1. Clone this repo and enter the 'development' folder:

    ```
    git clone http://github.com/aegir-project/development aegir
    cd aegir
    ```

3. Run the `prepare.sh` script.

    ```
    bash prepare.sh
    ```

  This script does the following:

  - Creates an "aegir-home" folder and opens permissions. This maps to `/var/aegir` in the container.
  - Builds a hostmaster stack with the aegir.make file and uses "working copy" so all sub projects are git clones.
  - Clones provision and registry rebuild into the .drush folder.
  - Creates a custom local container for you, using your user's UID. This is so mounted folders can be written to and don't get saved as root on the host.
 
4. Run `docker-compose up -d && docker-compose logs -f`:

  This will download and launch mysql and aegir containers, detach from the 
  process so it will keep running, and then follows the logs output from the
  hostmaster container.

  You will have to wait a bit for hostmaster to install. Watch the logs for the
  "Congratulations" message and the one-time-login link.

  Once running, you can edit the files in ./aegir/hostmaster-7.x-3.x and get live when loading the site at http://aegir.local.computer

  *NOTE:* The `docker-compose.yml` is set to utilize port 80, so you will get an error
  if you have any other web server running locally on port 80.

  If you do not want this, simply change the `docker-compose.yml` file ports to 
  something else:
  
    ```
    ports:
        - 8080:80
    ```

  *Using local.computer:* The domain name http://local.computer is registered to Aegir
   contributor and set to resolve to 127.0.0.1, otherwise known as localhost.

   There is also a wildcard domain, so any subdomain on local.computer resolves
   to localhost.  This development environment uses the hostname 
   http://aegir.local.computer.  When you are creating sites in aegir, if you 
   want to access them without messing with DNS or Hosts file, you can use 
   http://sitename.local.computer as the domain name.

5. Get into the container:

  To get into the server as the aegir user using the terminal, run the command:
  
    ```
    docker exec -ti aegir_hostmaster_1 bash
    ```

  You will be dropped into a bash terminal as the aegir user, in the root folder,
   so change to your home directory with `cd` if you need to.

    ```
    aegir@aegir:/$ cd 
    aegir@aegir:$ drush @hostmaster uli 
    ```

  Remember, the home directory for the `aegir` user is mapped to `aegir-home` 
  on the docker host (your computer). Feel free to download or edit anything 
  into that folder.

6. Running Tests

  We have behat tests you should run if you start to work on Aegir.

  Drop into bash, cd into the tests folder, run `composer install`
  
    ```
    docker exec -ti aegir_hostmaster_1 bash
    aegir@aegir:/$ cd 
    aegir@aegir:~$ cd tests
    aegir@aegir:~/tests$ composer install
    ```

   Then bin/behat to run the tests:
      
    ```
    aegir@aegir:~/tests$ bin/behat
    ```
      