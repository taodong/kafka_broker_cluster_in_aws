provider "aws" {
  region = "${var.region}"
  version = "~> 1.12"
}

resource "aws_launch_configuration" "lc_kafka_app" {
  name_prefix            = "${var.product}-${var.env}-${var.type}_app-lc+"
  image_id               = "${length(var.kafka_ami_id) == 0 ? data.aws_ami.kafka_app.id : var.kafka_ami_id}"
  instance_type          = "${var.kafka_instance_type}"
  key_name               = "${var.deployer_key_name}"
  iam_instance_profile   = "${var.instance_role_profile}"
  security_groups        = ["${aws_security_group.kakfa_app_sg.id}"]
  user_data              = "${data.template_file.kafka_app_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_kafka_app" {
  count                 = "${var.server_number}"
  launch_configuration  = "${aws_launch_configuration.lc_kafka_app.id}"

  name                  = "${var.product}-${var.env}-${var.type}-${count.index}-${element(split("+",aws_launch_configuration.lc_kafka_app.name), 1)}"
  max_size              = 1
  min_size              = 1
  desired_capacity      = 1
  health_check_grace_period = 30000
  default_cooldown      = 150
  health_check_type     = "ELB"

  vpc_zone_identifier   = "${var.private_subnets}"

  target_group_arns = ["${aws_alb_target_group.kafka_app.arn}"]

  tag {
    key                 = "Name"
    value               = "${var.product}-${var.env}-${var.type}-${var.server_number}_${count.index + 1}"
    propagate_at_launch = true
  }

  tag {
    key                 = "User"
    value               = "${var.user}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Product"
    value               = "${var.product}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Version"
    value               = "${var.version}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Zone"
    value               ="${var.private_zone_id}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_ami" "kafka_app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${var.product}-${var.type}-${var.version}"]
  }
}

data "template_file" "kafka_app_data" {
  template = "${file("user-data.yml")}"

  vars {
    region       = "${var.region}"
    type         = "${var.type}"
  }
}

// Internal load balancer. You can also re-use existing one in your VPC
resource "aws_alb" "kafka_alb" {
  name            = "${var.product}-${var.env}-${var.type}-alb"
  internal        = true
  subnets         = ["${var.private_subnets}"]
  security_groups = ["${aws_security_group.kafka_alb_sg.id}"]
  idle_timeout    = 1800

  tags = {
    Name = "${var.product}-${var.env}-apn-alb"
    User = "${var.user}"
  }
}

resource "aws_alb_listener" "health" {
  load_balancer_arn = "${aws_alb.kafka_alb.id}"
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.kafka_app.arn}"
    type = "forward"
  }
}

resource "aws_security_group" "kafka_alb_sg" {
  name            = "${var.product}-${var.env}-${var.type}-alb-sg"
  description     = "Internal traffic only"
  vpc_id          = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.product}-${var.env}-${var.type}-alb-sg"
    User = "${var.user}"
  }
}

resource "aws_security_group_rule" "app_kafka_zpcli" {
  from_port = 2181
  to_port = 2181
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  type = "ingress"
  source_security_group_id = "${var.app_server_sg}"
}

resource "aws_security_group_rule" "app_kafka_broker" {
  from_port = 9092
  to_port = 9092
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  type = "ingress"
  source_security_group_id = "${var.app_server_sg}"
}

resource "aws_alb_target_group" "kafka_app" {
  name     = "${var.product}-${var.env}-${var.type}-${count.index}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path = "${var.status_endpoint}"
  }

  tags {
    Name = "${var.product}-${var.env}-${var.type}-${count.index}-tg"
    User = "${var.user}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "kakfa_app_sg" {
  name = "${var.product}-${var.env}-${var.type}-sg"
  description = "internal traffic only"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Name = "${var.product}-${var.env}-${var.type}-sg"
    User = "${var.user}"
  }
}

resource "aws_security_group_rule" "jump_kafka" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${var.jump_sg_id}"
}

resource "aws_security_group_rule" "alb_kafka" {
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${aws_security_group.kafka_alb_sg.id}"
}

resource "aws_security_group_rule" "zookeeper_broker_2181" {
  type = "ingress"
  from_port = 2181
  to_port = 2181
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${aws_security_group.kakfa_app_sg.id}"
}

resource "aws_security_group_rule" "client_test_9092" {
  type = "ingress"
  from_port = 9092
  to_port = 9092
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${aws_security_group.kakfa_app_sg.id}"
}

resource "aws_security_group_rule" "kafka_2888" {
  type = "ingress"
  from_port = 2888
  to_port = 2888
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${aws_security_group.kakfa_app_sg.id}"
}

resource "aws_security_group_rule" "kafka_3888" {
  type = "ingress"
  from_port = 3888
  to_port = 3888
  protocol = "tcp"
  security_group_id = "${aws_security_group.kakfa_app_sg.id}"
  source_security_group_id = "${aws_security_group.kakfa_app_sg.id}"
}

resource "aws_iam_role_policy" "ec2_full_role_policy" {
  name = "${element(split("-", var.product),0)}-${var.env}-${var.region}-ec2-rp"
  role = "${var.instance_role_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "autoscaling:*",
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "cloudwatch:PutMetricAlarm",
        "Resource": "*"
    },
    {
        "Action": "ec2:*",
        "Effect": "Allow",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "elasticloadbalancing:*",
        "Resource": "*"
    }
  ]
}
EOF
}

