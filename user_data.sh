#!/bin/bash 

# caso usuario principal nao seja ubuntu e ainda seja uma distribuicao do ubuntu, garante que permaneca o usuario 

USER=$(whoami) 
PROJECT_DIR=/home/$USER/wordpress 

EFS_MOUNT_POINT=/mnt/efs/wordpress  

case "$USER" in
  ec2-user)
  sudo yum update 
  sudo yum install docker nfs-utils amazon-efs-utils -y
  curl -SL "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-linux-x86_64" -o /usr/libexec/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose;;
  ubuntu)
  sudo apt-get update 
  sudo apt-get install docker nfs-utils amazon-efs-utils -y
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
  sudo chmod +x /usr/local/bin/docker-compose;;
  *) shutdown now;;
esac

sudo systemctl start docker 
sudo systemctl enable docker 

sudo mkdir -p $PROJECT_DIR 
sudo mkdir -p $EFS_MOUNT_POINT 
sudo usermod -aG docker $USER

sudo chown -R $USER:$USER $PROJECT_DIR 
 

sudo tee -a /etc/fstab << GTV  
<efs>:/ efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0  
GTV 
sudo mount -a

while ! mountpoint -q /mnt/efs; do
  sleep 2
done

sudo tee /home/"$USER"/docker-compose.yml <<EOL
services:
  wordpress:
    image: wordpress:6-php8.2
    container_name: web
    ports:
      - "80:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: <rds>
      WORDPRESS_DB_USER: <usuario_db>
      WORDPRESS_DB_PASSWORD: <senha>
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - "$EFS_MOUNT_POINT:/var/www/html"
EOL

sudo chown $USER:$USER /home/$USER/docker-compose.yml 
cd /home/$USER 

while ! sudo -u $USER docker info &>/dev/null; do sleep 5; done 

sudo -u $USER docker-compose up -d
 
sudo -u "$USER" docker exec -i web bash -c 'cat <<EOF > /var/www/html/healthcheck.php
<?php
http_response_code(200);
header("Content-Type: application/json");
echo json_encode(["status" => "OK", "message" => "Health check passed"]);
exit;
?>
EOF' 
if  sudo -u $USER docker exec -i web ls /var/www/html/healthcheck.php > /dev/null 2>&1; then 
  echo "Arquivo healthcheck.php criado com sucesso!" 
fi
