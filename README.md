torquebox-ansible
=================

Torquebox deployment from git using postgresql (configured using ansible for ubuntu)


How to use
----------

You will first need to add a new ```group_vars/all``` file that will be used by ansible to configure the script. Here is an example:

```yaml
bootstrap:
  ubuntu_release: precise
  logwatch_email: ops@porkepic.com
  deploy_password: 'your password of choice'
  user_keys: 
    - juggy

mod_cluster:
  version: 1.2.6

torquebox:
  version: 3.0.1
  backstage:
    admin: porkepic
    password: ******

postgresql:
  version: 9.3
  repo: 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main'
  install_development_headers: true

  user: postgres
  group: postgres

  config:
    shared_buffers: 24MB
    work_mem: 16MB

    checkpoint_segments: 3
    checkpoint_completion_target: 0.5

    effective_cache_size: 512MB

postgresql_backup:
  aws:
    access_key: <<your aws key>>
    secret_key: <<your aws key>>
    location: US

pgbouncer:
  user: postgres
  group: postgres

  config:
    database_host: 127.0.0.1
    database_port: 5432

    listen_addr: 127.0.0.1
    listen_port: 6432

    user: postgres

    auth_type: plain
    auth_file: /etc/pgbouncer/userlist.txt

```

Most of it is defaulted, but feel free to play with it. 

Next, to configure your SSH access you will need to edit the array ```user_keys``` to include all public keys you want to upload. I used the user name, but it can be anything. The public key file must have the same name and be added to the ```bootstrap/files``` directory. For example, ```bootstrap/files/juggy.pub```

If you want to use pgbouncer, make sure to add a ```userlist.txt``` to your server at the location of ```pgbouncer.config.auth_file```.

To test the whole thing, install Vagrant and type ```vagrant up``` in the terminal. You can now run the ansible playbook using ```ansible-playbook -i vagrant.host setup.yml --private-key=~/.vagrant.d/insecure_private_key```.


Roles Description
-----------------

- Bootstrap is to create a basic secure server that updates itself. Inspired by [5 Min server setup](http://plusbryan.com/my-first-5-minutes-on-a-server-or-essential-security-for-linux-servers). Should be run on every host.
- gitreceive installs [progrium/gitreceive](https://github.com/progrium/gitreceive) and configures it to receive pushes. You can push more than one repo and the script will handle the deployment for you (including bundler, assets precompilation and torquebox deployment)
- torquebox configures apache, installs mod_cluster and torquebox to allow deployment.
- pgbouncer and postgresql install the database and schedule a cron job to take backups and send them to a specified aws bucket.


Deployment
----------
To deploy to torquebox, you must provide a knob file within your project. The file must be located at ```RAILS_ROOT/torquebox/production-knob-yml```. This is the file that is going to be deployed to torquebox at the end of the deploy script.

Let's say you want to deploy your Rails app to your server. You first have to add a remote repo to your local repo:
```
git remote add production git@myserver.com/myrepo.git
```
Where ```myserver.com``` and ```myrepo.git``` are the domain name of your server and the name of the deployed app on the server. You must use the git user to push your repo and have them deployed correctly.

Now that you have a remote added, you can push to it.
```
git push production local_branch:master
```
You must push your ```local_branch``` to the remote's master branch. Watch your app deployment like you do in Heroku.

Your app is deployed using the deploy user. You should login to your server using that user too. 
```
ssh deploy@myserver.com
```
Your ssh public key is installed already so no password. Your application was deployed at ```/home/deploy/myrepo.git/current```. All previous versions are kept too. If you want to rollback, just point ```current``` to the desired git hash folder.

Futur
-----
I would like to add a small script that would ease common tasks like running the migrations or login into the console.

Please send me any other proposal/pull request.
