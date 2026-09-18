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
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCp+qajMCD3NGi/4R0ofqFgKSUgs6C23h9StJRlmaUI/Ijzn5opoyy/lbuN9f3mBeQ9xFlo/HecyjH46NjXwEVbQFF34GTZZDh7do5vILqmTY0ycrlJngirHR5UvSj505n9GOktXBtav3dpMHLypas7GbFprvxlLqYPi2D1UGfJyntJN98+aMKuWLrYEUJ4VG8XrVnd45kf0XYdDl+vAl/q1dPaqkkrlU0I0a4CFgdb/6jxp292CIqX8b3LYWNARNODXh58uQuul+1m5h0BxYQu50VNXOIXjdiSTI1hSAMFsvUD23GR9lrfojJEJFHQrxoFtXASS813+R+3f8TJ9CbMmt3wrRQCoCd5D1ZiD/THLhESBpIBPo1Z+cobrDh5b+yxa7FoUyuXv0SHIVwdXrRz+d9ugTOR7m3hOlrTxrv+5LQvD7jMFmNN8rjXJaShYRrX2PLcnf+ub6FyYTJUn1/3NyQKzbcjiymCqEHYzxIDA7hedtAGtiI+eUOhklaxJ2qDLCX4IHRifkkLM32S8FXPaOx4YkfEh7gTSPJ85JyVB427TiUdtvJvjvulz+lba5dMa9qYrc8Y3GgNsVN3zx8cc6Exma6QHfWKkDWGtrCf67M9z8vFT4IKOy3oSNDTy04hqNdHrHm/N4OVh9s7Z3tqDTCWTVygbANcXimNXt8EiQ== vishaltewatia@Vishals-MacBook-Pro.local"
  install_docker_on_boot      = true
  mount_external_disk_on_boot = true
  root_block_device_size      = 20
  ebs_block_device_size       = 25
  tags = merge(local.dev_env_tag, {
    Environment = "Dev"
  })
}
