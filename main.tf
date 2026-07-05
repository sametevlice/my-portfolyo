provider "aws" {
  region = "eu-central-1"
}

# En güncel Ubuntu sürümünü otomatik bulur
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Daha önce ürettiğin güvenli açık anahtarı (Public Key) tanımlar
resource "aws_key_pair" "deployer" {
  key_name   = "portfolio-deploy-key"
  public_key = file("~/.ssh/portfolio_key.pub")
}

# Güvenlik duvarı (Web ve SSH girişine izin verir)
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio_web_sg"
  description = "Web ve SSH erisimi"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# EC2 Sunucu Siparişi (t3.micro)
resource "aws_instance" "portfolio_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.portfolio_sg.id]

  # Sunucu açılır açılmaz Docker'ı kurar
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Portfolio-Web-Server"
  }
}

# İşlem bitince sunucunun IP adresini ekrana yazdırır
output "sunucu_ip_adresi" {
  value = aws_instance.portfolio_server.public_ip
}