#!/bin/python

from common.functions import YAMLOps
from common.functions import LogOps
from common.functions import Properties
from common.functions import UtilOps
from common.functions import SSHUtil
import commands
import shutil
import logging
import os
import sys
import time


def get_db_model(model_id):
    return {
        1: "Non replication database",
        2: "Passive DR-Master database",
        3: "Passive DR-Replica database",
        4: "Cross DR-Active database"
    }.get(model_id)


def get_deployment_template(model_id):
    return {
        1: os.path.join(dbi_tpl, database_name + "_no_repl_deployment.tmpl"),
        2: os.path.join(dbi_tpl, database_name + "_master_deployment.tmpl"),
        3: os.path.join(dbi_tpl, database_name + "_replica_deployment.tmpl"),
        4: os.path.join(dbi_tpl, database_name + "_replica_deployment.tmpl")
    }.get(model_id)


def get_start_hosts(node_list, internal_port):
    nodes_str = ""
    for node in node_list:
        external_host = node["external_interface"]
        nodes_str += external_host + ":" + str(internal_port) + ","
    if len(nodes_str) > 0:
        nodes_str = nodes_str[:-1]
    return nodes_str


def get_placement_group(external_host):
    placement_group_name = "d00"
    for placement_group in voltdb_placement_groups:
        if placement_group["external_interface"] == external_host:
            placement_group_name = placement_group["placement_group"]
            break
    return placement_group_name


def get_apps():
    """

    :return: app name list
    """
    global abm_export_enable
    path_ = os.path.join(dbi_scripts, database_name)
    logger_.info("get self-defined store procedure jar files from {0}".format(path_))
    combine_dir_file = os.walk(path_)
    root, dirs, files = combine_dir_file.next()
    # for root, dirs, files in os.walk(path_, topdown=False):
    logger_.debug("root is:{0}".format(root))
    logger_.debug("dirs is:{0}".format(dirs))
    logger_.debug("files is:{0}".format(files))

    for app in dirs:
        if app == 'abm':
            abm_export_enable = "true"
    return dirs


def generate_store_procedure_jar():
    sp_jars = []
    apps = get_apps()
    for app in apps:
        app_sp_path = os.path.join(dbi_scripts, database_name, app, "voltdb", "sp_jars")
        if os.path.isdir(app_sp_path):
            jars_path = UtilOps.get_files(app_sp_path, "*.jar")
            sp_jars += jars_path.split(":")
    return sp_jars


def generate_jars_and_sqls():
    sp_jars = generate_store_procedure_jar()  # sp jar files list
    logger_.info("customized store procedure jar files:{0}".format(sp_jars))
    apps = get_apps()
    for app in apps:
        vdbcfg_path = os.path.join(dbi_scripts, database_name, app, "voltdb", "ddc")
        vdbcfg_dest_path = os.path.join(voltdb_tmd, "ddc")
        vdbcfg_files = UtilOps.get_files(vdbcfg_path, "*.vdbcfg")
        if len(vdbcfg_files) > 0:
            vdbcfg_file_lst = vdbcfg_files.split(":")
            for vdbcfg_file_ in vdbcfg_file_lst:
                shutil.copy(vdbcfg_file_, vdbcfg_dest_path)

        sql_path = os.path.join(dbi_scripts, database_name, app, "voltdb")
        sql_files = UtilOps.get_files(sql_path, "*.sql")
        if len(sql_files) > 0:
            sql_file_lst = sql_files.split(":")
            for sql_file_ in sql_file_lst:
                UtilOps.write_file_to_file(sql_file_, voltdb_tmd + "/" + voltdb_instance_name + ".sql")
    logger_.info("VoltDB ddc and sql files for %s are merged successfully." % voltdb_instance_name)

    src_folder = os.path.join(voltdb_tmd, "src")
    exit_code, output = commands.getstatusoutput(
        "cd " + voltdb_tmd + " && java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.ProGenTools")
    if exit_code == 0:
        logger_.info("voltdb store procedure source files generated.")
    logger_.debug("ProGenTools output:" + output)

    if os.path.isdir(src_folder):
        exit_code, output = commands.getstatusoutput(
            "cd " + voltdb_tmd + " && find src -name '*.java' > javasourcefiles &&  javac -cp \"" + class_path + "\" -d bin @javasourcefiles")
        logger_.debug("Compile javasource file output is:" + output)
        if exit_code == 0:
            logger_.info("voltdb store procedures for %s are generated successfully." % voltdb_instance_name)
        else:
            logger_.error("voltdb store procedures for %s are failed to be generated." % voltdb_instance_name)
            os._exit(1)
    else:
        voltdb_tmp_ddl = os.path.join(voltdb_tmd, "ddl")
        sql_files = UtilOps.get_files(voltdb_tmp_ddl, "*.sql")
        if len(sql_files) > 0:
            sql_file_lst = sql_files.split(":")
            for sql_file_ in sql_file_lst:
                shutil.copy(sql_file_, voltdb_tmd)
            logger_.info("have no store procedures generated from vdbcfg files.")

    # process the timer jar files
    have_timer_flag = False
    exit_code, output = commands.getstatusoutput("ls -t " + eium_plugin + " | grep " + timer_plugin + " | head -1")
    if len(output) > 0:
        logger_.info("timer plugin folder name is:" + output)
        have_timer_flag = True
        timer_plugin_folder = os.path.join(eium_plugin, output)

    # combine customer sp jar, vdbcfg jar, timer jar:
    all_class_folder = os.path.join(voltdb_tmd, "bin")
    for sp_jar_file in sp_jars:
        exit_code, output = commands.getstatusoutput("cd " + all_class_folder + " && jar -xvf " + sp_jar_file)
        logger_.debug("extract " + sp_jar_file + ": " + output)

    if have_timer_flag:
        timer_jar = timer_plugin_folder + "/voltdb-procs.jar"
        if os.path.isfile(timer_jar):
            exit_code, output = commands.getstatusoutput("cd " + all_class_folder + " && jar -xvf " + timer_jar)
            logger_.debug("extract " + timer_jar + ": " + output)

    exit_code, output = commands.getstatusoutput(
        "cd " + voltdb_tmd + " && jar -cvf " + voltdb_instance_name + ".jar -C bin/ .")
    logger_.debug("generate the " + voltdb_instance_name + ".jar file output is: " + output)
    if os.path.isfile(os.path.join(voltdb_tmd, voltdb_instance_name + ".jar")):
        logger_.info("the " + voltdb_instance_name + ".jar file is generated successfully.")
    else:
        logger_.error("the " + voltdb_instance_name + ".jar file is failed to generate, exit it.")
        os._exit(1)

    # combine all sql files
    ddl_shemal_sql = os.path.join(voltdb_tmd, "ddl_schema.sql")
    timer_sql = os.path.join(timer_plugin_folder, "voltdb.ddl")
    votldb_instance_sql = os.path.join(voltdb_tmd, voltdb_instance_name + ".sql")
    UtilOps.write_file_to_file(ddl_shemal_sql, votldb_instance_sql)
    if os.path.isfile(timer_sql):
        UtilOps.write_file_to_file(timer_sql, votldb_instance_sql)
    logger_.info("the " + votldb_instance_sql + " sql file is generated successfully.")


def initial_and_start_db(node_list, voltdb_ssh_user):
    deployment_template_file = get_deployment_template(db_model)
    UtilOps.render_file(deployment_template_file, voltdb_tmd + "/deployment.xml",
                        {'PLACEHOLDER_KFACTOR': voltdb_kfactor,
                         'PLACEHOLDER_SITES_PER_HOSTS': voltdb_sites_per_host,
                         'PLACEHOLDER_EXPORT_ABM_ENABLED': abm_export_enable,
                         'PLACEHOLDER_VOLTDB_EXPORT_ROLL_PERIOD': voltdb_export_roll_period,
                         'PLACEHOLDER_VAR_EIUM': var_eium,
                         'PLACEHOLDER_ADMIN_USER': voltdb_admin_user,
                         'PLACEHOLDER_ADMIN_PASSWORD': voltdb_admin_pwd,
                         'PLACEHOLDER_DB_USER': voltdb_user,
                         'PLACEHOLDER_DB_PASSWORD': voltdb_pwd,
                         'PLACEHOLDER_DB_ROOT': voltdb_root,
                         'PLACEHOLDER_ADMIN_PORT': voltdb_admin_port,
                         'PLACEHOLDER_HTTPD_PORT': voltdb_httpd_port,
                         'PLACEHOLDER_SOURCE_NODELIST': dr_source_nodes_lst,
                         'PLACEHOLDER_DRID': dr_id})
    logger_.info("voltdb deployment.xml for " + voltdb_instance_name + " is configured successfully.")

    # mask the deployment.xml
    if os.path.isfile(voltdb_tmd + "/deployment.xml"):
        ret_code, output_ = commands.getstatusoutput(voltdb_home + "/bin/voltdb mask " + voltdb_tmd + "/deployment.xml")
        if "Error" in output_:
            ret_code = 1
        if ret_code == 0:
            logger_.info("mask the deployment.xml successfully. ")
        else:
            logger_.error("failed to mask the deployment.xml, error message is: " + output_)
            os._exit(1)

    # prepare voltdb initial file
    init_db_file = os.path.join(voltdb_tmd, "voltdb_init_{0}.sh".format(process_num))
    start_db_file = os.path.join(voltdb_tmd, "voltdb_start_{0}.sh".format(process_num))
    voltdb_create_folder = voltdb_tmd + "_create"
    UtilOps.write_file(init_db_file, "export JAVA_HOME=" + JAVA_HOME + "\n")
    UtilOps.write_file(init_db_file, "export PATH=$JAVA_HOME/bin:$PATH" + "\n")
    UtilOps.write_file(init_db_file, "mkdir -p " + var_eium + "/csv" + "\n")
    UtilOps.write_file(init_db_file, "export LOG4J_CONFIG_PATH=" + voltdb_create_folder + "/voltdb_log4j.xml" + "\n")
    UtilOps.write_file(init_db_file, "export VOLTDB_HEAPMAX={0}".format(voltdb_heapmax) + "\n")
    UtilOps.write_file(init_db_file,
                       "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true -DDISABLE_JMX=true\"" + "\n")
    UtilOps.write_file(init_db_file,
                       voltdb_home + "/bin/voltdb init --force --config=" + voltdb_create_folder + "/deployment.xml --dir=" + voltdb_root + " --classes=" + os.path.join(
                           voltdb_create_folder, voltdb_instance_name + ".jar") + " --schema=" + os.path.join(
                           voltdb_create_folder,
                           voltdb_instance_name + ".sql") + "\n")

    # initilize the voltdb
    for node in node_list:
        external_host = node["external_interface"]
        internal_host = node["internal_interface"]
        public_host = node["httpd_interface"]
        admin_interface = node["admin_interface"] + ":" + str(voltdb_admin_port)
        httpd_interface = public_host + ":" + str(voltdb_httpd_port)
        repl_port_interface = node["replication_interface"] + ":" + str(voltdb_repl_port)
        client_port_interface = external_host + ":" + str(voltdb_client_port)
        internal_interface = internal_host + ":" + str(voltdb_internal_port)
        placement_group_name = get_placement_group(external_host)
        UtilOps.write_file(start_db_file, "export JAVA_HOME=" + JAVA_HOME + "\n")
        UtilOps.write_file(start_db_file, "export PATH=$JAVA_HOME/bin:$PATH" + "\n")
        UtilOps.write_file(start_db_file, "mkdir -p " + var_eium + "/csv" + "\n")
        UtilOps.write_file(start_db_file,
                           "export LOG4J_CONFIG_PATH=" + voltdb_create_folder + "/voltdb_log4j.xml" + "\n")
        UtilOps.write_file(start_db_file, "export VOLTDB_HEAPMAX={0}".format(voltdb_heapmax) + "\n")
        UtilOps.write_file(start_db_file,
                           "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true -DDISABLE_JMX=true\"" + "\n")
        start_hosts = get_start_hosts(node_list, voltdb_internal_port)
        start_command = voltdb_home + "/bin/voltdb start --dir=" + voltdb_root + " --host=" + start_hosts + \
                        " --externalinterface=" + external_host + " --internalinterface=" + internal_host + \
                        " --publicinterface=" + public_host + " --admin=" + admin_interface + \
                        " --client=" + client_port_interface + " --http=" + httpd_interface + \
                        " --internal=" + internal_interface + " --replication=" + repl_port_interface + \
                        " --zookeeper=" + str(voltdb_zookeeper_port) + \
                        " --placement-group=" + placement_group_name + " --background \n"
        UtilOps.write_file(start_db_file, start_command)

        SSHUtil(external_host, voltdb_ssh_user).exec_cmd("mkdir -p " + voltdb_create_folder)
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(os.path.join(voltdb_create_folder, "deployment.xml"),
                                                            os.path.join(voltdb_tmd, "deployment.xml"))
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
            os.path.join(voltdb_create_folder, voltdb_instance_name + ".jar"),
            os.path.join(voltdb_tmd, voltdb_instance_name + ".jar"))
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(os.path.join(voltdb_create_folder, "voltdb_log4j.xml"),
                                                            os.path.join(voltdb_tmd, "voltdb_log4j.xml"))
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
            os.path.join(voltdb_create_folder, voltdb_instance_name + ".sql"),
            os.path.join(voltdb_tmd, voltdb_instance_name + ".sql"))
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
            voltdb_create_folder + "/voltdb_init_{0}.sh".format(process_num), init_db_file)
        SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
            voltdb_create_folder + "/voltdb_start_{0}.sh".format(process_num), start_db_file)

        SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
            "chmod +x " + voltdb_create_folder + "/*.sh".format(process_num))
        ret_code, result = SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
            "sh " + voltdb_create_folder + "/voltdb_init_{0}.sh".format(process_num))
        if ret_code == 0:
            logger_.info("initialize the " + voltdb_instance_name + " db successfully in " + external_host + " host.")
        else:
            logger_.error("failed to initialize the " + voltdb_instance_name + " db.")
            logger_.error("output message is: " + result)
            os._exit(1)

    # start db
    for node in node_list:
        external_host = node["external_interface"]
        ret_code, result = SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
            "sh " + voltdb_create_folder + "/voltdb_start_{0}.sh".format(process_num))
        if ret_code == 0:
            logger_.info("start the " + voltdb_instance_name + " db in " + external_host + " host.")
        else:
            logger_.error("failed to start the " + voltdb_instance_name + " db.")
            logger_.error("output message is: " + result)
            os._exit(1)

    db_work_model = "none"
    if db_work_model != 3:
        db_work_model = "ACTIVE"
    else:
        db_work_model = "REPLICA"

    exit_code, output = commands.getstatusoutput(
        "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool encrypt " + voltdb_admin_pwd)
    if exit_code != 0:
        logger_.error("encrypted voltdb admin password error.")
        logger_.error(output)
    else:
        voltdb_admin_pwd_encrypted = output
        # logger_.info("voltdb admin password is:" + voltdb_admin_pwd)

    exit_code, output = commands.getstatusoutput(
        "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool encrypt " + voltdb_pwd)
    if exit_code != 0:
        logger_.error("encrypted voltdb user {0} password error.".format(voltdb_user))
        logger_.error(output)
    else:
        voltdb_pwd_encrypted = output
    # logger_.info("voltdb user {0} password is {1}:".format(voltdb_user, voltdb_pwd))

    if check_voltdb_start_status(external_host, voltdb_create_folder) == 0:
        voltdb_data_store_path = os.path.join(voltdb_root, "voltdbroot")
        db_ini_obj = {"Deployment": {"VOLTDB_INSTANCE_NAME": voltdb_instance_name,
                                     "DATABASE_NAME": database_name,
                                     "VOLTDB_NODE_LIST": node_list,
                                     "VOLTDB_ROOT_PATH": voltdb_root,
                                     "VOLTDB_CLIENT_PORT": voltdb_client_port,
                                     "VOLTDB_ADMIN_PORT": voltdb_admin_port,
                                     "VOLTDB_HTTP_PORT": voltdb_httpd_port,
                                     "VOLTDB_INTERNAL_PORT": voltdb_internal_port,
                                     "VOLTDB_ZOOKEEPER_PORT": voltdb_zookeeper_port,
                                     "VOLTDB_REPLICATION_PORT": voltdb_repl_port,
                                     "VOLTDB_USER_NAME": voltdb_user,
                                     "VOLTDB_USER_PASSWORD": voltdb_pwd_encrypted,
                                     "VOLTDB_ADMIN_USERNAME": voltdb_admin_user,
                                     "VOLTDB_ADMIN_PASSWORD": voltdb_admin_pwd_encrypted,
                                     "VOLTDB_START_PORT": voltdb_start_port,
                                     "VOLTDB_WORK_MODEL": db_work_model,
                                     "VDB_SSH_USER": voltdb_ssh_user,
                                     "VOLTDB_PLACEMENT_GROUPS": voltdb_placement_groups}}
        YAMLOps.write_yaml(db_ini_obj, os.path.join(voltdb_create_folder, ".database.ini"))
        for node in node_list:
            external_host = node["external_interface"]
            ret_code, result = SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
                voltdb_home + "/."+voltdb_instance_name+".ini", voltdb_create_folder + "/.database.ini")
            if ret_code == 0:
                logger_.info(".database.ini wrote into " + voltdb_home + " folder in " + external_host + " host.")
            else:
                logger_.warn(
                    ".database.ini failed to write into " + voltdb_home + " folder in " + external_host + " host.")
                logger_.warn(result)
        # insert  a record into the .database.ini file, line:1237
    else:
        logger_.error("the database start failed, please contact to administrator!")


def check_voltdb_start_status(external_host, voltdb_create_folder):
    db_status_file = os.path.join(voltdb_tmd, "voltdb_check_{0}.sh".format(process_num))
    UtilOps.write_file(db_status_file, "export JAVA_HOME=" + JAVA_HOME + "\n")
    UtilOps.write_file(db_status_file, "export PATH=$JAVA_HOME/bin:$PATH" + "\n")
    UtilOps.write_file(db_status_file,
                       voltdb_home + "/bin/sqlcmd --servers=" + external_host + " --port=" + str(voltdb_client_port) +
                       " --user=" + voltdb_user + " --password=" + voltdb_pwd + " --query=\"exec @SystemInformation overview\"" + "\n")
    SSHUtil(external_host, voltdb_ssh_user).scp_file_to(
        voltdb_create_folder + "/voltdb_check_{0}.sh".format(process_num), db_status_file)
    SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
        "chmod +x " + voltdb_create_folder + "/*.sh".format(process_num))
    wait_count = 1
    while wait_count < 61:
        logger_.info("checking the " + voltdb_instance_name + " status ......")
        ret_code, result = SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
            "sh " + voltdb_create_folder + "/voltdb_check_{0}.sh".format(process_num))
        if ret_code == 0:
            SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
                "rm -f " + voltdb_create_folder + "/voltdb_check_{0}.sh".format(process_num))
            logger_.info("the " + voltdb_instance_name + " database start successfully.")
            return 0
        wait_count += 1
        time.sleep(10)
    SSHUtil(external_host, voltdb_ssh_user).exec_cmd(
        "rm -f " + voltdb_create_folder + "/voltdb_check_{0}.sh".format(process_num))
    return 1


def check_huge_page(ssh_user, check_host):
    logger_.info("check transparent huge page in " + check_host)

    ret_code, result = SSHUtil(check_host, ssh_user).exec_cmd("ls /sys/kernel/mm/transparent_hugepage/enabled")
    if ret_code == 0:
        ret_code2, result2 = SSHUtil(check_host, ssh_user).exec_cmd(
            "cat /sys/kernel/mm/transparent_hugepage/enabled | grep -i \"\[never\]\"")
        if ret_code2 != 0:
            logger_.error(
                "1.[{0}] The kernel is configured to use transparent huge pages (THP). This is not supported when running VoltDB. Use the following comamnd to disable this feature for the current session:".format(
                    check_host))
            logger_.error("sudo bash -c \" echo never > /sys/kernel/mm/transparent_hugepage/enabled\"")
            logger_.error("sudo bash -c \" echo never > /sys/kernel/mm/transparent_hugepage/defrag\"")
            os._exit(1)

    ret_code, result = SSHUtil(check_host, ssh_user).exec_cmd("ls /sys/kernel/mm/transparent_hugepage/defrag")
    if ret_code == 0:
        ret_code2, result2 = SSHUtil(check_host, ssh_user).exec_cmd(
            "cat /sys/kernel/mm/transparent_hugepage/defrag | grep -i \"\[never\]\"")
        if ret_code2 != 0:
            logger_.error(
                "2.[{0}] The kernel is configured to use transparent huge pages (THP). This is not supported when running VoltDB. Use the following comamnd to disable this feature for the current session:".format(
                    check_host))
            logger_.error("sudo bash -c \" echo never > /sys/kernel/mm/transparent_hugepage/enabled\"")
            logger_.error("sudo bash -c \" echo never > /sys/kernel/mm/transparent_hugepage/defrag\"")
            os._exit(1)


def check_voltdb_env(db_instance_name):
    UtilOps.snap_check_dir(voltdb_tmd)

    if not os.path.isfile(voltdb_home + "/bin/voltdb"):
        logger_.error("VOLTDB doesn't exist in the folder " + voltdb_home + "/bin/voltdb")
        os._exit(1)

    os.system("export JAVA_HOME=" + JAVA_HOME)
    os.system("export PATH=$JAVA_HOME/bin:$PATH")
    tmp_log4j = dbi_conf + "/voltdb_log4j.xml"
    UtilOps.render_file(tmp_log4j, voltdb_tmd + "/voltdb_log4j.xml",
                        {'PLACEHOLDER_VAR_EIUM_HOME': var_eium, 'PLACEHOLDER_DB_NAME': db_instance_name})
    commands.getoutput("export LOG4J_CONFIG_PATH=" + voltdb_tmd + "/voltdb_log4j.xml")

    if not os.path.isfile(JAVA_HOME + "/bin/java"):
        logger_.error("JAVA home doesn't correctly set in Environment variable: JAVA_HOME=" + JAVA_HOME)
        os._exit(1)

    if not os.path.isdir(eium_voltdb_tool):
        logger_.error("RTC voltdb tool directory doesn't exit in " + eium_voltdb_tool)
        os._exit(1)

    # ret_code, result = SSHUtil("15.116.78.152", "snap").exec_cmd("ls")
    # logger_.info("SSH return code is {0}".format(ret_code))
    # logger_.info("SSH Result is:"+result)
    #
    # ret_code, result = SSHUtil("15.116.78.152", "snap").scp_to("/tmp", "/home/snap/default.config")
    # logger_.info("SCP return code is {0}".format(ret_code))
    # logger_.info(result)
    exit_code, output = commands.getstatusoutput("base64 --version")
    if exit_code != 0:
        logger_.error("base64 tool can't be found, please check.")
        os._exit(1)

    exit_code, output = commands.getstatusoutput("ssh -V")
    if exit_code != 0:
        logger_.error("ssh tool can't be found, please check.")
        os._exit(1)


def create_db_in_voltdb(db_name, port_offset):
    global voltdb_kfactor
    voltdb_db_name = db_name

    UtilOps.snap_check_dir(voltdb_tmd + "/ddc")
    UtilOps.snap_check_dir(voltdb_tmd + "/bin")

    command_ = "cd " + voltdb_tmd + "; ln -s " + eium_voltdb_tool + "/ddl"
    os.system(command_)

    command_ = "cd " + voltdb_tmd + "; ln -s " + eium_voltdb_tool + "/procedures"
    os.system(command_)

    voltdb_ssh_user = current_user
    host_cnt = 0

    node_list = config_data["Deployment"]["VOLTDB_NODE_LIST"]

    host_cnt = len(node_list)
    logger_.info("{0} nodes configured in the cluster.".format(host_cnt))

    for node_item in node_list:
        external_interface = node_item["external_interface"]
        check_huge_page(voltdb_ssh_user, external_interface)

    if host_cnt > 1:
        voltdb_kfactor = 1
    logger_.info("voltdb k-factor value is:{0}".format(voltdb_kfactor))

    logger_.info("abm_export_enable is {0}".format(abm_export_enable))

    generate_jars_and_sqls()

    initial_and_start_db(node_list, voltdb_ssh_user)


# hold on line:921


##### Main Process ......#####################

logger_ = LogOps("DBInstaller.log", logging.INFO)

# logger_.info("Start print log")
# logger_.debug("Do something")
# logger_.warn("Something maybe fail.")
# logger_.info("Finish")
snap_tmp = "/tmp"
snap_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
logger_.debug('snap_dir is {0}'.format(snap_dir))
eium_installation_ini = '{0}/../../../../siu_install.ini'.format(snap_dir)
logger_.debug('eium_installation_ini is {0}'.format(eium_installation_ini))
if not os.path.isfile(eium_installation_ini):
    logger_.error(
        "the siu_install.ini file does exit in the {0} folder, exit it!".format(os.path.abspath(eium_installation_ini)))
    os._exit(1)
ini_properties = Properties(eium_installation_ini).getProperties()
eium_home = ini_properties['SiuRoot']
eium_plugin = "{0}/plugins".format(eium_home)
var_eium = ini_properties['VarRoot']
voltdb_home = "{0}/VoltDB".format(eium_home)
mysql_home = "{0}/mysql".format(eium_home)

timer_plugin = "com.hp.usage.timers_"
process_num = os.getpid()
dbi_home = os.path.abspath('{0}/..'.format(snap_dir))
dbi_bin = dbi_home + '/bin'
dbi_scripts = dbi_home + '/dbscripts'
dbi_tpl = dbi_home + '/template'
dbi_conf = dbi_home + '/config'
dbi_lib = dbi_home + '/lib'
logger_.debug("dbi_home is %s" % dbi_home)
logger_.debug("dbi_bin is %s" % dbi_bin)
logger_.debug("dbi_scripts is %s" % dbi_scripts)
logger_.debug("dbi_tpl is %s" % dbi_tpl)
logger_.debug("dbi_conf is %s" % dbi_conf)
logger_.debug("dbi_lib is %s" % dbi_lib)

voltdb_tmd = "{0}/voltdb.{1}".format(snap_tmp, process_num)
rtc_home = os.path.abspath('{0}/../../'.format(dbi_home))
rtp_home = eium_home + "/RTP"
eium_voltdb_tool = rtc_home + "/tools/vdbtool"
logger_.debug("rtc_home is %s" % rtc_home)
logger_.debug("rtp_home is %s" % rtp_home)
logger_.debug("eium_voltdb_tool is %s" % eium_voltdb_tool)

(status, output) = commands.getstatusoutput("whoami")
current_user = commands.getoutput("whoami")
logger_.debug("current_user is %s" % current_user)
voltdb_ssh_user = current_user
abm_export_enable = "false"

logger_.info("unset http_proxy https_proxy")
commands.getstatusoutput("unset http_proxy https_proxy")

class_path = ".:" + eium_voltdb_tool + eium_home + "/lib/datastruct-api.jar:" \
             + UtilOps.get_files(eium_home + "/lib", "*.jar") + ":" \
             + UtilOps.get_files(eium_voltdb_tool + "/lib", "*.jar", excludes=["org.slf4j.slf4j-log4j12.jar"]) + ":" \
             + UtilOps.get_files(rtp_home + "/virgo/repository/snap", "*.jar") + ":" \
             + UtilOps.get_files(dbi_lib, "*.jar") + ":" \
             + UtilOps.get_files(rtc_home + "/repository", "*.jar", excludes=["jdbccfg"])
logger_.debug("CLASSPATH is %s" % class_path)

config_file = dbi_home + "/config/snap_sprdb.yaml"
config_data = YAMLOps.load_config(config_file)
logger_.debug(config_data)
VOLTDB_JAVA_HOME = config_data["Deployment"]["VOLTDB_JAVA_HOME"]
JAVA_HOME = VOLTDB_JAVA_HOME
database_name = config_data["Deployment"]["DATABASE_NAME"]
voltdb_instance_name = config_data["Deployment"]["VOLTDB_INSTANCE_NAME"]
db_model = config_data["Deployment"]["VOLTDB_WORK_MODEL"]
dr_id = config_data["Deployment"]["VOLTDB_DR_ID"]
dr_source_nodes_lst = config_data["Deployment"]["VOLTDB_DR_SOURCE"]
is_only_generate_catalog = config_data["Deployment"]["ONLY_DEPLOYMENT_OPERATION"]
voltdb_admin_user = config_data["Deployment"]["VOLTDB_ADMIN_USERNAME"]
voltdb_admin_pwd = config_data["Deployment"]["VOLTDB_ADMIN_PASSWORD"]
voltdb_user = config_data["Deployment"]["VOLTDB_USER_NAME"]
voltdb_pwd = config_data["Deployment"]["VOLTDB_USER_PASSWORD"]
voltdb_sites_per_host = config_data["Deployment"]["VOLTDB_SITES_PER_HOST"]
voltdb_export_roll_period = config_data["Deployment"]["VOLTDB_EXPORT_ROLL_PERIOD"]
# VOLTDB_ADMIN_PWD_ORI=VOLTDB_ADMIN_PWD
exit_code, output = commands.getstatusoutput(
    "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool decrypt " + voltdb_admin_pwd)
if exit_code != 0:
    logger_.error("Decrypted voltdb admin password error.")
    logger_.error(output)
else:
    voltdb_admin_pwd = output
    logger_.info("Voltdb admin password is:" + voltdb_admin_pwd)

exit_code, output = commands.getstatusoutput(
    "java -cp \"" + class_path + "\" com.hp.atom.vdb.tools.PasswdTool decrypt " + voltdb_pwd)
if exit_code != 0:
    logger_.error("Decrypted voltdb user {0} password error.".format(voltdb_user))
    logger_.error(output)
else:
    voltdb_pwd = output
    logger_.info("voltdb user {0} password is {1}:".format(voltdb_user, voltdb_pwd))

voltdb_root = config_data["Deployment"]["VOLTDB_ROOT_PATH"]
voltdb_client_port = config_data["Deployment"]["VOLTDB_CLIENT_PORT"]
voltdb_admin_port = config_data["Deployment"]["VOLTDB_ADMIN_PORT"]
voltdb_httpd_port = config_data["Deployment"]["VOLTDB_HTTP_PORT"]
voltdb_internal_port = config_data["Deployment"]["VOLTDB_INTERNAL_PORT"]
voltdb_zookeeper_port = config_data["Deployment"]["VOLTDB_ZOOKEEPER_PORT"]
voltdb_repl_port = config_data["Deployment"]["VOLTDB_REPLICATION_PORT"]
voltdb_start_port = voltdb_internal_port
voltdb_heapmax = config_data["Deployment"]["VOLTDB_HEAPMAX"]
voltdb_placement_groups = config_data["Deployment"]["VOLTDB_PLACEMENT_GROUPS"]

voltdb_kfactor = 0

logger_.info("voltdb database name:" + database_name)
logger_.info("voltdb database instance name:" + voltdb_instance_name)
logger_.info("voltdb installation model:" + get_db_model(db_model))
logger_.info("voltdb admin user name:" + voltdb_admin_user)
logger_.info("voltdb admin user password: ******")
logger_.info("voltdb instance user name:" + voltdb_user)
logger_.info("voltdb instance user password: ******")
logger_.info("voltdb sites per host:%s" % voltdb_sites_per_host)
logger_.info("voltdb export rolling period:%s" % voltdb_export_roll_period)
logger_.info("voltdb root path:%s" % voltdb_root)
logger_.info("voltdb client port:%s" % voltdb_client_port)
logger_.info("voltdb admin port:%s" % voltdb_admin_port)
logger_.info("voltdb httpd port:%s" % voltdb_httpd_port)
logger_.info("voltdb internal port:%s" % voltdb_internal_port)
logger_.info("voltdb replication port:%s" % voltdb_repl_port)

check_voltdb_env("spr_db")

create_db_in_voltdb("spr_db", 1)
