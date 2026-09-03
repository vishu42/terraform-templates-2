locals {
  dev_env_tag = {
    environment = "dev"
  }
}



resource "aws_default_vpc" "default" {
  tags = merge(local.dev_env_tag, {
    Name = "default-vpc"
  })
}

resource "aws_default_subnet" "default" {
  availability_zone = "eu-central-1a"
  tags = merge(local.dev_env_tag, {
    Name = "default-subnet"
  })
}

resource "aws_default_subnet" "default_2" {
  availability_zone = "eu-central-1b"
  tags = merge(local.dev_env_tag, {
    Name = "default-subnet-2"
  })
}

resource "aws_security_group" "alb_sg" {
  count  = 1
  name   = "alb-sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
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
}


resource "aws_lb_listener" "http" {
  count             = 1
  load_balancer_arn = aws_lb.supabase[0].arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.supabase[0].arn
  }
}

resource "aws_lb_target_group" "supabase" {
  count    = 1
  name     = "supabase"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "401"
  }
}

resource "aws_lb_target_group_attachment" "supabase" {
  count            = 1
  target_group_arn = aws_lb_target_group.supabase[0].arn
  target_id        = module.vm[0].vm.id
  port             = 8000
}

# alb
resource "aws_lb" "supabase" {
  count              = 1
  name               = "supabase-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[0].id]
  subnets            = [aws_default_subnet.default.id, aws_default_subnet.default_2.id]
  tags = merge(local.dev_env_tag, {
    Environment = "Dev"
  })
}

# TODO: add security rules
module "vm" {
  count                       = 1
  source                      = "../../../modules/aws/vm"
  suffix                      = "supabase"
  ami_id                      = "ami-02003f9f0fde924ea"
  instance_type               = "t3.large"
  subnet_id                   = aws_default_subnet.default.id
  region                      = "eu-central-1"
  associate_public_ip_address = true
  public_key                  = file("/Users/vishaltewatia/.ssh/aws-supabase-instance.pub")
  install_docker_on_boot      = true
  mount_external_disk_on_boot = true
  root_block_device_size      = 20
  ebs_block_device_size       = 25
  tags = merge(local.dev_env_tag, {
    Environment = "Dev"
  })
}
