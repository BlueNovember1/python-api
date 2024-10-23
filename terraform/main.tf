provider "aws" {
  region = "us-east-1" 
}

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instances"

  # Otwieramy port 22 dla SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Dopuszczanie ruchu z każdego adresu IP (dla testów)
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Dopuszczanie ruchu z każdego adresu IP (dla testów)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}


resource "aws_instance" "build_machine" {
  ami           = "ami-0c55b159cbfafe1f0"  # AMI dla Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "your-key" # Wprowadź swoją nazwę klucza SSH

  security_groups = [aws_security_group.ec2_security_group.name]

  tags = {
    Name = "Build-Machine"
  }

  # Provisioner do uruchamiania skryptu bash na instancji BUILD
  provisioner "file" {
    source      = "scripts/build_setup.sh"
    destination = "/home/ec2-user/build_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/build_setup.sh",
      "/home/ec2-user/build_setup.sh"
    ]
  }
}


resource "aws_instance" "test_machine" {
  ami           = "ami-0c55b159cbfafe1f0"  # AMI dla Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "your-key"  # Wprowadź swoją nazwę klucza SSH

  security_groups = [aws_security_group.ec2_security_group.name]

  tags = {
    Name = "Test-Machine"
  }

  provisioner "file" {
    source      = "scripts/test_setup.sh"
    destination = "/home/ec2-user/test_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/test_setup.sh",
      "/home/ec2-user/test_setup.sh"
    ]
  }
}
