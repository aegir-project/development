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
    $this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile')
      ->option('build-arg', "AEGIR_UID=$user_uid")
      ->tag('aegir/hostmaster')
      ->run()
    ;
    // aegir/hostmaster:xdebug
    $this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-xdebug')
      ->tag('aegir/hostmaster:xdebug')
      ->run()
    ;
    // aegir/hostmaster:privileged
    $this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-privileged')
      ->tag('aegir/hostmaster:privileged')
      ->run()
    ;
    // aegir/web
    $this->taskDockerBuild('dockerfiles')
      ->option('file', 'dockerfiles/Dockerfile-web')
      ->tag('aegir/web')
      ->run()
    ;
  }
}