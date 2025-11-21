docker cp consul-acl.json consul-server1-pcmms:/consul/config/consul-acl.json
docker cp consul-acl.json consul-server2-pcmms:/consul/config/consul-acl.json
docker cp consul-acl.json consul-server3-pcmms:/consul/config/consul-acl.json
docker cp consul-acl.json consul-client-pcmms:/consul/config/consul-acl.json
docker restart consul-server1-pcmms
docker restart consul-server2-pcmms
docker restart consul-server3-pcmms
docker restart consul-client-pcmms
###### create secret ######
# docker exec -it consul-server1 /bin/sh
# consul acl bootstrap
# this bellow line will create secret for consul:::::
#   'docker exec -it consul-server1-$IMAGE_NAME  consul acl bootstrap'

# AccessorID:       b978ff1e-165f-ee5e-dc90-89b8a7a9b3f7
# SecretID:         4e164673-08e9-db3c-8e8a-caa602a8eeb6
# Description:      Bootstrap Token (Global Management)
# Local:            false
# Create Time:      2024-05-02 10:25:13.741677746 +0000 UTC
# Policies:
#    00000000-0000-0000-0000-000000000001 - global-management