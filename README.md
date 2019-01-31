1、首先安装docker

下载docker的阿里镜像源：

wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

安装docker所需的依赖包:

yum -y install yum-utils device-mapper-persistent-data lvm2 container-selinux

添加docker的阿里源

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

安装docker

yum -y install docker-ce

启动docker

systemctl restart docker

2、安装docker阿里云加速器

登录自己的阿里云账号进入一下页面即可复制专属加速器地址

https://cr.console.aliyun.com/#/accelerator

配置加速器

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://756fdy0k.mirror.aliyuncs.com"]    #此为加速器地址,每个人不同 
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

3、拉取所需镜像

docker pull nginx:latest

docker pull mysql:8

docker pull bitnami/php-fpm

微信截图_20181017202056.png

4、创建文件夹

mkdir -pv /docker/www    #网站根目录

mkdir -pv /docker/nginx/conf.d/       #nginx配置文件

mkdir -pv /docker/mysql     #数据库文件夹

5、构建mysql容器

docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -v /docker/mysql:/var/lib/mysql --name mysql8 mysql:8

连入容器中

docker exec -it mysql8 bash

2.png

登录数据库重置密码:

mysql -uroot -p123456

use mysql

ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';

alter  user 'root'@'%' identified by '123456';

FLUSH PRIVILEGES;

3.png

在宿主机上测试是否能够连入数据库

查看数据库容器IP地址:

docker inspect mysql8 --format='{{.NetworkSettings.IPAddress}}'

4.png

mysql -h 172.17.0.2 -uroot -p123456

5.png

数据库配置完成

6、构建nginx容器

docker run -p 80:80 --name mynginx \

 -v /docker/www:/usr/share/nginx/html \

 -v /docker/nginx/conf.d:/etc/nginx/conf.d \

 --privileged=true \

 -d nginx

6.png

7、构建php容器

docker run -p 9000:9000 --name myphp -v /docker/www:/var/www/html\

-d bitnami/php-fpm:latest

8、配置nginx代理

首先查看php容器的IP地址

docker inspect myphp --format='{{.NetworkSettings.IPAddress}}'

7.png

配置nginx代理

vim /docker/nginx/conf.d/default.conf

server {

  listen  80 default_server;

  server_name _;

  root   /usr/share/nginx/html;

  location / {

   index index.html index.htm index.php;

   autoindex off;

  }

  location ~ \.php(.*)$ {

   root   /var/www/html/;

   fastcgi_pass 172.17.0.4:9000;   #php容器的IP地址

   fastcgi_index index.php;

   fastcgi_split_path_info ^((?U).+\.php)(/?.+)$;

   fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

   fastcgi_param PATH_INFO $fastcgi_path_info;

   fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;

   include  fastcgi_params;

  }

}

9、配置phpinfo页面

echo "<?php phpinfo();" > /docker/www/info.php

访问nginx页面看看

curl localhost/info.php

8.png

10、配置php连接数据库

vim /docker/www/test.php

 <?php

 $dbms='mysql';     //数据库类型

 $host='mysql8'; //数据库主机名,此处写mysql 容器的名字

 $dbport = '3306';

 $dbName='mysql';    //使用的数据库

 $user='root';      //数据库连接用户名

 $pass='123456';          //对应的密码

 $dsn="$dbms:host=$host;port=$dbport;dbname=$dbName";

 try {

    $dbh = new PDO($dsn, $user, $pass); //初始化一个PDO对象

    echo "successful!<br/>";

   //你还可以进行一次搜索操作

    // foreach ($dbh->query('SELECT * from user') as $row) {

    //     print_r($row); //你可以用 echo($GLOBAL); 来看到这些值

    // }

    

    $dbh = null;

 } catch (PDOException $e) {

    die ("Error!: " . $e->getMessage() . "<br/>");

 }

11、测试是否连接数据库成功

curl localhost/test.php
