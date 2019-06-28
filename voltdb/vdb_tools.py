#!/bin/python

from common.functions import LogOps
from common.functions import Properties
from common.functions import YAMLOps
from common.functions import UtilOps
from common.functions import SSHUtil
from voltdbclient import *
import logging
import time
import os
import commands

eium_home = "/opt/SIU_snap"
voltdb_instance_name = "spr_db"

logger_ = LogOps("DB_Shell.log", logging.INFO, console_enable=False)


def vdb_tool_output(message, level=logging.INFO):
    if level == logging.DEBUG:
        logger_.debug(message)
    elif level == logging.INFO:
        logger_.info(message)
    elif level == logging.WARN:
        logger_.warn(message)
    elif level == logging.ERROR:
        logger_.error(message)
    UtilOps.output(message)


def get_voltdb_version():
    version_file = os.path.join(vdb_home, "version.txt")
    with open(version_file, 'r') as f:
        version_ = f.read()
    return version_


def get_placement_group(external_host):
    placement_group_name = " "
    for placement_group in voltdb_placement_groups:
        if placement_group["external_interface"] == external_host:
            placement_group_name = " --placement-group=" + placement_group["placement_group"]
            break
    return placement_group_name


def get_start_hosts(node_list, internal_port):
    nodes_str = ""
    for node in node_list:
        external_host = node["external_interface"]
        nodes_str += external_host + ":" + str(internal_port) + ","
    if len(nodes_str) > 0:
        nodes_str = nodes_str[:-1]
    return nodes_str


def get_admin_interface(vdb_host):
    vdb_admin_interface = vdb_host
    for cluster_node in cluster_node_list:
        if vdb_host == cluster_node["external_interface"]:
            vdb_admin_interface = cluster_node["admin_interface"]
            break
    return vdb_admin_interface


def check_db_start_status(vdb_host):
    wait_count = 1
    while wait_count < 61:
        vdb_tool_output("checking the " + voltdb_instance_name + " start status ......", level=logging.INFO)
        status_command = vdb_home + "/bin/sqlcmd --servers=" + vdb_host + " --port=" + str(
            vdb_client_port) + " --user=" + vdb_admin_user + " --password=" + vdb_admin_pwd + " --query=\"exec @SystemInformation overview\""
        logger_.debug("status query command is:" + status_command)
        return_code, output = commands.getstatusoutput(status_command)
        if return_code == 0:
            vdb_tool_output("the " + voltdb_instance_name + " database start successfully.", level=logging.INFO)
            return 0
        wait_count += 1
        time.sleep(10)
    return 1


def get_alive_servers(vdb_host):
    client = FastSerializer(vdb_host, vdb_admin_port, vdb_admin_user, vdb_admin_pwd)
    proc = VoltProcedure(client, "@SystemInformation", [FastSerializer.VOLTTYPE_STRING])
    response = proc.call(["overview"])
    client.close()
    rows = response.tables[0].tuples
    alive_hostnames = []
    for item in rows:
        if item[1] == "HOSTNAME":
            alive_hostnames.append(item[2])
    print("alive hosts:{0}".format(alive_hostnames))
    return alive_hostnames


def generate_database_ini():
    client = FastSerializer(vdb_host_node, vdb_admin_port, vdb_admin_user, vdb_admin_pwd)
    proc = VoltProcedure(client, "@SystemInformation", [FastSerializer.VOLTTYPE_STRING])
    response = proc.call(["overview"])
    client.close()
    rows = response.tables[0].tuples
    logger_.debug("call @SystemInformation: " + rows)
    node_list = []
    placement_groups = []
    id_flag = rows[0][0]
    node_list_interfaces = {}
    node_placement_group = {}
    for item in rows:
        id = item[0]
        if id != id_flag:
            id_flag = id
            node_list.append(node_list_interfaces.copy())
            placement_groups.append(node_placement_group.copy())
            node_list_interfaces = {}
            node_placement_group = {}
        print("++++" + item[1].encode("utf-8"))
        if item[1].encode("utf-8") == "ADMININTERFACE":
            node_list_interfaces["admin_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "IPADDRESS":
            node_list_interfaces["external_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "PUBLICINTERFACE":
            node_list_interfaces["httpd_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "INTERNALINTERFACE":
            node_list_interfaces["internal_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "DRINTERFACE":
            node_list_interfaces["replication_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "IPADDRESS":
            node_placement_group["external_interface"] = item[2].encode("utf-8")
        if item[1].encode("utf-8") == "PLACEMENTGROUP":
            node_placement_group["placement_group"] = item[2].encode("utf-8")

    if node_list_interfaces:
        node_list.append(node_list_interfaces.copy())

    if node_placement_group:
        placement_groups.append(node_placement_group.copy())

    db_ini_obj = {"Deployment": {"VOLTDB_INSTANCE_NAME": voltdb_instance_name,
                                 "DATABASE_NAME": database_name,
                                 "VOLTDB_NODE_LIST": node_list,
                                 "VOLTDB_ROOT_PATH": vdb_root_path,
                                 "VOLTDB_CLIENT_PORT": vdb_client_port,
                                 "VOLTDB_ADMIN_PORT": vdb_admin_port,
                                 "VOLTDB_HTTP_PORT": vdb_http_port,
                                 "VOLTDB_INTERNAL_PORT": vdb_internal_port,
                                 "VOLTDB_ZOOKEEPER_PORT": vdb_zookeeper_port,
                                 "VOLTDB_REPLICATION_PORT": vdb_replication_port,
                                 "VOLTDB_USER_NAME": vdb_user,
                                 "VOLTDB_USER_PASSWORD": vbd_pwd_encrypted,
                                 "VOLTDB_ADMIN_USERNAME": vdb_admin_user,
                                 "VOLTDB_ADMIN_PASSWORD": vdb_admin_pwd_encrypted,
                                 "VOLTDB_START_PORT": vdb_start_port,
                                 "VOLTDB_WORK_MODEL": vdb_work_model,
                                 "VDB_SSH_USER": vdb_ssh_user,
                                 "VOLTDB_PLACEMENT_GROUPS": placement_groups}}
    logger_.debug("database.ini object is:{0} ".format(db_ini_obj))
    return db_ini_obj


def db_cleanup():
    pass


def db_status():
    status_command = vdb_home + "/bin/sqlcmd --servers=" + vdb_host_node + " --port=" + str(
        vdb_client_port) + " --user=" + vdb_admin_user + " --password=" + vdb_admin_pwd + " --query=\"exec @SystemInformation overview\""
    logger_.debug("status query command is:" + status_command)
    return_code, output = commands.getstatusoutput(status_command)
    if return_code == 0:
        UtilOps.output("The " + voltdb_instance_name + " status is running.")
        UtilOps.output(output)
    else:
        UtilOps.output("The " + voltdb_instance_name + " status is stopped.")


def db_start():
    voltdb_tmd = os.path.join(snaptmd, "vdb_tool" + str(process_num))
    UtilOps.snap_check_dir(voltdb_tmd)
    tmp_log4j = dbi_conf + "/voltdb_log4j.xml"
    UtilOps.render_file(tmp_log4j, voltdb_tmd + "/voltdb_log4j.xml",
                        {'PLACEHOLDER_VAR_EIUM_HOME': var_eium, 'PLACEHOLDER_DB_NAME': voltdb_instance_name})
    deployment_file = os.path.join(vdb_store_path, "config", "deployment.xml")
    if not os.path.isfile(deployment_file):
        vdb_tool_output(
            "The " + deployment_file + " does not exist, need to init the DB, please reinstall the " + voltdb_instance_name)
        os._exit(1)
    voltdb_start_folder = voltdb_tmd + "_start"
    start_db_file = os.path.join(voltdb_tmd, "voltdb_start_{0}.sh".format(process_num))
    for node in node_list:
        external_host = node["external_interface"]
        internal_host = node["internal_interface"]
        public_host = node["httpd_interface"]
        admin_interface = node["admin_interface"] + ":" + str(vdb_admin_port)
        httpd_interface = public_host + ":" + str(vdb_http_port)
        repl_port_interface = node["replication_interface"] + ":" + str(vdb_replication_port)
        client_port_interface = external_host + ":" + str(vdb_client_port)
        internal_interface = internal_host + ":" + str(vdb_internal_port)
        placement_group_name = get_placement_group(external_host)

        UtilOps.write_file(start_db_file, "export JAVA_HOME=" + vdb_java_home + "\n")
        UtilOps.write_file(start_db_file, "export PATH=$JAVA_HOME/bin:$PATH" + "\n")
        # UtilOps.write_file(start_db_file, "mkdir -p " + var_eium + "/csv" + "\n")
        UtilOps.write_file(start_db_file,
                           "export LOG4J_CONFIG_PATH=" + voltdb_start_folder + "/voltdb_log4j.xml" + "\n")
        # UtilOps.write_file(start_db_file, "export VOLTDB_HEAPMAX={0}".format(voltdb_heapmax) + "\n")
        UtilOps.write_file(start_db_file,
                           "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true -DDISABLE_JMX=true\"" + "\n")
        start_hosts = get_start_hosts(node_list, vdb_internal_port)
        start_command = vdb_home + "/bin/voltdb start --dir=" + vdb_root_path + " --host=" + start_hosts + \
                        " --externalinterface=" + external_host + " --internalinterface=" + internal_host + \
                        " --publicinterface=" + public_host + " --admin=" + admin_interface + \
                        " --client=" + client_port_interface + " --http=" + httpd_interface + \
                        " --internal=" + internal_interface + " --replication=" + repl_port_interface + \
                        " --zookeeper=" + str(vdb_zookeeper_port) + placement_group_name + " --background \n"
        UtilOps.write_file(start_db_file, start_command)

        SSHUtil(external_host, vdb_ssh_user).exec_cmd("mkdir -p " + voltdb_start_folder)
        SSHUtil(external_host, vdb_ssh_user).scp_file_to(os.path.join(voltdb_start_folder, "voltdb_log4j.xml"),
                                                         os.path.join(voltdb_tmd, "voltdb_log4j.xml"))
        SSHUtil(external_host, vdb_ssh_user).scp_file_to(
            voltdb_start_folder + "/voltdb_start_{0}.sh".format(process_num), start_db_file)

        SSHUtil(external_host, vdb_ssh_user).exec_cmd(
            "chmod +x " + voltdb_start_folder + "/*.sh".format(process_num))
        ret_code, result = SSHUtil(external_host, vdb_ssh_user).exec_cmd(
            "sh " + voltdb_start_folder + "/voltdb_start_{0}.sh".format(process_num))
        if ret_code == 0:
            vdb_tool_output("start the " + voltdb_instance_name + " db in " + external_host + " host.",
                            level=logging.INFO)
        else:
            vdb_tool_output("failed to start the " + voltdb_instance_name + " db.", level=logging.ERROR)
            vdb_tool_output("output message is: " + result, level=logging.ERROR)
            os._exit(1)
    if check_db_start_status(vdb_host_node) == 0:
        vdb_tool_output("The " + voltdb_instance_name + " start successfully.")
    else:
        vdb_tool_output("Faile to start " + voltdb_instance_name + " db.")
        os._exit(1)


def db_stop():
    vdb_admin_interface = get_admin_interface(vdb_host_node)
    try:
        client = FastSerializer(vdb_admin_interface, vdb_admin_port, vdb_admin_user, vdb_admin_pwd)
        UtilOps.output("Pause the " + voltdb_instance_name + "...")
        proc = VoltProcedure(client, "@Pause")
        response = proc.call([])
        result = response.tables[0]
        status = result.tuples[0][0]
        # print("=====status"+str(status))
        if status == 0:
            UtilOps.output("Pause the " + voltdb_instance_name + " successfully.")
        else:
            UtilOps.output("Failed to pause " + voltdb_instance_name + ".")
            os._exit(1)

        snapshot_path = os.path.join(vdb_store_path, "snapshots")
        UtilOps.output("Save snapshot of the " + voltdb_instance_name + " to disk " + snapshot_path + "...")
        proc = VoltProcedure(client, "@SnapshotSave", [FastSerializer.VOLTTYPE_STRING, FastSerializer.VOLTTYPE_STRING,
                                                       FastSerializer.VOLTTYPE_INTEGER])
        response = proc.call([snapshot_path, database_name + date_, 1])
        if response.status == 1:
            UtilOps.output(
                "Save snapshot of the " + voltdb_instance_name + " to disk " + snapshot_path + " successfully.")
        else:
            UtilOps.output("Failed to save " + voltdb_instance_name + " snapshot.")
            os._exit(1)

        # UtilOps.output("----response----{0}".format(response))
        UtilOps.output("Stop the " + voltdb_instance_name + "... ")
        proc = VoltProcedure(client, "@Shutdown")
        response = proc.call([])
        # result = response.tables[0]
        # status = response.status
        if response.statusString == "Connection broken":
            UtilOps.output("Stop the " + voltdb_instance_name + " successfully.")
        else:
            UtilOps.output("Stop DB response:" + response.statusString)
            UtilOps.output("Stop the " + voltdb_instance_name + " have no correct response.")
        client.close()
    except Exception as e:
        logger_.error("Exception:{0}".format(e))


def db_rejoin(rejoin_node, placement_group_name=None):
    """

    :param rejoin_node:  <external interface>/<internal interface>/<public(http) interface>/<replication interface>/<admin interface>
    :param rejoin_node_placement:
    :return:
    """
    node_interfaces = rejoin_node.split('/')
    if len(node_interfaces) != 5:
        vdb_tool_output(
            "Rejoin opreation need 5 network interfaces, format as:" +
            "<external interface>/<internal interface>/<public(http) interface>/<replication interface>/<admin interface>",
            level=logging.ERROR)
        os._exit(1)

    voltdb_rejoin_tmd = os.path.join(snaptmd, "vdb_rejoin" + str(process_num))
    UtilOps.snap_check_dir(voltdb_rejoin_tmd)
    tmp_log4j = dbi_conf + "/voltdb_log4j.xml"
    UtilOps.render_file(tmp_log4j, voltdb_rejoin_tmd + "/voltdb_log4j.xml",
                        {'PLACEHOLDER_VAR_EIUM_HOME': var_eium, 'PLACEHOLDER_DB_NAME': voltdb_instance_name})
    deployment_file = os.path.join(vdb_store_path, "config", "deployment.xml")
    if not os.path.isfile(deployment_file):
        vdb_tool_output(
            "The " + deployment_file + " does not exist, please check.")
        os._exit(1)

    rejoin_node_external = node_interfaces[0]
    rejoin_node_internal = node_interfaces[1]
    rejoin_node_public = node_interfaces[2]
    rejoin_node_replication = node_interfaces[3]
    rejoin_node_admin = node_interfaces[4]
    rejoin_admin_port_interface = rejoin_node_admin + ":" + str(vdb_admin_port)
    rejoin_httpd_port_interface = rejoin_node_public + ":" + str(vdb_http_port)
    rejoin_repl_port_interface = rejoin_node_replication + ":" + str(vdb_replication_port)
    rejoin_client_port_interface = rejoin_node_external + ":" + str(vdb_client_port)
    rejoin_internal_port_interface = rejoin_node_internal + ":" + str(vdb_internal_port)

    rejoin_placement_group = get_placement_group(rejoin_node_external)
    if not placement_group_name:
        rejoin_placement_group = " --placement-group=" + placement_group_name

    status_command = vdb_home + "/bin/sqlcmd --servers=" + rejoin_node_external + " --port=" + str(
        vdb_client_port) + " --user=" + vdb_admin_user + " --password=" + vdb_admin_pwd + " --query=\"exec @SystemInformation overview\""
    logger_.debug("check rejoin node in cluster:" + status_command)
    return_code, output = commands.getstatusoutput(status_command)
    if return_code == 0:
        vdb_tool_output("The rejoin node exist in the cluster, don't rejoin again.", level=logging.WARN)
        os._exit(0)

    cluster_properties_file = os.path.join(vdb_root_path, "voltdbroot", "config", "cluster.properties")
    if not os.path.isfile(cluster_properties_file):
        vdb_tool_output("The " + cluster_properties_file + " does not exist in this node", level=logging.ERROR)
        os._exit(1)

    cluster_properties = Properties(cluster_properties_file).getProperties()
    cluster_count = cluster_properties["org.voltdb.cluster.hostcount"]
    vdb_tool_output("{0} hosts should be in cluster".format(cluster_count))
    alive_count = len(get_alive_servers(vdb_host_node))
    vdb_tool_output("Alive hosts in cluster is:{0}".format(alive_count))
    if alive_count >= cluster_count:
        vdb_tool_output("Alive host count is equals the cluster host count,rejoin operation ignore.")
        os._exit(0)
    else:
        vdb_tool_output("The rejoin operation permit, continue...")

    # ssh check
    return_code, result = SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd("echo hello")
    if return_code != 0:
        vdb_tool_output("SSH user [{0}] can't access [{1}], please check.".format(vdb_ssh_user, rejoin_node_external),
                        level=logging.ERROR)
        os._exit(1)

    # check the rejoin node has been install voltdb the eIUN come with
    return_code, result = SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd("ls " + vdb_home)
    if return_code != 0:
        vdb_tool_output("The Voltdb home " + vdb_home + " does not found in rejoin node.",
                        level=logging.ERROR)
        os._exit(3)

    # check voltdb version
    voltdb_version = get_voltdb_version()
    vdb_tool_output("Host voltdb version is:" + voltdb_version)

    return_code, result = SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd("cat " + vdb_home + "/version.txt")
    rejoin_voltdb_version = result
    vdb_tool_output("Rejoin node voltdb version is:" + rejoin_voltdb_version)
    if voltdb_version != rejoin_voltdb_version:
        vdb_tool_output(
            "Rejoin node voltdb version is not equals to the host node voltdb version, exit rejoin operation.",
            level=logging.ERROR)
        os._exit(4)

    init_db_file = os.path.join(voltdb_rejoin_tmd, "voltdb_init_{0}.sh".format(process_num))
    rejoin_db_file = os.path.join(voltdb_rejoin_tmd, "voltdb_rejoin_{0}.sh".format(process_num))

    UtilOps.write_file(rejoin_db_file, "export JAVA_HOME=" + vdb_java_home + "\n")
    UtilOps.write_file(rejoin_db_file, "export PATH=$JAVA_HOME/bin:$PATH" + "\n")
    # UtilOps.write_file(start_db_file, "mkdir -p " + var_eium + "/csv" + "\n")
    UtilOps.write_file(rejoin_db_file,
                       "export LOG4J_CONFIG_PATH=" + voltdb_rejoin_tmd + "/voltdb_log4j.xml" + "\n")
    # UtilOps.write_file(rejoin_db_file, "export VOLTDB_HEAPMAX={0}".format(voltdb_heapmax) + "\n")
    UtilOps.write_file(rejoin_db_file,
                       "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true -DDISABLE_JMX=true\"" + "\n")
    start_hosts = vdb_host_node

    init_command = vdb_home + "/bin/voltdb init --force --config=" + voltdb_rejoin_tmd + "/deployment.xml --dir=" + vdb_root_path + "\n"
    UtilOps.write_file(init_db_file, init_command)
    start_command = vdb_home + "/bin/voltdb start --dir=" + vdb_root_path + " --host=" + start_hosts + \
                    " --externalinterface=" + rejoin_node_external + " --internalinterface=" + rejoin_node_internal + \
                    " --publicinterface=" + rejoin_node_public + " --admin=" + rejoin_admin_port_interface + \
                    " --client=" + rejoin_client_port_interface + " --http=" + rejoin_httpd_port_interface + \
                    " --internal=" + rejoin_internal_port_interface + " --replication=" + rejoin_repl_port_interface + \
                    " --zookeeper=" + str(vdb_zookeeper_port) + rejoin_placement_group + " --background \n"
    UtilOps.write_file(rejoin_db_file, start_command)

    SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd("mkdir -p " + voltdb_rejoin_tmd)
    SSHUtil(rejoin_node_external, vdb_ssh_user).scp_file_to(os.path.join(voltdb_rejoin_tmd, "voltdb_log4j.xml"),
                                                            os.path.join(voltdb_rejoin_tmd, "voltdb_log4j.xml"))
    SSHUtil(rejoin_node_external, vdb_ssh_user).scp_file_to(os.path.join(voltdb_rejoin_tmd, "deployment.xml"),
                                                            deployment_file)
    SSHUtil(rejoin_node_external, vdb_ssh_user).scp_file_to(
        voltdb_rejoin_tmd + "/voltdb_init_{0}.sh".format(process_num), init_db_file)
    SSHUtil(rejoin_node_external, vdb_ssh_user).scp_file_to(
        voltdb_rejoin_tmd + "/voltdb_rejoin_{0}.sh".format(process_num), rejoin_db_file)

    SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd(
        "chmod +x " + voltdb_rejoin_tmd + "/*.sh")

    # Init DB in the rejoin node
    ret_code, result = SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd(
        "sh " + voltdb_rejoin_tmd + "/voltdb_init_{0}.sh".format(process_num))
    if ret_code == 0:
        vdb_tool_output("Init the " + voltdb_instance_name + " db in " + rejoin_node_external + " host.",
                        level=logging.INFO)
    else:
        vdb_tool_output("Failed to init the " + voltdb_instance_name + " db.", level=logging.ERROR)
        vdb_tool_output("Output message is: " + result, level=logging.ERROR)
        os._exit(1)

    # start DB in the rejoin node
    ret_code, result = SSHUtil(rejoin_node_external, vdb_ssh_user).exec_cmd(
        "sh " + voltdb_rejoin_tmd + "/voltdb_rejoin_{0}.sh".format(process_num))

    if ret_code == 0:
        vdb_tool_output("Start the " + voltdb_instance_name + " db in " + rejoin_node_external + " host.",
                        level=logging.INFO)
    else:
        vdb_tool_output("Failed to start the " + voltdb_instance_name + " db.", level=logging.ERROR)
        vdb_tool_output("Output message is: " + result, level=logging.ERROR)
        os._exit(1)


    # Check rejoin node status
    vdb_tool_output("Waiting rejoin......")
    time.sleep(10)
    if check_db_start_status(rejoin_node_external) == 0:
        vdb_tool_output("Start sync .database.ini in current cluster.")
    else:
        vdb_tool_output("Rejoin node failure, please contact with administrator.", level=logging.ERROR)
        os._exit(1)

    # generate .database.ini from @systemInformation store procedure
    db_ini_obj = generate_database_ini()
    YAMLOps.write_yaml(db_ini_obj, os.path.join(voltdb_rejoin_tmd, ".database.ini"))
    new_node_list = db_ini_obj["Deployment"]["VOLTDB_NODE_LIST"]
    for node in new_node_list:
        SSHUtil(node["external_interface"], vdb_ssh_user).scp_file_to(os.path.join(vdb_home, ".database.ini"),
                                                                os.path.join(voltdb_rejoin_tmd, ".database.ini"))
    db_cleanup()
    vdb_tool_output("Rejoin completed..")

## Main process ##
process_num = os.getpid()  # process ID
snaptmd = "/tmp"
eium_installation_ini = os.path.join(eium_home, "siu_install.ini")
if not os.path.isfile(eium_installation_ini):
    logger_.error(
        "the siu_install.ini file does exit in the {0} folder, exit it!".format(
            os.path.abspath(eium_installation_ini)))
    os._exit(1)
ini_properties = Properties(eium_installation_ini).getProperties()
var_eium = ini_properties['VarRoot']
vdb_java_home = os.path.dirname(ini_properties['JDKHome'])
vdb_home = os.path.join(eium_home, "VoltDB")
eium_voltdb_tool = os.path.join(eium_home, "RTC", "tools", "vdbtool")
db_install_home = os.path.join(eium_home, "RTC", "tools", "DBInstaller")
dbi_conf = os.path.join(db_install_home, "config")
dbi_lib = os.path.join(db_install_home, "lib")
database_ini_file = os.path.join(vdb_home, "." + voltdb_instance_name + ".ini")
if not os.path.isfile(database_ini_file):
    logger_.error("local node is not a node of the " + voltdb_instance_name + " cluster.")
    os._exit(1)

# load the .database.ini file

config_data = YAMLOps.load_config(database_ini_file)
logger_.debug(config_data)
database_name = config_data["Deployment"]["DATABASE_NAME"]
vdb_ssh_user = config_data["Deployment"]["VDB_SSH_USER"]
vdb_admin_user = config_data["Deployment"]["VOLTDB_ADMIN_USERNAME"]
vdb_admin_pwd = config_data["Deployment"]["VOLTDB_ADMIN_PASSWORD"]
vdb_admin_pwd_encrypted = vdb_admin_pwd
vdb_user = config_data["Deployment"]["VOLTDB_USER_NAME"]
vdb_pwd = config_data["Deployment"]["VOLTDB_USER_PASSWORD"]
vbd_pwd_encrypted = vdb_pwd
vdb_work_model = config_data["Deployment"]["VOLTDB_WORK_MODEL"]
cluster_node_list = config_data["Deployment"]["VOLTDB_NODE_LIST"]
cluster_node_place_group = config_data["Deployment"]["VOLTDB_PLACEMENT_GROUPS"]
vdb_admin_port = config_data["Deployment"]["VOLTDB_ADMIN_PORT"]
vdb_client_port = config_data["Deployment"]["VOLTDB_CLIENT_PORT"]
vdb_http_port = config_data["Deployment"]["VOLTDB_HTTP_PORT"]
vdb_internal_port = config_data["Deployment"]["VOLTDB_INTERNAL_PORT"]
vdb_replication_port = config_data["Deployment"]["VOLTDB_REPLICATION_PORT"]
vdb_start_port = config_data["Deployment"]["VOLTDB_START_PORT"]
vdb_zookeeper_port = config_data["Deployment"]["VOLTDB_ZOOKEEPER_PORT"]
vdb_root_path = config_data["Deployment"]["VOLTDB_ROOT_PATH"]
vdb_store_path = os.path.join(vdb_root_path, "voltdbroot")
node_list = config_data["Deployment"]["VOLTDB_NODE_LIST"]
voltdb_placement_groups = config_data["Deployment"]["VOLTDB_PLACEMENT_GROUPS"]

class_path = ".:" + eium_voltdb_tool + ":" \
             + UtilOps.get_files(eium_home + "/lib", "*.jar") + ":" \
             + UtilOps.get_files(eium_voltdb_tool + "/lib", "*.jar", excludes=["org.slf4j.slf4j-log4j12.jar"]) + ":" \
             + UtilOps.get_files(dbi_lib, "*.jar")
logger_.debug("CLASSPATH:" + class_path)

exit_code, output = commands.getstatusoutput(
    "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool decrypt " + vdb_admin_pwd)
if exit_code != 0:
    logger_.error("Decrypted voltdb admin password error.")
    logger_.error(output)
else:
    vdb_admin_pwd = output
    # logger_.info("Voltdb admin password is:" + vdb_admin_pwd)

exit_code, output = commands.getstatusoutput(
    "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool decrypt " + vdb_pwd)
if exit_code != 0:
    logger_.error("Decrypted voltdb user {0} password error.".format(vdb_user))
    logger_.error(output)
else:
    vdb_pwd = output
    # logger_.info("voltdb user {0} password is {1}".format(vdb_user, vdb_pwd))

date_ = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))

local_network_interface = UtilOps.getNetInterfaces()
vdb_host_node = "127.0.0.1"
for k, v in local_network_interface.items():
    for node in cluster_node_list:
        if v == node["external_interface"]:
            vdb_host_node = v
            break
logger_.info("the vdb_host_node is:" + vdb_host_node)

# db_status()

# db_stop()

# db_start()

generate_database_ini()
