provider "aws" {

region = "ap-south-1"
profile = "tanuja"
}

resource "tls_private_key" "example122" {
  algorithm   = "RSA"
 
}


resource "aws_key_pair" "instkey" {
  key_name   = "keynew"
  public_key =  tls_private_key.example122.public_key_openssh 

}

resource "local_file" "mykeyfile" {
    content     = tls_private_key.example122.private_key_pem 
    filename =  "keynew.pem"
}

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames ="true"
  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "my_subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "mygw"
  }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "myroute_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.r.id
}

resource "aws_eip" "example" {
  vpc = true
}

resource "aws_nat_gateway" "gw2" {
  allocation_id = "${aws_eip.example.id}"
  subnet_id     = "${aws_subnet.my_subnet.id}"

  tags = {
    Name = "myNATgw"
  }
}
resource "aws_route_table" "r2" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.gw2.id}"
  }

  tags = {
    Name = "myroute_table2"
  }
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.my_subnet2.id
  route_table_id = aws_route_table.r2.id
}

resource "aws_security_group" "allow_tls" {
  name        = "my_security_group1"
  description = "create firewall for my wp os"
  vpc_id      = "${aws_vpc.main.id}"

    ingress {
    description = "allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_security_group1"
  }
}

resource "aws_security_group" "allow_tls2" {
  name        = "my_security_group2"
  description = "create firewall for my mysql os"
  vpc_id      = "${aws_vpc.main.id}"

    ingress {
    description = "tcp"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_security_group2"
  }
}

resource "aws_instance" "wp" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name =  "keynew"
  vpc_security_group_ids = [ aws_security_group.allow_tls.id ]
  subnet_id = aws_subnet.my_subnet.id
  tags = {
    Name = "mywpos"
  }
}

resource "aws_instance" "wysql" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  key_name =  "keynew"
  vpc_security_group_ids = [ aws_security_group.allow_tls2.id ]
  subnet_id =  aws_subnet.my_subnet2.id
  tags = {
    Name = "mymysqlos"
  }
}
