resource "tls_private_key" "tfe" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#resource "local_file" "tfe" {
#  filename        = "tfe.pem"
#  content         = tls_private_key.tfe.private_key_pem
#  file_permission = "0400"
#}

resource "aws_key_pair" "tfe" {
  key_name   = "tfe-${random_pet.tfe.id}"
  public_key = tls_private_key.tfe.public_key_openssh
}

module "tfe" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~>5.0"

  name = "tfe-${random_pet.tfe.id}"

  ami               = data.aws_ami.ubuntu_linux.id
  instance_type     = "m5.xlarge"
  availability_zone = element(module.vpc.azs, 2)
  subnet_id         = element(module.vpc.public_subnets, 2)

  key_name           = aws_key_pair.tfe.id
  enable_volume_tags = false
  root_block_device = [
    {
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = 10
      delete_on_termination = true
      tags = {
        Name = "tfe-${random_pet.tfe.id}-root"
      }
    }
  ]
  ebs_block_device = [
    {
      device_name           = "/dev/sdf"
      volume_type           = "gp3"
      volume_size           = 10
      encrypted             = true
      delete_on_termination = true
      tags = {
        MountPoint = "/tmp"
        Name       = "tfe-${random_pet.tfe.id}-tmp"
      }
    },
    {
      device_name           = "/dev/sdg"
      volume_type           = "gp3"
      volume_size           = 10
      encrypted             = true
      delete_on_termination = true
      tags = {
        MountPoint = "/var"
        Name       = "tfe-${random_pet.tfe.id}-var"
      }
    },
    {
      device_name           = "/dev/sdh"
      volume_type           = "gp3"
      volume_size           = 50
      encrypted             = true
      delete_on_termination = true
      tags = {
        MountPoint = "/var/lib/docker"
        Name       = "tfe-${random_pet.tfe.id}-var-lib-docker"
      }
    }
  ]

  associate_public_ip_address = true

  create_iam_instance_profile = true

  user_data = file("files/userdata.sh")

  iam_role_policies = {
    SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_security_group_ids = [
    module.sg_remote_mgmt_allow_all.security_group_id
  ]

  depends_on = [
    module.vpc
  ]
}

resource "null_resource" "tfe" {

  # Changes to tfe instance requires re-provisioning
  triggers = {
    instance_id = module.tfe.id
  }

  connection {
    host        = module.tfe.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.tfe.private_key_openssh
    timeout     = "10m"
    script_path = "/home/ubuntu/remote-exec.sh"
  }

  provisioner "file" {
    source      = "files/replicated.conf"
    destination = "/tmp/replicated.conf"
  }

  provisioner "file" {
    content = templatefile("files/settings.json",
      {
        "hostname" = module.tfe.public_dns
      }
    )
    destination = "/tmp/settings.json"
  }

  provisioner "file" {
    source      = "files/tfe.rli"
    destination = "/tmp/tfe.rli"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Pausing for userdata completion...",
      "sleep 60",
      "sudo lsblk",
      "sleep 3",
      "sudo mkdir -p /opt/tfe",
      "sudo mkdir -p /opt/install/tfe",
      "curl -sLo /tmp/install.sh https://install.terraform.io/ptfe/stable",
      "chmod +x /tmp/install.sh",
      "sudo mv /tmp/install.sh /opt/install/tfe/install.sh",
      "sudo mv /tmp/settings.json /opt/install/tfe/settings.json",
      "sudo mv /tmp/tfe.rli /opt/install/tfe/tfe.rli",
      "sudo mv /tmp/replicated.conf /etc/replicated.conf",
      "cd /opt/install/tfe && sudo ./install.sh no-proxy private-address=${module.tfe.private_ip} public-address=${module.tfe.public_ip}",
    ]
  }

  provisioner "local-exec" {
    when    = create
    command = "while ! curl -ksfS --connect-timeout 5 https://${module.tfe.public_dns}/_health_check?full=1; do sleep 30; done"
  }

  depends_on = [
    module.tfe
  ]
}
