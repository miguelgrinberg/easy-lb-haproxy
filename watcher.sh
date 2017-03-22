#!/bin/sh

# make sure the /services key is set in etcd before we start
for ETCD_URL in ${ETCD_PEERS//,/ }; do
    curl -s -f $ETCD_URL/v2/keys/services -XPUT -d dir=true
    if [ "$?" = "0" ]; then
        break
    fi
done

# attempt to generate a first configuration
ETCD_NODES="-node ${ETCD_PEERS//,/ -node }"
while [ true ]; do
    ./confd -onetime $ETCD_NODES -config-file /etc/confd/conf.d/haproxy.toml
    if [ "$?" != "0" ]; then
        echo confd cannot generate initial configuration, retrying in 10 sec...
        sleep 10
    else
        break
    fi
done

# start the watch cycle
while [ true ]; do
    ./confd -interval 10 $ETCD_NODES -config-file /etc/confd/conf.d/haproxy.toml
    echo confd exited, restarting.
done
