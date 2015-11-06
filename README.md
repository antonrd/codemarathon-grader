## CodeMarathon Grader

### Overview

The CodeMarathon Grader is a system that can be used to execute programs or parts of programs written is several programming languages against a predefined set of inputs and to check the produced outputs.

It has been inspired a lot by a related project called [the Maycamp Arena](https://github.com/valo/maycamp_arena). Many of the ideas laid down in it are used in the CodeMarathon Grader. However, this grader's goal is to be more universal in terms of how it can be used and what programming languages it can support.

A working version of the system can be found here: [grader.codemarathon.com](http://grader.codemarathon.com/).

### Tasks execution

The idea is to keep each program execution in a sandboxed environment by limiting the CPU and memory used as well as suppress some other capabilities of the programs.

The grader uses the notion of tasks where each task has a set of inputs and outputs and a checker program verifying the correctness of the produced outputs by the tested programs.

To achieve this the grader runs as a Rails app and exposes a RESTful API, which can be used to define new tasks, upload inputs/outputs for them, submit new program runs and retrieve the status of existing runs.

Hence, the grader can be used by external services, which can communicate with it through the API. To do this one needs a registered account and a secret key.

### Components

The grader stores data about user accounts and created tasks in a database.

It runs the programs in a [Docker](https://www.docker.com/) container to achieve sandboxing. In order to put some additional limitations it uses a runner, which was taken from the Maycamp Arena.

Hopefully, this combination of the runner and Docker will allow the grader to sandbox the programs it runs well enough to limit their resource usage and any undesired behavior.

In order to upload inputs/outputs to the grader the API users need to define a path on a server, where the files can be found. They will need to add the grader's public key in their `authorized_keys` file to allow it to fetch the files using [rsync](https://rsync.samba.org/) whenever needed.

Once the files are fetched they get stored on the same machine where the grader is running. This whole process of moving and storing files around needs to be improved in the future to make it more secure and fail proof.

The grader uses the `sendmail` utility to send some emails. There is a small tweak needed to make this work fast. It's described below.

In order to execute the requested task runs there is a rake task (`grader:start`), which is run separately and constantly checks the database for pending runs. It sleeps for 1 second if nothing is found and checks again. In production running the Rails app and the rake task is handled by [upstart](http://upstart.ubuntu.com/). It gets set up by the deployment scripts.

### Sanboxing

As mentioned above this version of the grader uses a combination of Docker containers and a runner script, which together are supposed to limit CPU and memory according to some pre-set values. Some other things like network connectivity should be limited by Docker. Forking is not exactly forbidden although it is possible to limit the number of processes. The reason is that some languages rely on having more than one thread/process running and this could break them.

In a previous version of the grader when it was supporting C++, Java (through gcj) and Python a combination of other two tools was used. For C++ and Java we used the Moe's sandbox tool [isolate](http://www.ucw.cz/moe/isolate.1.html). It was doing a great job overall but it was harder to apply to interpreted languages. For Python we used the EdX sandboxing tool [CodeJail](https://github.com/edx/codejail) with some modifications to make it work for the grader's purposes.

With time, in order to unify things we switched to using the current solution taken from Maycamp's Arena. It has been working there well for a while now and seems to be giving more flexibility in adding more languages to the platform.

Compilation is not yet run in a sandbox but it seems like a good idea to do that. This is a future task.

### Deployment prerequisites

To make deployment easier the grader contains some [Ansible](http://www.ansible.com/home) scripts. It is possible that this README misses some details of how deployment should be done but overall it describes the idea.

This means that you need to install Ansible locally, in order to be able to run the scripts.

All the scripts live in the directory `provisioning/`.

First of all you need to define the server to deploy to and the user for accessing the server in `provisioning/production.ini`.

Then, a few roles are defined in `provisioning/roles`, which get used by the various files in `provisioning/*.yml`. In these files you will need to modify some variable in order to match your deployment setup.

The grader has been deployed to servers with several Ubuntu distributions, with the latest one being 14.04 LTS.

Before running any scripts you will need to create a user on the target server. The default is `grader`. It needs to be part of the `admin` and `sudo` groups to be able to execute some commands related to the deployment:

```bash
sudo adduser grader
sudo usermod -a -G admin grader
sudo usermod -a -G sudo grader
```

Also, you will need to edit the sudoers file in order to avoid the need to type a password for the `grader` user each time it uses `sudo`:

```bash
sudo visudo -f /etc/sudoers.d/myOverrides
```

and add a line like this in this file: `grader  ALL=NOPASSWD: ALL`.

The utility `sendmail` used to send some emails from the grader could be really slow on some setups. If you exprience this you may need to modify your `etc/hosts` file to contain something like this, so that it works fast:

`127.0.0.1 grader.codemarathon.com localhost grader.codemarathon.com`

where you need to replace the values with the real domain where the grader is deployed to.

To have a smooth deployment you may need to fix your SSH config file (typically `~/.ssh/config`) to have forwarding of keys:

```
Host host_name
  ...
  ForwardAgent yes
```

As mentioned above each API client of the grader will need to have its public key in the autorized_keys file (e.g. `~/.ssh/authorized_keys`) in order to be able to send it files.

### Deployment

Hopefully, after all the prerequisites are completed you will be able to run a few Ansible scripts and complete the deployment.

The Rails app is being served using a combination of [Unicorn](http://unicorn.bogomips.org/) and [nginx](http://nginx.org/). The database is MySql for the moment. Docker is used for sandboxing. Sendmail is used for sending emails.

First of all you need to run from the root of the project:

`ansible-playbook ./provisioning/setup_production.yml -i ./provisioning/production.ini`

This will install the needed packages and configure some of them whenever needed. See more details about this step in the `install` and `config` Ansible roles.

You also need to set up the Docker image, which will be used to create containers. This can be done by running:

`ansible-playbook ./provisioning/setup_docker.yml -i ./provisioning/production.ini`

This will use the `Dockerfile` available in the root of the project.

After that you need to proceed with the deployment, which will fetch the latest code from Github, install gems, run migrations and precompile the assets:

`ansible-playbook ./provisioning/deploy_production.yml -i ./provisioning/production.ini`

You need to create the `config/grader.yml` file and make sure it contains the right values. You can use the `config/grader.example/yml` file as basis. More about this config file is included below.

Finally, use the tasks for starting/stopping/restarting the application. The first time a start would be sufficient. After subsequent deploys a restart is more suitable.

**IMPORTANT!:** For the moment the grader allows creation of new accounts only if there is an invite for them. You will need to create one manually in the database. You can use the Rails console (`rails c`) to do this. After that you should be able to register a new user with the invited email address and manage this process from the web interface of the grader. In the future this will be made more convenient hopefully.

### Running in Vagrant

There is also a `Vagrantfile` file in the root of the project for running the grader in a Vagrant virtual box. This is useful if you're developing using a OS different from Ubuntu. You may need to tweak some of the Ansible scripts to make this work for you because the Vagrant file references these scripts in order to setup a box for you.

After Rails 4.2 the server is only serving on `127.0.0.1`, not on `0.0.0.0` as before. This may be an issue for the port forwarding feature in Vagrant and VirtualBox. If this is not working for you, try running the server like that `rails s -p XXXX -b 0.0.0.0`.

### Configuration

All configuration for the grader lives in the file `config/grader.yml`. It has sections according to Rails environments and defines important aspects of the grader's operation. There are comments about most fields about what they are about.

### Client setup

A client of the grader is expected to have a registered account, which is done through the web UI. There should be user invite create for the email address with which the new client will subscribe. New accounts are confirmed through a link sent to the email of the client.

After an account has been created the client must go to their profile page and request a secret token to be generated for them. This is the token to be sent along with the email address to the RESTful API for each API call.

In order to upload inputs/outputs for tasks the client needs to specify in their profile a path to a server where the files are to be fetched from. Look at the example on the web page. Of course, the remote server must have the public key of the grader authorized as mentioned above.

It is also possible to have a set up in which the client runs on the same machine as the grader and the files are just moved around locally.

### Supported languages

For the moment the supported languages are C++, Java (through gcj), Python and Ruby. For Python there is a special mode in which the code for one particular method can be submitted. Read more about this mode in the section about using the grader.

The architecture of the grader makes it possible to run programs in virutally any language that has a compiler or interpreter. However, it is important to research how well the sandbox works for each separate case. Even the support for the current languages may have vulnerabilities. Please report if any such are found.

### How to use it?

The grader accepts either whole programs or for Python - one method's contents (unit tests). The whole program mode accepts a whole valid program in each of the supported langauges and runs it in a stand-alone mode.

The unit test mode is for tasks for which the API client (or task author) has supplied a wrapper program, which is written in such way so that it calls a given method and processes its result. The method can accept parameters and the solution to such problems must contain the expected method with implementation in it. **NOTE:** This is only available for Python at the moment but should be easily extendable to the other languages, too.

There are example Ruby and shell scripts in the directory `sample_api_calls`, which will allow you to test using the API of a running grader. These scripts simulate all possible API calls (as of 2015-07-27), you just need to tweak the params they send with the requests to match what you have in your version of the grader.

### TODO list
* Make it easier to bootstrap the user creation.
* Run compilation in the sandbox, too.
* Think of a better way to handle file uploads for tasks
* Allow other methods for sending email
* Make it possible to run unit tests for all languages
