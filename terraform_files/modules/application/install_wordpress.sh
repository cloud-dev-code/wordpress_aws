#!/bin/bash -xe

EFS_MOUNT="${EFS_MOUNT}"

DB_NAME="${DB_NAME}"
DB_HOSTNAME="${DB_HOSTNAME}"
DB_USERNAME="${DB_USERNAME}"
DB_PASSWORD="${DB_PASSWORD}"

WP_ADMIN="wordpress_admin"
WP_PASSWORD="wordpress_admin_pw"

LB_HOSTNAME="${LB_HOSTNAME}"

WP_VERSION="${WORDPRESS_VERSION}"


sudo yum update -y
sudo yum install -y httpd
sudo service httpd start
sudo yum install nfs-utils -y -q

# Mounting EFS
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_MOUNT}:/  /var/www/html

# Making Mount Permanent
echo ${EFS_MOUNT}:/ /var/www/html nfs4 defaults,_netdev 0 0  | sudo cat >> /etc/fstab
sudo chmod go+rw /var/www/html

# Install WordPress
sudo wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

# Deploy WordPress
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo cp -r wordpress/* /var/www/html/
sudo curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x /bin/wp

# Add database info to WordPress config file and install theme
cd /var/www/html
sudo wp core download --version="$WP_VERSION" --locale='en_US' --allow-root

# Loop until config WordPress file is created
while [ ! -f /var/www/html/wp-config.php ]
do
    cd /var/www/html 
    sudo wp core config --dbname="$DB_NAME" --dbuser="$DB_USERNAME" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOSTNAME" --dbprefix=wp_ --allow-root
    sleep 5
done

sudo wp core install --url="http://$LB_HOSTNAME" --title='WordPress deployment on AWS' --admin_user="$WP_ADMIN" --admin_password="$WP_PASSWORD" --admin_email='admin@mydomain.com' --allow-root


# Restart httpd
sudo chkconfig httpd on
sudo service httpd start
sudo service httpd restart

# Restart httpd after a while
setsid nohup "sleep 500; sudo service httpd restart" &
