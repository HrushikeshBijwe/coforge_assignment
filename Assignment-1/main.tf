locals{
  region = "us-east-1"
  key_name = "assignment"
  private_key_path = "./assignment.pem"
  ssh_user = "ubuntu"

}

terraform {
    backend "s3" {
      bucket = "my-tf-assignment-bucket-1"
      key = "infra-app-state"
      region = "us-east-1"
    }
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
      private_key = file("${path.module}/assignment.pem")
      host        = aws_instance.app_server.public_ip
    }
  }
 
  tags = {
    Name = "AppServerInstance"
  }
}

resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.app_server]

  provisioner "local-exec" {
    command = "chmod 600 assignment.pem && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i '${aws_instance.app_server.public_ip},' --private-key assignment.pem nginx.yaml"
  }
}

output "nginx_ip" {
  value = aws_instance.app_server.public_ip
}

resource "aws_vpc" "main" {
  cidr_block       = "10.10.1.0/25"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.1.0/26"
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


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-gateway"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.main.id
}
