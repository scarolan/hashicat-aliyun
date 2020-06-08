# hashicat-aliyun

# Create a new ECS instance for VPC
resource "alicloud_vpc" "hashicat-vpc" {
  name       = "${var.prefix}-vpc"
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "hashicat-vswitch" {
  name              = "${var.prefix}-vswitch"
  vpc_id            = alicloud_vpc.hashicat-vpc.id
  cidr_block        = "172.16.0.0/21"
  availability_zone = "cn-hangzhou-b"
}

resource "alicloud_security_group" "hashicat-sg" {
  name        = "${var.prefix}-sg"
  description = "Security group for HashiCat application"
  vpc_id      = alicloud_vpc.hashicat-vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.hashicat-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_instance" "hashicat-instance" {
  description                = "${var.prefix} HashiCat Application"
  availability_zone          = "cn-hangzhou-b"
  security_groups            = alicloud_security_group.hashicat-sg.*.id
  instance_type              = "ecs.n1.tiny"
  system_disk_category       = "cloud_efficiency"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "hashicat-${var.prefix}"
  vswitch_id                 = alicloud_vswitch.hashicat-vswitch.id
  internet_max_bandwidth_out = 10
  user_data                  = <<-EOF
    # Create the website home
    # 创建网站主页
    cat << EOM > /var/www/html/index.html
    <html>
    <head><title>喵!</title></head>
    <body>
    <div style="width:800px;margin: 0 auto">
    <!-- BEGIN -->
    <center><img src="http://$${PLACEHOLDER}/$${WIDTH}/$${HEIGHT}"></img></center>
    <center><h2>喵世界!</h2></center>
    您好，欢迎来到 $${PREFIX}
    <!-- END -->
    </div>
    </body>
    </html>
    EOM
    
    # Install software
    # 安装软件
    sudo add-apt-repository universe
    sudo apt -y update
    sudo apt -y install apache2
    sudo systemctl start apache2
    sudo chown -R ubuntu:ubuntu /var/www/html
    chmod +x *.sh

    # Deploy application
    # 部署应用
    PLACEHOLDER=${var.placeholder} WIDTH=${var.width} HEIGHT=${var.height} PREFIX=${var.prefix} ./deploy_app.sh
  EOF
}
