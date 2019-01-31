sudo docker run -p 80:80 --name nginx -v /docker/www:/usr/share/nginx/html -v /docker/nginx/conf.d:/etc/nginx/conf.d --privileged=true -d nginx
