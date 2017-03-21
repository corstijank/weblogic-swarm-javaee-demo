#!/bin/bash
docker-machine create --driver virtualbox --virtualbox-memory "1024" swmaster
docker-machine create --driver virtualbox --virtualbox-memory "2048" swnode1
docker-machine create --driver virtualbox --virtualbox-memory "2048" swnode2
docker-machine create --driver virtualbox --virtualbox-memory "1024" lb

eval $(docker-machine env swmaster)
docker swarm init --advertise-addr $(docker-machine ip swmaster) --listen-addr $(docker-machine ip swmaster):2377
TOKEN=$(docker swarm join-token -q worker)

docker $(docker-machine config swnode1) swarm join $(docker-machine ip swmaster):2377 --listen-addr $(docker-machine ip swnode1):2377 --token $TOKEN
docker $(docker-machine config swnode2) swarm join $(docker-machine ip swmaster):2377 --listen-addr $(docker-machine ip swnode2):2377 --token $TOKEN
docker $(docker-machine config lb) swarm join $(docker-machine ip swmaster):2377 --listen-addr $(docker-machine ip lb):2377 --token $TOKEN

# inject DNS entry for registry;
docker-machine ssh swmaster 'echo "192.168.99.100 my-wl-registry" | sudo tee -a /etc/hosts'
docker-machine ssh swnode1 'echo "192.168.99.100 my-wl-registry" | sudo tee -a /etc/hosts'
docker-machine ssh swnode2 'echo "192.168.99.100 my-wl-registry" | sudo tee -a /etc/hosts'
docker-machine ssh lb 'echo "192.168.99.100 my-wl-registry" | sudo tee -a /etc/hosts'

# Hack insecure registry on swmaster
docker-machine ssh swmaster 'echo "{\"insecure-registries\": [\"my-wl-registry:5000\"]}" | sudo tee /etc/docker/daemon.json'
docker-machine ssh swmaster 'sudo /etc/init.d/docker restart'
docker-machine ssh swnode1 'echo "{\"insecure-registries\": [\"my-wl-registry:5000\"]}" | sudo tee /etc/docker/daemon.json'
docker-machine ssh swnode1 'sudo /etc/init.d/docker restart'
docker-machine ssh swnode2 'echo "{\"insecure-registries\": [\"my-wl-registry:5000\"]}" | sudo tee /etc/docker/daemon.json'
docker-machine ssh swnode2 'sudo /etc/init.d/docker restart'
docker-machine ssh lb 'echo "{\"insecure-registries\": [\"my-wl-registry:5000\"]}" | sudo tee /etc/docker/daemon.json'
docker-machine ssh lb 'sudo /etc/init.d/docker restart'

# Start registry 
eval $(docker-machine env swmaster)
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Create server jre image
cd oracle-java-8
docker build -t my-wl-registry:5000/oracle/serverjre:8 .
docker push my-wl-registry:5000/oracle/serverjre:8
cd ..
cd oracle-weblogic 
docker build -t my-wl-registry:5000/oracle/weblogic:12.2 .
docker push my-wl-registry:5000/oracle/weblogic:12.2
cd ..

# Build java-ee demo
cd javaee-demo 
mvn clean package
docker build -t my-wl-registry:5000/javaee-demo:1.0 .

# Run as simple container
docker run -p 7001:7001 my-wl-registry:5000/javaee-demo:1.0
