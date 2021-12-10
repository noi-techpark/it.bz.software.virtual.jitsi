// Create Application LB
resource "aws_lb" "test" {
  name               = var.lb_name
  internal           = var.lb_internal //false
  load_balancer_type = var.lb_type //"application"
  security_groups    = var.lb_sg //[aws_security_group.lb_sg.id]
  subnets            = var.lb_subnet //aws_subnet.public.*.id

  enable_deletion_protection = var.lb_deletion_protection //true

  #access_logs {
  #  bucket  = aws_s3_bucket.lb_logs.bucket
  #  prefix  = "test-lb"
  #  enabled = true
  #}

  tags = {
    Environment = "production"
  }
}

// Create Target groups
resource "aws_lb_target_group" "test" {
  for_each = { for lb_tg in var.lb_tg_values : lb_tg.lb_tg_name => lb_tg }
  name     = each.value.lb_tg_name //"tf-example-lb-tg"
  port     = each.value.lb_tg_port //80
  protocol = each.value.lb_tg_protocol //"HTTP"
  vpc_id   = each.value.lb_tg_vpc //aws_vpc.main.id
  target_type = each.value.lb_tg_target_type //"instance"
  health_check {
    enabled = each.value.lb_tg_health_check_endabled //true
    path = each.value.lb_tg_health_check_path // "/"
    protocol = each.value.lb_tg_health_check_protocol // "HTTPS"
  }
}

// Add resources to target group
#resource "aws_lb_target_group_attachment" "test" {
#  target_group_arn = var.lb_tga_arn //aws_lb_target_group.test.arn
#  target_id        = var.lb_tga_id //aws_instance.test.id
#  port             = var.lb_tga_port //80
#}

// Spcifiy the action on incoming traffic -> forward to target groups
resource "aws_lb_listener" "front_end" {
  for_each = { for listener in var.lb_listener_values : listener.lb_listener_port => listener }
  load_balancer_arn = aws_lb.test.arn
  port              = each.value.lb_listener_port //"80"
  protocol          = each.value.lb_listener_protocol //"HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             =  each.value.lb_listener_default_action_type //"forward"
    target_group_arn =  aws_lb_target_group.test[each.value.lb_listener_default_tg_name].arn // jitsi-cluster-target-staging - 8443
  }
}

/*
* port 80 redirect - rule: https://#{host}:443/#{path}?#{query} - status code: 301
*
* listener on 8448 (matrix federation) - rule: forward -> 8008 -> matrix-cluster-target-staging
*/

#resource "aws_lb_listener_rule" "static" {
#  listener_arn = var.lb_rule_listener_arn //aws_lb_listener.front_end.arn
#  priority     = 100
#
#  condition {
#    host_header {
#      values = ["matrix.virtual.software.testingmachine.eu", "synapse.virtual.software.testingmachine.eu"] //matrix-cluster-target-staging 8008 - health: /health
#    }
#  }
#
#  condition {
#    host_header {
#      values = ["element.virtual.software.testingmachine.eu"] //matrix-element-target-staging 8080 - health: /
#    }
#  }
#
#  action {
#    type             = "forward"
#    target_group_arn = var.lb_rule_target_arn //aws_lb_target_group.static.arn e.g. matrix-cluster-target-staging
#  }
#
#  condition {
#    host_header {
#      values = ["jitsi.virtual.software.testingmachine.eu"] //matrix-element-target-staging 8443 - health: /
#    }
#  }
#}
