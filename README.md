# HelloWorld HelmOperator CICD Pipeline Component

This "HelloWorld" Helm Operator component was shamelessly copied (with permission) from Swati Nair of IBM and lays down a simple BusyBox component through a Helm chart via an operator.  This component is an example of a fully onboarded component in the new CICD pipeline including build, test, deploy, and publishing to Quay.  This README will walk you through onboarding an existing or new component onto the new CICD Pipeline.  

# High-Level Requirements

In order to interface your component with the pipeline, you need to include some artifacts produced by CICD in your repo:

1. `Makefile` entries to bootstrap the build harness + build harness extensions.  This line will pull [build-harness-extensions](https://github.com/open-cluster-management/build-harness-extensions) which will also pull and configure the [build-harness](https://github.com/open-cluster-management/build-harness).  
2. `.travis.yml` template that defines the CICD provided travis job interface.  Any input required from a squad will be parameterized and noted.  

You'll also need to produce some artifacts that are specific to your component, required for interface with the `component` and `pipeline` build harness module:

1. `COMPONENT_NAME` file containing the name of your component to be produced by your build.  
2. `COMPONENT_VERSION` file containing the version of your component to be produced by your build.  
3. `RELEASE_VERSION` file containing your components' targetted product version (for example: 1.2 for Product version 1.2).  Used in pipeline placement.  
4. Within the template `.travis.yml`, scripts that you are expected to supply in the root of your component directory will be called as appropriate:
   * `install-build-dependencies.sh` - install any build dependencies you have
   * `build.sh` - execute any build actions
   * `unit-test.sh` - execute unit tests
   * `e2e-test.sh` - execute integration tests, assumptions can be made that the broader environment will be up

# Travis Job Behavior

Using the `.travis.yml` template provided, your jobs will have the following behavior:

## PRs

PR builds will run the `build`, `unit-test`, and `test-e2e` stages.  These stages will build your component and publish a PR-tagged image to quay.io, run your unit tests, deploy your component to an OCP cluster, and run your e2e tests.  

## Master/Release Versioned Branch Builds

Builds on master or release verisoned will run the `build` and `publish` stages.  These stages will build your component and push to quay.io with final tags (`<version>-<git-sha>`) and update the CICD pipeline repo's integration manifest to point to your new image. 

## Non-Master/Release Versioned Builds

If a branch name is not present in the list of publish branches in your travis.yml:
```
    - stage: publish
      name: "Publish the image to quay with an official version/sha tag and publish entry to integration pipeline stage"
      if: type = push AND branch IN ( master )
``` 
under `branch in (<branches>)` the travis job will simply build an image tagged with `<version>-<git-sha>` and push it to quay so you can test!  

# How-To Onboard Your Component

## .travis.yml

First, start by copying the `.travis.yml` from this repository into your repository.  We'll update/build this this throughout the following sections.  We won't have to make too many edits, and almost all of the edits will be in the `env:` section.  

## Component Specific Scripting

You'll need to identify which scripts you need to implement out of the following list one-by-one.  CICD is working to provide generalized scripts to accomodate some common components types for component build and deploy, but we won't capture all of the possibilities.  

You can find the generalized component scripts available through the build-harness-extensions `component` module [here](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin).  If you're able to find a `bin` of scripts that partially or fully matches your component, update `COMPONENT_TYPE` in `.travis.yml` to that `bin` name. As an example, this component is a `helmoperator`.  

Once you've reviewed the available bins of scripts and set `COMPONENT_TYPE` if relevant, walk through each of the next subsections:

### install-dependencies

The `install-dependencies` script is used to install all of the dependencies for your build.  

If you found a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) with an `install-dependencies` script that matches your needs, make sure `COMPONENT_INIT_COMMAND` isn't set in your `.travis.yml` and skip to the next subsection.  

If you didn't find a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) matching your needs, implement a script (we recommend calling it `install-dependencies.sh` for clarity) and put it in the base directory of your component's git repo.  Set `COMPONENT_INIT_COMMAND` in `.travis.yml` to `${TRAVIS_BUILD_DIR}/<script-name>`.  

In this component, the `install-dependenices` script for this repo is defined by the [helmoperator bin](https://github.com/open-cluster-management/build-harness-extensions/blob/master/modules/component/bin/helmoperator/install-dependencies.sh)

### build

The `build` script is used by the build harness component module to build your component.   The script will be called with an argument that is the `<repo>/<component>:<tag>` of the component your build script needs to output.  This component will be referenced by that input identifier in the following steps, so the naming/tagging must be correct, if not your component won't enter the pipeline!

If you found a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) with a `build` script that matches your needs, make sure `COMPONENT_BUILD_COMMAND` isn't set in your `.travis.yml` and `COMPONENT_TYPE` is set to that component bin, and skip to the next subsection.  

If you didn't find a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) matching your needs, implement a script (we recommend calling it `build.sh` for clarity) and put it in the base directory of your component's git repo.  Set `COMPONENT_BUILD_COMMAND` in `.travis.yml` to `${TRAVIS_BUILD_DIR}/<script-name>`.  

In this component, the `build.sh` script for this repo is defined by the [helmoperator bin](https://github.com/open-cluster-management/build-harness-extensions/blob/master/modules/component/bin/helmoperator/build.sh)

### unit-test

The `unit-test` script is used by the build harness component module to run your unit tests.   The script will be called with an argument that is the `<repo>/<component>:<tag>` of the component that your unit tests scripts need to test.  If your tests occur as part of the build, you'll need to implement a script that for this stage that is a no-op and passes cleanly!

If you found a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) with a `unit-test` script that matches your needs, make sure `COMPONENT_UNIT_TEST_COMMAND` isn't set in your `.travis.yml` and `COMPONENT_TYPE` is set to that component bin, and skip to the next subsection.  

If you didn't find a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) matching your needs, implement a script (we recommend calling it `run-unit-tests.sh` for clarity) and put it in the base directory of your component's git repo.  Set `COMPONENT_UNIT_TEST_COMMAND` in `.travis.yml` to `${TRAVIS_BUILD_DIR}/<script-name>`.  

In this component, the `run-unit-tests.sh` script for this repo is defined by the [helmoperator bin](https://github.com/open-cluster-management/build-harness-extensions/blob/master/modules/component/bin/helmoperator/run-unit-tests.sh)

### deploy

The `deploy` script is used by the build harness component module to deploy your component to a running OCP 4.X cluster in preparation for e2e testing.   The script will be called with an argument that is the `<repo>/<component>:<tag>` of the component that your script needs to deploy.  

If you found a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) with a `deploy-to-cluster` script that matches your needs, make sure `COMPONENT_DEPLOY_COMMAND` isn't set in your `.travis.yml` and `COMPONENT_TYPE` is set to that component bin, and skip to the next subsection.  

If you didn't find a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) matching your needs, implement a script (we recommend calling it `deploy-to-cluster.sh` for clarity) and put it in the base directory of your component's git repo.  Set `COMPONENT_DEPLOY_COMMAND` in `.travis.yml` to `${TRAVIS_BUILD_DIR}/<script-name>`.  

In this component, the `deploy-to-cluster.sh` script for this repo is defined [in the repository](deploy-to-cluster.sh) and is passed into the `.travis.yml` as an environment variable:
```
env:
  global:
  ...
    - COMPONENT_DEPLOY_COMMAND=${TRAVIS_BUILD_DIR}/deploy-to-cluster.sh
  ...
```
### e2e-test

The `e2e-test` script is used by the build harness component module to run your e2e tests on your PR component deployed on an OCP cluster.   The script will be called with an argument that is the `<repo>/<component>:<tag>` of the component that your e2e tests scripts need to test.  

If you found a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) with a `run-e2e-tests` script that matches your needs, make sure `COMPONENT_E2E_TEST_COMMAND` isn't set in your `.travis.yml` and `COMPONENT_TYPE` is set to that component bin, and skip to the next subsection.  

If you didn't find a component in the [component module bin](https://github.com/open-cluster-management/build-harness-extensions/tree/master/modules/component/bin) matching your needs, implement a script (we recommend calling it `run-e2e-tests.sh` for clarity) and put it in the base directory of your component's git repo.  Set `COMPONENT_E2E_TEST_COMMAND` in `.travis.yml` to `${TRAVIS_BUILD_DIR}/<script-name>`.  

In this component, the `run-e2e-tests.sh` script for this repo is defined by the [helmoperator bin](https://github.com/open-cluster-management/build-harness-extensions/blob/master/modules/component/bin/helmoperator/run-unit-tests.sh)

## Metadata Files

### COMPONENT_NAME

`COMPONENT_NAME` should be a file containing the name of your component to be produced by your build. 

### COMPONENT_VERSION

`COMPONENT_VERSION` file containing the version of your component to be produced by your build.  

### RELEASE_VERSION

`RELEASE_VERSION` file containing your components' targetted product version (for example: 1.2 for Product version 1.2).  This will be used to determine which branch to promote your component into within the CICD Pipeline.  

## Makefile

Make sure you either copy the `Makefile` from this repository, or place the contents of this `Makefile` within your own `Makefile`.  We rely on the makefile to bootstrap the [build-harness](https://github.com/open-cluster-management/build-harness) and [build-harness-extensions](https://github.com/open-cluster-management/build-harness-extensions).  

## `.travis.yml`

After following all of the above, ensure that your copy of the `.travis.yml` has all of the "Component Specific" environment variables defined to your liking, and ensure that all "Required" environment variables are properly defined.  

## Travis Environment Variables

You need to properly set the following environment variables under "Settings" for the Travis job for your component repository:
* `DOCKER_USER` and `DOCKER_PASS`: the username and token for a robot account for the destination Quay repository.  You can learn more about creating a Robot Account [here](https://docs.quay.io/glossary/robot-accounts.html)
* `GITHUB_USER` and `GITHUB_TOKEN`: the username and token for a GitHub user with access to your component repository, the build harness and extensions, and a clusterpool.  

# Conclusion

If you've made it this far, your component should now be prepared for the CICD pipeline.  You can verify your `.travis.yml` using the [`travis` CLI's linter](https://support.travis-ci.com/hc/en-us/articles/115002904174-Validating-travis-yml-files). Then its time to start up your Travis job and try it out!  Contact CICD at #private-cloud-cicd in IBM Slack or #acm-devops in CoreOS Slack with any questions!
