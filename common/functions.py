#!/bin/python

import yaql
import yaml
import logging
import os
import string
import paramiko
import warnings
import fnmatch
import psutil
import sys


# data_source = yaml.load(open('C:/Users/chzhenhu/PycharmProjects/DBInstaller/config/snap_sprdb.yaml', 'r'),
#                         Loader=yaml.CLoader)
#
# # print data_source
# print(data_source["Deployment"]["VOLTDB_NODE_LIST"][0]["replication_interface"])


# output = yaml.dump(data_source, Dumper=yaml.CDumper)
#
# print output

# engine = yaql.factory.YaqlFactory().create()
#
# expression = engine(
#     '$.Deployment.VOLTDB_INSTANCE_NAME')
#
# order = expression.evaluate(data=data_source)
# print order

class UtilOps(object):

    @staticmethod
    def snap_check_dir(dirname):
        if not os.path.isdir(dirname):
            os.makedirs(dirname)

    @staticmethod
    def render_file(source_file, dest_file, replace_strings={}):
        with open(source_file, 'r') as r_f:
            with open(dest_file, 'a+') as w_f:
                for line in r_f.readlines():
                    a = string.Template(line)
                    w_f.write(a.safe_substitute(**replace_strings))

    @staticmethod
    def write_file(dest_file, message):
        with open(dest_file, 'a+') as f:
            f.write(message)

    @staticmethod
    def write_file_to_file(source_file, dest_file):
        UtilOps.render_file(source_file, dest_file)

    @staticmethod
    def get_files(file_path, pattern, excludes=[]):
        """
          return files format is: file1_path:file2_path

        """
        jars_path = ""
        if os.path.isdir(file_path):
            for file_ in os.listdir(file_path):
                match_flag = False
                if fnmatch.fnmatch(file_, pattern):
                    for item in excludes:
                        if item in file_:
                            match_flag = True
                    if not match_flag:
                        jars_path = jars_path + file_path + "/" + file_ + ":"
            if len(jars_path) > 0:
                jars_path = jars_path[:-1]
        return jars_path

    @staticmethod
    def output(message):
        sys.stdout.write(message)
        sys.stdout.write("\n")
        sys.stdout.flush()

    @staticmethod
    def getNetInterfaces():
        """
         get Network intefaces with family(AF_INET)=2
        :return: {"ens161":"192.168.3.14", "lo":"127.0.0.1","ens192":"15.116.78.152", "ens224":"192.168.1.14",
                 "ens256":"192.168.2.14", ......}
        """
        net_interface = {}
        net_info = psutil.net_if_addrs()
        for k, v in net_info.items():
            for snicaddr_item in v:
                if snicaddr_item.family == 2:
                    net_interface[k] = snicaddr_item.address
        # print(net_interface)
        return net_interface


class YAMLOps(object):

    @staticmethod
    def load_config(config_file):
        config_deployment = yaml.load(open(config_file, 'r'), Loader=yaml.FullLoader)
        # config_deployment = yaml.load(open(config_file, 'r'))
        return config_deployment

    @staticmethod
    def write_yaml(db_ini, db_ini_file):
        with open(db_ini_file, "w") as yaml_file:
            yaml.dump(db_ini, yaml_file, default_flow_style=False)


class LogOps(object):

    def __init__(self, log_file, log_level, console_enable=True):
        logger = logging.getLogger("DBInstaller")
        self.logger = logger
        logger.setLevel(level=log_level)
        handler = logging.FileHandler(log_file)
        handler.setLevel(log_level)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)

        console = logging.StreamHandler()
        console.setLevel(log_level)
        console.setFormatter(formatter)

        logger.addHandler(handler)
        if console_enable:
            logger.addHandler(console)

    def debug(self, message):
        self.logger.debug(message)

    def info(self, message):
        self.logger.info(message)

    def warn(self, message):
        self.logger.warning(message)

    def error(self, message):
        self.logger.error(message)


class Properties(object):

    def __init__(self, fileName):
        warnings.filterwarnings(action='ignore', module='.*paramiko.*')
        self.fileName = fileName
        self.properties = {}

    def __getDict(self, strName, dictName, value):

        if (strName.find('.') > 0):
            k = strName.split('.')[0]
            dictName.setdefault(k, {})
            return self.__getDict(strName[len(k) + 1:], dictName[k], value)
        else:
            dictName[strName] = value
            return

    def getProperties(self):
        try:
            pro_file = open(self.fileName, 'Ur')
            for line in pro_file.readlines():
                line = line.strip().replace('\n', '')
                if line.find("#") != -1:
                    line = line[0:line.find('#')]
                if line.find('=') > 0:
                    strs = line.split('=')
                    strs[1] = line[len(strs[0]) + 1:]
                    self.__getDict(strs[0].strip(), self.properties, strs[1].strip())
        except Exception, e:
            raise e
        else:
            pro_file.close()
        return self.properties


class SSHUtil(object):

    def __init__(self, hostname, username, port=22):
        self.hostname = hostname
        self.username = username
        self.port = port
        paramiko.util.log_to_file("/tmp/paramiko.log")

    def exec_cmd(self, command):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        ssh.connect(hostname=self.hostname, port=self.port, username=self.username, auth_timeout=2)
        try:
            stdin, stdout, stderr = ssh.exec_command(command)
            err_list = stderr.readlines()
            if len(err_list) > 0:
                return 1, "\n".join(err_list)
            else:
                return 0, stdout.read()
        except paramiko.ssh_exception.SSHException as e:
            raise e
        finally:
            ssh.close()

    def scp_file_to(self, remote_file_path, local_file_path):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        ssh.connect(hostname=self.hostname, port=self.port, username=self.username, auth_timeout=2)
        # transport_ = paramiko.Transport((self.hostname, self.port))
        # transport_.connect(username=self.username)
        try:
            # sftp_ = paramiko.SFTPClient.from_transport(transport_)
            sftp_ = paramiko.SFTPClient.from_transport(ssh.get_transport())
            sftp_.put(local_file_path, remote_file_path)
            return 0, "put files successfully."
        except Exception as e:
            return 1, e.message
        finally:
            # transport_.close()
            ssh.close

    def scp_file_from(self, remote_file_path, local_file_path):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy)
        ssh.connect(hostname=self.hostname, port=self.port, username=self.username, auth_timeout=2)
        try:
            sftp_ = paramiko.SFTPClient.from_transport(ssh.get_transport())
            sftp_.get(remote_file_path, local_file_path)
            return 0, "get files successfully."
        except Exception as e:
            return 1, e.message
        finally:
            ssh.close()

    def scp_directory_to(self, remote_directory_path, local_directory_path):
        pass

    def scp_directory_from(self, remote_directory_path, local_directory_path):
        pass



# db_ini_obj = {"VOLTDB_INSTANCE_NAME": "session_db", "VOLTDB_NODE_LIST": [
#     {"external_interface": "15.116.78.152", "internal_interface": "15.116.78.152", "httpd_interface": "15.116.78.152",
#      "replication_interface": "15.116.78.152", "admin_interface": "15.116.78.152"}],
#                              "VOLTDB_STORE_PATH": "/var/opt/SIU_snap/voltdb/dbs/session", "VOLTDB_CLIENT_PORT": 21212,
#                              "VOLTDB_ADMIN_PORT": 21213, "VOLTDB_HTTP_PORT": 21214, "VOLTDB_INTERNAL_PORT": 21215,
#                              "VOLTDB_ZOOKEEPER_PORT": 21216, "VOLTDB_REPLICATION_PORT": 21217,
#                              "VOLTDB_USER_NAME": "spr_user",
#                              "VOLTDB_USER_PASSWORD": "%ENCRYPTED%A2B119A01D1E2A0561C22754DF40D2D3",
#                              "VOLTDB_ADMIN_USERNAME": "vdbadmin",
#                              "VOLTDB_ADMIN_PASSWORD": "%ENCRYPTED%5AEE3B799827803F61C22754DF40D2D3",
#                              "VOLTDB_START_PORT": 21215, "VOLTDB_WORK_MODEL": "ACTIVE", "VOLTDB_PLACEMENT_GROUPS": [
#         {"external_interface": "15.116.78.152", "placement_group": "China.SH.SiteA_server1"}]}
# exit_cionfig = YAMLOps.load_config(".database.yaml")
# exit_cionfig["Deployment"].append(db_ini_obj)
# YAMLOps.write_yaml(exit_cionfig, "datanase_test.yaml")

 # UtilOps.getNetInterfaces()
