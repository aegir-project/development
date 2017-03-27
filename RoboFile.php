<?php
/**
 * This is project's console commands configuration for Robo task runner.
 *
 * @see http://robo.li/
 */
class RoboFile extends \Robo\Tasks
{

  private $aegir_version = '7.x-3.x';

  private $repos = [
    'provision' => 'http://git.drupal.org/project/provision.git',
    'documentation' => 'http://github.com/aegir-project/documentation.git',
    'aegir-home/tests' => 'http://github.com/aegir-project/tests.git',
    'dockerfiles' => 'http://github.com/aegir-project/dockerfiles.git',
  ];

  /**
   * Clone all needed source code and build devmaster from the makefile.
   */
  public function prepareSourcecode() {


    // Create the Aegir Home directory.
    if (file_exists("aegir-home/.drush/commands")) {
      $this->say("aegir-home/.drush/commands already exists.");
    }
    else {
      $this->taskExecStack()
        ->exec('mkdir -p aegir-home/.drush/commands')
        ->run();
    }

    // Clone all git repositories.
    foreach ($this->repos as $path => $url) {
      if (file_exists($path)) {
        $this->say("$path already exists.");
      }
      else {
        $this->taskGitStack()
          ->cloneRepo($url, $path)
          ->run();
      }
    }

    // Run drush make to build the devmaster stack.
    $make_path = "aegir-home/hostmaster-{$this->aegir_version}";
    if (file_exists($make_path)) {
      $this->say("Path $make_path already exists.");
    } else {
      $result = $this->_exec("drush make provision/aegir.make $make_path --working-copy --no-gitinfofile");
      if ($result->wasSuccessful()) {
        $this->say('Built hostmaster from makefile.');
        return TRUE;
      }
      else {
        $this->say("Drush make failed with the exit code " . $result->getExitCode());
        return FALSE;
      }
    }
  }

  /**
   * Build aegir containers from the Dockerfiles.
   * Detects your UID or you can pass as an argument.
   */
  public function prepareContainers($user_uid = NULL) {

    if (is_null($user_uid)) {
      $user_uid = $this->_exec('id -u')->getMessage();
    }

    $this->say("Found UID $user_uid. Passing to docker build as a build-arg...");

    // aegir/hostmaster
    if ($this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile')
      ->option('build-arg', "AEGIR_UID=$user_uid")
      ->tag('aegir/hostmaster')
      ->run()
      ->wasSuccessful() == FALSE) {
      $this->yell('Docker Build Failed!');
      exit(1);
    }

    // aegir/hostmaster:xdebug
    if ($this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-xdebug')
      ->tag('aegir/hostmaster:xdebug')
      ->run()
      ->wasSuccessful() == FALSE) {
        $this->yell('Docker Build Failed!');
      exit(1);
    }

    // aegir/hostmaster:privileged
    if ($this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-privileged')
      ->tag('aegir/hostmaster:privileged')
      ->run()
      ->wasSuccessful() == FALSE) {
      $this->yell('Docker Build Failed!', '');
      exit(1);
    }

    // aegir/web
    if ($this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-web')
      ->tag('aegir/web')
      ->run()
        ->wasSuccessful() == FALSE) {
      $this->yell('Docker Build Failed!');
      exit(1);
    }
    return TRUE;
  }

  /**
   * Launch devshop containers using docker-compose up and follow logs.
   *
   * Use "--test" option to run tests instead of the hosting queue.
   */
  public function up($opts = ['follow' => 1, 'test' => false, 'prepare-containers' => false]) {

    if (!file_exists('aegir-home')) {
      if ($opts['no-interaction'] || $this->ask('aegir-home does not yet exist. Run "prepare:sourcecode" command?')) {
        if ($this->prepareSourcecode() == FALSE) {
          $this->say('Prepare source code failed.');
          exit(1);
        }
      }
      else {
        $this->say('aegir-home must exist for Aegir to work. Not running docker-compose up.');
        return;
      }
    }


    if ($opts['prepare-containers']) {
      if ($this->prepareContainers() == FALSE) {
        $this->say('Prepare source code failed.');
        exit(1);
      }
    }

    if ($opts['test']) {
      $cmd = "docker-compose run hostmaster 'run-tests.sh'";
    }
    else {
      $cmd = "docker-compose up -d";
      if ($opts['follow']) {
        $cmd .= "; docker-compose logs -f";
      }
    }
    if ($this->_exec($cmd)->wasSuccessful()) {
      exit(0);
    }
    else {
      exit(1);
    }
  }

  /**
   * Destroy all containers, docker volumes, and aegir configuration.
   */
  public function destroy() {
    $this->_exec('docker-compose kill');
    $this->_exec('docker-compose rm -fv');

    if ($this->confirm("Remove source code?")) {
      if ($this->_exec("sudo rm -rf aegir-home")->wasSuccessful()) {
        $this->say("Deleted source code.");
      }
      else {
        $this->yell('Unable to delete local source code! Remove manually to fully destroy your local install.');
      }
    }
  }
}