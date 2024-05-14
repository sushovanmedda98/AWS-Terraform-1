resource "aws_vpc" "VPC" {
    cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
  
}
resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.VPC.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
  
}
resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.VPC.id
 
}
resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IG.id

    }
  
}
resource "aws_route_table_association" "RTA1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
  
}
resource "aws_route_table_association" "RTA2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.RT.id
  
}

resource "aws_security_group" "SG" {
  name        = "web"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.VPC.id
  tags = {
    Name = "web"
  }


  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
    ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
}

resource "aws_s3_bucket" "BUCKET" {
    bucket = "********"
  
}

resource "aws_instance" "EC1" {
    ami = "*************"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.SG.id ]
    subnet_id = aws_subnet.sub1.id
    key_name = "bitun"

}
resource "aws_instance" "EC2" {
    ami = "*************"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.SG.id ]
    subnet_id = aws_subnet.sub2.id
    key_name = "bitun"

}

########### creating a load balancer
resource "aws_lb" "LB" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Environment = "testing"
  }
}

resource "aws_lb_target_group" "TG" {
    name = "TG"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.VPC.id

    health_check {
      path = "/"
      port = "traffic-port"
    }
  
}

resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.TG.arn
    target_id = aws_instance.EC1.id
    port = 80
  
}
resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.TG.arn
    target_id = aws_instance.EC2.id
    port = 80
  
}

resource "aws_lb_listener" "listner" {
    load_balancer_arn = aws_lb.LB.arn
    port = 80
    protocol = "HTTP"

    default_action {
      target_group_arn = aws_lb_target_group.TG.arn
      type = "forward"
    }
}

output "loadbalancerdns" {
    value = aws_lb.LB.dns_name
  
}
    








