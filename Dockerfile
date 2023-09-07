FROM ubuntu:latest
RUN apt update
RUN apt install -y nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
