#!/bin/bash
# Atualizar pacotes
yum update -y

# Instalar Apache
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Instalar PHP
amazon-linux-extras enable php8.0
yum install -y php php-mysqlnd

# Instalar MySQL Client
yum install -y mysql

# Configuração final
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
systemctl restart httpd
