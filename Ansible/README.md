### Ansible Script
plus the configuration of the infraestructure, it is required to install HSS (host security service), this requires an agent that must be installed, and to do so we're going to use ansible plus a little script to have python that will be encoded and inyected into the machine

first we need to have a key pair in ssh and upload it into hhuawei cloud, for that we can use the terraform file in this folder and some commmands, to make it work the files should be in the following structure:

```
| main.tf
| - ssh
| | - rsa
| | - rsa.pub
```

then in the ssh folder we can run the following command to generate the key pair: `ssh-keygen -P "" -t rsa -b 2048 -m pem -f my-key-pair`
after it make sure the key has the correct permissions, otherwise it would throw an error message saying that the permissions are too open

after this we can run the terraform file in this folder and will inyect the following commands to an ECS:
```
#!/bin/bash
sudo apt update
sudo apt upgrade
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.8
```
after excecuting the terraform script we will have to excecute the command `terraform output --raw eipBob` to get the output made by terraform and put it into an inventory file to be procesable by ansible
then we can excecute `ansible-playbook -i inventory script_hss.yml` to set the configuration
