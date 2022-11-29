# Grab my source ip
data "http" "myip" {
  url = "http://ifconfig.me"
}

# Referencing the two Ubuntu AMIs for us-east-1
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# Referencing the Ubuntu AMIs for us-east-2
data "aws_ami" "ubuntu2" {
  most_recent = true
  provider    = aws.region-2
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# Security Groups for proxy, web, db and centralized ingress LB
module "security_group_proxy_vm" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "security_group_proxy_vm"
  description         = "Security group for proxy vm"
  vpc_id              = module.spoke_aws_us_east_1_proxy.vpc.vpc_id
  ingress_cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "All"
      description = "ethr tool"
      cidr_blocks = "10.0.0.0/8"
  }]
  egress_rules = ["all-all"]
}

module "security_group_web_vm" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "security_group_web_vm"
  description         = "Security group for web vm"
  vpc_id              = module.spoke_aws_us_east_1_web.vpc.vpc_id
  ingress_cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "All"
      description = "ethr tool"
      cidr_blocks = "10.0.0.0/8"
  }]
  egress_rules = ["all-all"]
}

module "security_group_database_vm" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "security_group_database_vm"
  description         = "Security group for database vm"
  vpc_id              = module.spoke_aws-us-east-2-database.vpc.vpc_id
  ingress_cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "all-icmp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "All"
      description = "ethr tool"
      cidr_blocks = "10.0.0.0/8"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "All"
      description = "enclave"
      cidr_blocks = "100.64.0.0/10"
    }
  ]
  egress_rules = ["all-all"]
  providers = {
    aws = aws.region-2
  }
}

module "security_group_centralized_lb" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "security_group_centralized_lb"
  description         = "Security group for centralized_lb"
  vpc_id              = module.spoke_aws_us_east_1_centralized_ingress.vpc.vpc_id
  ingress_cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
}

# Proxy LB Creation
resource "aws_lb" "proxy_lb" {
  name                             = "proxy-lb"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  subnet_mapping {
    subnet_id            = module.spoke_aws_us_east_1_proxy.vpc.public_subnets[1].subnet_id
    private_ipv4_address = var.proxy_lb_ip1
  }

  subnet_mapping {
    subnet_id            = module.spoke_aws_us_east_1_proxy.vpc.public_subnets[2].subnet_id
    private_ipv4_address = var.proxy_lb_ip2
  }
}

# Proxy LB Target Group 
resource "aws_lb_target_group" "proxy_lb_target_group" {
  name     = "proxy-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.spoke_aws_us_east_1_proxy.vpc.vpc_id
}

# Proxy LB Target Group Attachment
resource "aws_lb_target_group_attachment" "proxy_lb_target_group_att" {
  target_group_arn = aws_lb_target_group.proxy_lb_target_group.arn
  target_id        = aws_instance.aws_us_east_1_proxy_vm.id
  port             = 80
}

# Centralized LB creation
resource "aws_lb" "centralized_ingress_lb" {
  name                       = "centralized-ingress-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [module.security_group_centralized_lb.this_security_group_id]
  subnets                    = [for subnet in module.spoke_aws_us_east_1_centralized_ingress.vpc.public_subnets : subnet.subnet_id]
  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Centralized LB target group
resource "aws_lb_target_group" "centralized_ingress_lb_target_group" {
  name        = "centralized-ingress-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.spoke_aws_us_east_1_centralized_ingress.vpc.vpc_id
}

# Centralized LB target group attachment pointing to Proxy LB
resource "aws_lb_target_group_attachment" "centralized_ingress_lb_target_group_att" {
  target_group_arn  = aws_lb_target_group.centralized_ingress_lb_target_group.arn
  availability_zone = "all"
  target_id         = var.proxy_lb_ip1
  port              = 80
}

resource "aws_lb_target_group_attachment" "centralized_ingress_lb_target_group_att2" {
  target_group_arn  = aws_lb_target_group.centralized_ingress_lb_target_group.arn
  availability_zone = "all"
  target_id         = var.proxy_lb_ip2
  port              = 80
}

# Central LB Listener
resource "aws_lb_listener" "central_ingress" {
  load_balancer_arn = aws_lb.centralized_ingress_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.centralized_ingress_lb_target_group.arn
  }
}

# Proxy LB Listener
resource "aws_lb_listener" "proxy_lb" {
  load_balancer_arn = aws_lb.proxy_lb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_lb_target_group.arn
  }
}

# Proxy VM 
resource "aws_instance" "aws_us_east_1_proxy_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.spoke_aws_us_east_1_proxy.vpc.private_subnets[1].subnet_id
  vpc_security_group_ids = [module.security_group_proxy_vm.this_security_group_id]
  user_data              = templatefile("${path.module}/aws_vm_config/nginx_proxy.tpl", { web_ip = aws_instance.aws_us_east_1_web_vm.private_ip, password = var.ubuntu_vms_password })
  tags = {
    Name = "aws-us-east-1-proxy-vm"
  }
  depends_on = [
    data.aviatrix_firenet_vendor_integration.fw1,
    data.aviatrix_firenet_vendor_integration.fw2
  ]
}

# Web VM
resource "aws_instance" "aws_us_east_1_web_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.spoke_aws_us_east_1_web.vpc.private_subnets[1].subnet_id
  vpc_security_group_ids = [module.security_group_web_vm.this_security_group_id]
  user_data              = templatefile("${path.module}/aws_vm_config/webserver.tpl", { db_ip = aws_instance.aws_us_east_2_database_vm.private_ip, password = var.ubuntu_vms_password, lb_dns = aws_lb.centralized_ingress_lb.dns_name })
  tags = {
    Name = "aws-us-east-1-web-vm"
  }
  depends_on = [
    data.aviatrix_firenet_vendor_integration.fw1,
    data.aviatrix_firenet_vendor_integration.fw2
  ]
}

# Database VM
resource "aws_instance" "aws_us_east_2_database_vm" {
  ami                    = data.aws_ami.ubuntu2.id
  instance_type          = "t3.micro"
  subnet_id              = module.spoke_aws-us-east-2-database.vpc.private_subnets[1].subnet_id
  vpc_security_group_ids = [module.security_group_database_vm.this_security_group_id]
  user_data              = templatefile("${path.module}/aws_vm_config/database.tpl", { password = var.ubuntu_vms_password })
  tags = {
    Name = "aws-us-east-2-database-vm"
  }
  depends_on = [
    data.aviatrix_firenet_vendor_integration.fw1,
    data.aviatrix_firenet_vendor_integration.fw2
  ]
  provider = aws.region-2
}
