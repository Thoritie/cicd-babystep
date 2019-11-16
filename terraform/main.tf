provider "aws" {
    access_key = "${var.access_id}"
    secret_key = "${var.secret_id}"
    region     = "ap-northeast-1"
}
resource "aws_vpc" "cicd-vpc" {
    cidr_block                       = "10.30.8.0/21"

    tags = {
        Name = "cicd-vpc"
    }
}

resource "aws_subnet" "cicd_public_subnet_zone_a" {
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    availability_zone               = "ap-northeast-1b"
    cidr_block                      = "10.30.8.0/24"

    tags = {
        Name = "cicd-vpc-public-subnet-zone-a"
    }
}

resource "aws_internet_gateway" "cicd_internet_gateway" {
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    tags = {
        Name = "cicd-vpc-public-internet_gateway"
    }
}

resource "aws_route_table" "cicd_public_route_table" {
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${aws_internet_gateway.cicd_internet_gateway.id}"
    }

    tags = {
        Name = "cicd-public-route-table"
    }
}

resource "aws_route_table_association" "cicd_public_route_table_association_zone_a" {
    subnet_id       = "${aws_subnet.cicd_public_subnet_zone_a.id}"
    route_table_id  = "${aws_route_table.cicd_public_route_table.id}"
}
resource "aws_security_group" "allow_ssh" {
    name = "allow-ssh"
    description = "All ssh conn"
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH inbound traffic"
    }

    tags = {
        Name = "allow-ssh"
    }
}

resource "aws_security_group" "allow_internet_outbound" {
    name = "allow_internet_outbound"
    description = "Allow Internet outbound"
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow Internet Outbound"
    }

    tags = {
        Name = "allow_internet_outbound"
    }
}

resource "aws_security_group" "allow_http_https" {
    name = "allow_http_https"
    description = "Allow http and https"
    vpc_id = "${aws_vpc.cicd-vpc.id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow Http inbound traffic"
    }


    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow Https inbound traffic"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow Internet Outbound"
    }

    tags = {
        Name = "allow_http_https"
    }
}

resource "aws_instance" "cicd-test-instance" {
    subnet_id       = "${aws_subnet.cicd_public_subnet_zone_a.id}"
    security_groups = [
        "${aws_security_group.allow_http_https.id}",
        "${aws_security_group.allow_ssh.id}",
    ]

    ami           = "ami-0cd744adeca97abb1"
    instance_type = "t2.micro"
    key_name      = "thoritie"
    associate_public_ip_address = true

    root_block_device {
        iops        = "600"
        volume_size = 50
        volume_type = "gp2"
    }

    tags = {
        Name = "cicd-instance"
    }
}
