#! /bin/bash

apt-get update
apt-get install python ansible git -y

wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy
./cloud_sql_proxy -instances=wordpress-248302:us-east1:wordpress=tcp:3306 &

export HOME=/root

git clone https://github.com/vasylgnatiuk/wordpress-lab-cloud-sql.git /wordpress-lab

ansible-playbook /wordpress-lab/playbook.yml