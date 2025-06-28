
locals{
  region = "us-east-1"
  key_name = "assignment"
  private_key_path = "C:/coforge_assignment/Assignment-1/assignment.pem"
  ssh_user = "ubuntu"

}


resource "aws_instance" "app_server" {
 
  ami           = data.aws_ami.coforge_assignment.id
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.my_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name = local.key_name
    user_data = <<-EOF
        #!/bin/bash
        sudo apt update
        sudo apt install ansible -y
        echo "Ansible installed successfully"       
        EOF
 provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = aws_instance.app_server.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.app_server.public_ip},' --private-key Assignment-1 nginx.yaml"
  }
  tags = {
    Name = "AppServerInstance"
  }
}
/*
resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.app_server]

  provisioner "local-exec" {
    command = "ansible-playbook -u root --private-key ./assignment.pem -i ${aws_instance.app_server.public_ip} nginx.yaml"
  }
}
*/
output "nginx_ip" {
  value = aws_instance.app_server.public_ip
}

resource "aws_vpc" "main" {
  cidr_block       = "10.10.10.0/25"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.10.0/26"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-example"
  }
}


resource "aws_s3_bucket" "coforge_assignment" {
  bucket = "my-tf-assignment-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}


data "aws_ami" "coforge_assignment" {
  most_recent      = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250610"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "main" {
    name = "terraform-sg"
    vpc_id      = aws_vpc.main.id
    egress = [
        {
          cidr_blocks      = ["0.0.0.0/0", ]
          description      = ""
          from_port        = 0
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "-1"
          security_groups  = []
          self             = false
          to_port          = 0
        }
    ]
    ingress = [
        {
          cidr_blocks      = ["0.0.0.0/0", ]
          description      = ""
          from_port        = 0
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "-1"
          security_groups  = []
          self             = false
          to_port          = 0
        }
    ]
}