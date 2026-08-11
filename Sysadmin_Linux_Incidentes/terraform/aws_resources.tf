# --- S3 Bucket ---
resource "aws_s3_bucket" "app_data" {
  bucket = "lab-hybrid-bucket"
}

# --- Route53 (DNS) ---
resource "aws_route53_zone" "lab_internal" {
  name = "lab.internal"
}

# --- Application Load Balancer (ELB) ---
resource "aws_lb" "app_alb" {
  name               = "lab-hybrid-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = ["subnet-12345678"] # Fakecloud a veces requiere un subnet dummy
  
  tags = {
    Environment = "lab"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "lab-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-12345678" # Dummy VPC para Fakecloud

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200,301,302"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Registramos las IPs de las VMs en el DNS de Fakecloud
resource "aws_route53_record" "app_frontend" {
  zone_id = aws_route53_zone.lab_internal.zone_id
  name    = "frontend.lab.internal"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.app_alb.dns_name]
}
