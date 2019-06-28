# DBInstaller_VoltDB
one-stop installation for VoltDB Cluster， the instllation script for VoltDB 7.0+
The installation tool support multiple deployment model of single VoltDB cluster, passive database replication and cross datacenter replication.



### Foder
* bin: Installation DB of shell sctipt.(The shell script will be depreciate)
* common: Utility method for DB instllation.
* dbscript: DB DDL, DML SQL for tables .
* config:  Define the VoltDB cluster topology.(Detail explain later).
* template：Voltdb deployment templates based on the different deployment model.
* voltdb: Voltdb indtalltion script(python)

#### Voltdb deployment topology
<pre>
Deployment:
  DATABASE_TYPE: voltdb
  DATABASE_NAME: sample_db
  VOLTDB_INSTANCE_NAME: sample_db
  VOLTDB_JAVA_HOME: /usr/java/jdk1.8.0_152
  VOLTDB_DR_ID: 1
  VOLTDB_DR_SOURCE: 15.114.119.11:11219
  ONLY_DEPLOYMENT_OPERATION: True
  VOLTDB_ADMIN_USERNAME: vdbadmin
  VOLTDB_ADMIN_PASSWORD: vdbadmin
  VOLTDB_USER_NAME: volt_user
  VOLTDB_USER_PASSWORD: volt_user
  VOLTDB_SITES_PER_HOST: 10
  VOLTDB_EXPORT_ROLL_PERIOD: 60
  VOLTDB_NODE_LIST:
    - external_interface: 15.116.78.152
      internal_interface: 15.116.78.152
      httpd_interface: 15.116.78.152
      replication_interface: 15.116.78.152
      admin_interface: 15.116.78.152
    - ......
  VOLTDB_ROOT_PATH: /var/opt/sample_db
  VOLTDB_CLIENT_PORT: 11212
  VOLTDB_ADMIN_PORT: 11213
  VOLTDB_HTTP_PORT: 11214
  VOLTDB_INTERNAL_PORT: 11215
  VOLTDB_ZOOKEEPER_PORT: 11216
  VOLTDB_REPLICATION_PORT: 11217
  VOLTDB_WORK_MODEL: 1
  VOLTDB_HEAPMAX: 2048
  VOLTDB_PLACEMENT_GROUPS:
    - external_interface: 15.116.78.152
      placement_group: row6.rack5.server3
    - ......
</pre>
