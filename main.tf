#declare the provider
provider "aws" {
  region = "us-east-1"

}

#create vpc
resource "aws_vpc" "vpcfruits" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name  = "vpcfruits"
    owner = "carolle"
  }

}

#create igw
resource "aws_internet_gateway" "igwfruits" {
  vpc_id = aws_vpc.vpcfruits.id
  tags = {
    Name = "igwfruits"
  }
}

#create a custom route table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpcfruits.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwfruits.id
  }
  tags = {
    Name = "Public-rt"
  }
}


#create subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.vpcfruits.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnetfruits"
  }
}

#associate subnet with RT
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

#create SG to allow port 22, 80, 443
resource "aws_security_group" "sgwebserver" {
  vpc_id      = aws_vpc.vpcfruits.id
  name        = "webserver-SG"
  description = "Allow SSH access to developers"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #defining outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "sgwebserver"
    owner = "Carolle"
  }
}
#Create a network interface with an IP in the subnet that was created in step 4
resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.public-subnet.id
  private_ips     = ["192.168.1.50"]
  security_groups = [aws_security_group.sgwebserver.id]

}

#8-Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "my-elastic-ip" {
  vpc                       = true
  network_interface         = aws_network_interface.ni.id
  associate_with_private_ip = "192.168.1.50"
  depends_on                = [aws_internet_gateway.igwfruits]

}

#9-Create an ubuntu server and install/enable apache 2
resource "aws_instance" "ubuntu-server" {
  instance_type     = "t2.micro"
  ami               = "ami-09d56f8956ab235b3"
  availability_zone = "us-east-1a"
  key_name          = "devops-carolle"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ni.id
  }
     tags = {
       Name = "webserver"
       Owner = "carolle"
     }

  user_data = <<EOF
#!/bin/bash
sudo apt get update -y
sudo apt install apache2 -y
sudo systemctl start apache2 
sudo systemctl enable apache2 
sudo echo "<html><h1>Hello World</h1>" /var/www/html/index.html'
EOF 
}