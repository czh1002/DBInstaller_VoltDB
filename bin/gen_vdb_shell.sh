#!/bin/bash

getFileKeyValue()
{
   FILE__=$1
   KEY__=$2
   #td is to replace \r
   cat  "$FILE__" | tr -d '\r' | grep "^${KEY__}=" | cut -d'=' -f2-
}

genVDBShell()
{
	DB_NAME=$1
	
	if [ -f ${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh ]; then
		
		VDB_JAVA_HOME=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_JAVA_HOME")
		VDB_HOME=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_HOME")
		VDB_NAME=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_NAME")
		VDB_HOST_NODE=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_HOST_NODE")
		VDB_SSH_USER=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_SSH_USER")
		EIUM_VOLTDB_TOOL=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "EIUM_VOLTDB_TOOL")
		EIUM_HOME=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "EIUM_HOME")
		VDB_FLAG_NAME=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VDB_FLAG_NAME")
		VOLTDB_HEAPMAX=$(getFileKeyValue "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh" "VOLTDB_HEAPMAX")

		# backup the snap_vdb_shell.sh
		mkdir -p ${DBInstaller_DIR}/backup/${DB_NAME}
		mv ${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh ${DBInstaller_DIR}/backup/${DB_NAME}/snap_vdb_shell.sh.$(date '+%Y%m%d%H%M%S')

		#Replace values from the template
		sed -e "s~\PLACEHOLDER_VOLTDB_JAVA_HOME~${VDB_JAVA_HOME}~" \
			-e "s~\PLACEHOLDER_VOLTDB_HOME~${VDB_HOME}~" \
			-e "s~\PLACEHOLDER_VOLTDB_DB_NAME~${VDB_NAME}~" \
			-e "s~\PLACEHOLDER_VOLTDB_CLUSTER_HOST~${VDB_HOST_NODE}~" \
			-e "s~\PLACEHOLDER_VOLTDB_SSH_USER~${VDB_SSH_USER}~" \
			-e "s~\PLACEHOLDER_EIUM_VOLTDB_TOOL~${EIUM_VOLTDB_TOOL}~" \
			-e "s~\PLACEHOLDER_EIUM_HOME~${EIUM_HOME}~" \
			-e "s~\PLACEHOLDER_VDB_FLAG_NAME~${VDB_FLAG_NAME}~" \
			-e "s~\PLACEHOLDER_VOLTDB_HEAPMAX~${VOLTDB_HEAPMAX}~" \
			   "${DBI_TPL}/snap_vdb_shell.tmpl" > "${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh"

		if [ $? -eq 0 ]; then
			chmod +x ${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh
			echo "generated the ${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh successfully."
			
			return 0
		else
			echo "failed to generate the ${DBInstaller_DIR}/target/${DB_NAME}/snap_vdb_shell.sh."	
			return 1
		fi
    fi	

}

BIN_DIR="$(readlink -f $(dirname $0))"
DBInstaller_DIR="$(cd "$BIN_DIR/.."; echo $PWD)"
DBI_TPL="${DBInstaller_DIR}/template"

for DIR_NAME in `ls ${DBInstaller_DIR}/target 2>/dev/null`; do 
	 genVDBShell "${DIR_NAME}"
	 RESULT=$?
	 if [ $RESULT -ne 0 ]; then
	     exit $RESULT
	 fi
done
