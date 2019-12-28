# haproxy2.1.0-lua-mongodriver
Haproxy2.1.0 with lua  and mongodriver,
The image is build with Haproxy2.1.0 and lua 5.3.4 and mongo-driver, it's purpose is visit mongodb replicaset from external network which can not connect to all instances of relicaset. 

## Usage
Path cfg is the demo of haproxy.cfg and lua file which connect to the mongodb replicaset.
You can use the docker command like follow:

docker run -d -p 37017:37017 -v /cfg:/etc/haproxy/conf pengtaoman/ubuntu-haproxy-mongo:0.0.1

and connect mongodb replicaset with:

docker run -it --rm mongo:4.0.14 mongo --host 172.17.0.2 --port 37017

You can view haproxy logs with:

docker logs containerId
