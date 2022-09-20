#!/bin/sh

# cat > /etc/logrotate.d/mongod <<EOL
# /opt/mis/mongodb/mongod.log {
#   daily
#   size 10M
#   rotate 7
#   missingok
#   compress
#   delaycompress
#   notifempty
#   create 644 mongod mongod
#   sharedscripts
#   postrotate
#     /bin/kill -SIGUSR1 `cat /opt/mis/mongodb/mongod.pid 2>/dev/null` >/dev/null 2>&1
#     sleep 1
#     chown 644 /opt/mis/mongodb/mongod.log
#     rm -rf /opt/mis/mongodb/mongod.log.[0-9][0-9][0-9][0-9]-* >/dev/null 2>&1
#   endscript
# }
# EOL

# tls
sed -i '/net:/a\  tls:' /etc/mongod.conf && \
sed -i '/  tls:/a\    CAFile: \/etc\/wrdcaroot.pem' /etc/mongod.conf && \
sed -i '/    CAFile: \/etc\/wrdcaroot.pem/a\    allowConnectionsWithoutCertificates: true' /etc/mongod.conf && \
sed -i '/    allowConnectionsWithoutCertificates: true/a\    certificateKeyFile: \/etc\/wrdmongodev.pem' /etc/mongod.conf && \
sed -i '/    certificateKeyFile: \/etc\/wrdmongodev.pem/a\    clusterFile: \/etc\/wrdmongodev.pem' /etc/mongod.conf && \
sed -i '/    clusterFile: \/etc\/wrdmongodev.pem/a\    mode: requireTLS' /etc/mongod.conf 

# security
sed -i '/processManagement:/i\security:' /etc/mongod.conf && \
sed -i '/security:/a\  authorization: enabled' /etc/mongod.conf && \
sed -i '/  authorization: enabled/a\  clusterAuthMode: x509' /etc/mongod.conf && \
sed -i '/  clusterAuthMode: x509/a\  ldap:' /etc/mongod.conf && \
sed -i '/  ldap:/a\    servers: "qed-ldap.qualcomm.com"' /etc/mongod.conf && \
sed -i '/    servers: "qed-ldap.qualcomm.com"/a\    transportSecurity: tls' /etc/mongod.conf && \
sed -i $'/    transportSecurity: tls/a\    userToDNMapping: \'[{match : "(.+)",ldapQuery: "ou=people,dc=qualcomm,dc=com??one?(uid={0})"}]\'' /etc/mongod.conf && \
sed -i $'/  ldap:/a\    authz: \'queryTemplate: "ou=groups,dc=qualcomm,dc=com??one?(&(objectClass=groupOfNames)(|(cn=dba.corp.mongodb.admin)(cn=dba.corp.devops))(member={USER}))"\'' /etc/mongod.conf

cp /docker-entrypoint-initdb.d/wrdmongodev.pem /opt/mis/mongodb/wrdmongodev.pem
cp /docker-entrypoint-initdb.d/wrdcaroot.pem /opt/mis/mongodb/wrdcaroot.pem

mongo <<EOF
use admin
db.createRole(
  {
    role: "cn=dba.corp.mysql,ou=groups,dc=qualcomm,dc=com",
    privileges: [],
    roles: [ {role : "root", db : "admin"} ]
  }
)
quit()
EOF