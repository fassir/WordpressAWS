#!/bin/bash
USER=$(whoami)
PROJECT_DIR=/home/$USER/wordpress
EFS_MOUNT_POINT=/mnt/efs 
sudo apt-get update
sudo apt-get install -y cloud-utils apt-transport-https ca-certificates curl software-properties-common
sudo apt-get install -y docker.io
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker $USER
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR
sudo mkdir -p $EFS_MOUNT_POINT
sudo tee /etc/fstab << GTV 
fs-06bec12425379e56a.efs.sa-east-1.amazonaws.com:/ efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0 
GTV

cd $PROJECT_DIR
sudo tee /home/$USER/docker-compose.yml <<EOL
services:
  wordpress:
    image: wordpress:latest
    container_name: web
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: db.cpsgwa8q2045.sa-east-1.rds.amazonaws.com
      WORDPRESS_DB_USER: admWordpress 
      WORDPRESS_DB_PASSWORD: senha!12
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - $EFS_MOUNT_POINT:/var/www/html 
EOL
sudo chown $USER:$USER /home/$USER/docker-compose.yml
cd /home/$USER
sudo chown -R $USER:$USER $PROJECT_DIR
sudo docker-compose up -d
sleep 3
sudo docker exec -i web bash -c "cat <<EOF > /var/www/html/healthcheck.php
<?php
http_response_code(200);
header('Content-Type: application/json');
echo json_encode([ status=> OK, message => Health check passed\"]);
exit;
?>
EOF"
if  sudo docker exec -i web ls /var/www/html/healthcheck.php > /dev/null 2>&1; then
  echo "Arquivo healthcheck.php criado com sucesso!"
else
  echo "ainda nada"
fi
  shutdown now
fi