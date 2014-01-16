#!/bin/bash
sed -i "/$1/d" /home/git/.ssh/authorized_keys
cat /home/deploy/$1.pub | gitreceive upload-key $1