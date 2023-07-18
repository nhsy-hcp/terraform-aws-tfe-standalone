#!/bin/bash

mkfs -t ext4 /dev/nvme3n1
echo "/dev/nvme3n1    /tmp        ext4   defaults,discard,noexec,nosuid        0 1"  >> /etc/fstab
mkdir -p /mnt/tmp
mount /dev/nvme3n1 /mnt/tmp
rsync -avzh /tmp/ /mnt/tmp/
umount /mnt/tmp
mount /tmp

mkfs -t ext4 /dev/nvme2n1
echo "/dev/nvme2n1    /var        ext4   defaults,discard        0 1"  >> /etc/fstab
mkdir -p /mnt/var
mount /dev/nvme2n1 /mnt/var
rsync -avzh /var/ /mnt/var/
umount /mnt/var
mount /var

mkfs -t ext4 /dev/nvme1n1
echo "/dev/nvme1n1    /var/lib/docker        ext4   defaults,discard,noexec,nosuid        0 1"  >> /etc/fstab
mkdir -p /var/lib/docker
mount /var/lib/docker

lsblk

cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo Userdata completed
