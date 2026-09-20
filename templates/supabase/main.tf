locals {
  common_tags = merge(var.tags, {
    environment = var.environment
  })
}




resource "aws_default_vpc" "default" {
  tags = merge(local.common_tags, {
    Name = "default-vpc"
  })
}

resource "aws_default_subnet" "default" {
  availability_zone = var.availability_zones[0]
  tags = merge(local.common_tags, {
    Name = "default-subnet"
  })
}

resource "aws_default_subnet" "default_2" {
  availability_zone = var.availability_zones[1]
  tags = merge(local.common_tags, {
    Name = "default-subnet-2"
  })
}

resource "aws_security_group" "alb_sg" {
  count  = 1
  name   = "${var.name}-alb-sg"
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

  tags = merge(local.common_tags, {
    Name = "${var.name}-alb-sg"
  })
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
  name     = "${var.name}-tg"
  port     = var.app_port
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

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "supabase" {
  count            = 1
  target_group_arn = aws_lb_target_group.supabase[0].arn
  target_id        = module.vm[0].vm.id
  port             = var.app_port
}

# alb
resource "aws_lb" "supabase" {
  count              = 1
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[0].id]
  subnets            = [aws_default_subnet.default.id, aws_default_subnet.default_2.id]
  tags = merge(local.common_tags, {
    Name = "${var.name}-alb"
  })
}

# TODO: add security rules
module "vm" {
  count                       = 1
  source                      = "../../modules/aws/vm"
  suffix                      = var.name
  ami_id                      = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_default_subnet.default.id
  region                      = var.region
  associate_public_ip_address = true
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCp+qajMCD3NGi/4R0ofqFgKSUgs6C23h9StJRlmaUI/Ijzn5opoyy/lbuN9f3mBeQ9xFlo/HecyjH46NjXwEVbQFF34GTZZDh7do5vILqmTY0ycrlJngirHR5UvSj505n9GOktXBtav3dpMHLypas7GbFprvxlLqYPi2D1UGfJyntJN98+aMKuWLrYEUJ4VG8XrVnd45kf0XYdDl+vAl/q1dPaqkkrlU0I0a4CFgdb/6jxp292CIqX8b3LYWNARNODXh58uQuul+1m5h0BxYQu50VNXOIXjdiSTI1hSAMFsvUD23GR9lrfojJEJFHQrxoFtXASS813+R+3f8TJ9CbMmt3wrRQCoCd5D1ZiD/THLhESBpIBPo1Z+cobrDh5b+yxa7FoUyuXv0SHIVwdXrRz+d9ugTOR7m3hOlrTxrv+5LQvD7jMFmNN8rjXJaShYRrX2PLcnf+ub6FyYTJUn1/3NyQKzbcjiymCqEHYzxIDA7hedtAGtiI+eUOhklaxJ2qDLCX4IHRifkkLM32S8FXPaOx4YkfEh7gTSPJ85JyVB427TiUdtvJvjvulz+lba5dMa9qYrc8Y3GgNsVN3zx8cc6Exma6QHfWKkDWGtrCf67M9z8vFT4IKOy3oSNDTy04hqNdHrHm/N4OVh9s7Z3tqDTCWTVygbANcXimNXt8EiQ== vishaltewatia@Vishals-MacBook-Pro.local"
  install_docker_on_boot      = true
  mount_external_disk_on_boot = true
  root_block_device_size      = var.root_block_device_size
  ebs_block_device_size       = var.ebs_block_device_size
  tags                        = local.common_tags
}
