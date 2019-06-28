#!/bin/bash


threadAliveDB=0
threadDeadDB=0
runningNode=0
stoppedNode=0

VDB_SSH_USER=$USER

SNAPTMD=/tmp

procedureStatus=$PWD/.procedureStatus.log

SCRIPT_DIR=$(dirname "$0");

EIUM_INSTALLATION_INI=$SCRIPT_DIR/../../../../siu_install.ini
if [ ! -f $EIUM_INSTALLATION_INI ]; then
    echo " The $EIUM_INSTALLATION_INI file does not exist!"
	exit 1
fi
EIUM_HOME=`cat $EIUM_INSTALLATION_INI | grep "SiuRoot" | cut -d'=' -f2 `
VDB_JAVA_HOME=`cat $EIUM_INSTALLATION_INI | grep "JDKHome" | cut -d'=' -f2 | cut -d / -f 1-4 `
VDB_HOME=$2
DBI_HOME="$SCRIPT_DIR/../"
DBI_LIB="$DBI_HOME/lib"

export EIUM_VOLTDB_TOOL="$DBI_HOME../vdbtool"

CLASSPATH=.:$EIUM_VOLTDB_TOOL:${EIUM_HOME}/lib/datastruct-api.jar:
CLASSPATH=${CLASSPATH}`find "${EIUM_HOME}/lib" -name '*.jar'|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "${EIUM_VOLTDB_TOOL}/lib" -name '*.jar'|grep -v org.slf4j.slf4j-log4j12.jar|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "${DBI_LIB}" -name '*.jar'|tr '\n' :`

	
dbListFile=$VDB_HOME/.database.ini


DATABASE_INFO=
START_HOST=
DEPLOYMENT_FILE_PATH=`cat $EIUM_INSTALLATION_INI | grep "VarRoot" | cut -d'=' -f2 `"/voltdb/dbs/"


function checkServerThread
{	
	
	threadAliveDB=0
	threadDeadDB=0
	serversThreadStatus=""
	serversThreadStatus=$serversThreadStatus$1"\n"
	serversThreadStatus=$serversThreadStatus"Server			Status\n"
 
	#loop server list, exit the function when query successfully
	for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
		if [ "x$server" = "x" ]; then
			continue
		fi
		
		singleServer=`echo $server|awk -F / '{print $1}'`
		IHOST=`echo $server | awk -F/ '{print $2}'`
		PHOST=`echo $server | awk -F/ '{print $3}'`
		
		#test ssh connection
		`ssh -o BatchMode=yes -o PasswordAuthentication=no -nq $VDB_SSH_USER@$singleServer echo hello 2>&1 > /dev/null`
		if [ "$?" != "0" ];then
			echo "ssh connection not work for $singleServer, please check ssh connection."
			exit 1
		fi
		
		queryServerThread $singleServer $voltdb_internal_port $IHOST
	done
}

function rejoinDB
{
	VOLTDBTMD="$SNAPTMD/vdb_tool.$$"
	mkdir -p $VOLTDBTMD
	for servers in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
			     
		server=`echo $servers | awk -F/ '{print $1}'`
		IHOST=`echo $servers | awk -F/ '{print $2}'`
		PHOST=`echo $servers | awk -F/ '{print $3}'`
		#check server status is dead or not, if alive skip the start
		checkDead=`echo -e $serversThreadStatus | grep $server | grep Dead`
		if [ "x$checkDead" == "x" ]; then
			echo "$server not in dead list, skip"
			continue
		fi
		
		if [ "x$START_HOST" == "x" ]; then
			if [ "x$IHOST" == "x" ]; then
				START_HOST=$server
			else
				START_HOST=$IHOST
			fi    
		fi
		
		echo "start node $server"
				 
		echo "" > ${VOLTDBTMD}/voltdb_start_$$.sh
		echo "export JAVA_HOME=$VDB_JAVA_HOME " >> ${VOLTDBTMD}/voltdb_start_$$.sh
		echo "export PATH=$JAVA_HOME/bin:$PATH  " >> ${VOLTDBTMD}/voltdb_start_$$.sh
		echo "export LOG4J_CONFIG_PATH=${VOLTDBTMD}/voltdb_log4j.xml" >> ${VOLTDBTMD}/voltdb_start_$$.sh
		echo "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true\"" >> ${VOLTDBTMD}/voltdb_start_$$.sh
		#echo "export VOLTDB_OPTS=\"-Dvolt.rmi.agent.port=${voltdb_jmx_port}\"" >> ${VOLTDBTMD}/voltdb_start_$$.sh
		if [ $database_work_model == 'REPLICA' ]; then
			echo "${VDB_HOME}/bin/voltdb rejoin --replica --deployment=/${VOLTDBTMD}/deployment.xml --host=$START_HOST:$voltdb_internal_port --client=$voltdb_client_port --internal=$voltdb_internal_port  --replication=$voltdb_repl_port --zookeeper=$voltdb_zookeeper_port  --admin=$adminport --externalinterface=$server  --internalinterface=$IHOST --publicinterface=$PHOST -B 2>&1 > /${VOLTDBTMD}/voltdb_start.log" >> ${VOLTDBTMD}/voltdb_start_$$.sh
		else
			echo "${VDB_HOME}/bin/voltdb rejoin --deployment=/${VOLTDBTMD}/deployment.xml --host=$START_HOST:$voltdb_internal_port --client=$voltdb_client_port --internal=$voltdb_internal_port  --replication=$voltdb_repl_port --zookeeper=$voltdb_zookeeper_port  --admin=$adminport --externalinterface=$server  --internalinterface=$IHOST --publicinterface=$PHOST -B 2>&1 > /${VOLTDBTMD}/voltdb_start.log" >> ${VOLTDBTMD}/voltdb_start_$$.sh
		fi	
		ssh -nq ${VDB_SSH_USER}@${server} "mkdir -p ${VOLTDBTMD}"
		scp ${VOLTDBTMD}/voltdb_start_$$.sh ${VDB_SSH_USER}@${server}:/${VOLTDBTMD} 2>&1 > /dev/null
		scp ${DBI_HOME}target/$1/voltdb_log4j.xml ${VDB_SSH_USER}@${server}:/${VOLTDBTMD} 2>&1 > /dev/null
		scp $2/deployment.xml ${VDB_SSH_USER}@${server}:/${VOLTDBTMD} 2>&1 > /dev/null
		ssh -nq ${VDB_SSH_USER}@${server} "chmod +x /${VOLTDBTMD}/voltdb_start_$$.sh"
		ssh -nq ${VDB_SSH_USER}@${server} "sh /${VOLTDBTMD}/voltdb_start_$$.sh"
	done
	echo
	echo
	cnt=1
	while [ $cnt -lt 30 ]; do
		echo "Checking the $1 status ......"
        $VDB_HOME/bin/sqlcmd --servers=$server --port=$adminport --user=$adminuser --password=$adminpwd --query="exec @SystemInformation overview" 2>&1 > /dev/null
	    
        if [ $? -eq 0 ]; then
			echo
			return 0
        fi
        cnt=$((cnt+1))
        sleep 10
    done
	echo "The $1 database failed to start, please contact database administrator."

}

function queryServerThread
{
	PID=`ssh -nq ${VDB_SSH_USER}@${1} "ps aux|grep $VDB_HOME|grep ${2}|grep -v grep|awk '{print \$2}'"`
	if [ "x$PID" != "x" ]; then
		let threadAliveDB+=1
		serversThreadStatus=$serversThreadStatus$1"		Alive\n"
	else
		let threadDeadDB+=1
		serversThreadStatus=$serversThreadStatus$1"		Dead\n"
	fi

}

function queryProcedureStatus
{
	echo "start query procedure"
	#loop server list, exit the function when query successfully
	for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
		if [ "x$server" = "x" ]; then
			continue
		fi
		singleServer=`echo $server|awk -F / '{print $1}'`
		`$VDB_HOME/bin/sqlcmd --servers=$singleServer --port=$voltdb_client_port --user=$adminuser --password=$adminpwd --query="exec @SystemInformation overview" > $procedureStatus`
		
		
		
		if [ "$?" = "0" ];then
			echo "query procedure successful"
			return 0
		fi
	done
	echo "query procedure failed"
	return 1
}

function checkProcedureStatus
{
	serversProcedureStatus=""
	serversProcedureStatus=$serversProcedureStatus$1"\n"
	serversProcedureStatus=$serversProcedureStatus"Server			Status\n"
	
	runningNode=0
	stoppedNode=0
	if [ ! -f "$procedureStatus" ]; then
		echo "$procedureStatus not exist"
		exit 1
	fi
	
	for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
		if [ "x$server" = "x" ]; then
			continue
		fi
		singleServer=`echo $server|awk -F / '{print $1}' `
		IHOST=`echo $server | awk -F/ '{print $2}'`
		#get host id
		status="STOPPED"
		hostId=`cat $procedureStatus|grep $singleServer|head -1|awk -F' '  '{print $1}'`
		if [ "x$hostId" != "x" ]; then
			#get status
			status=`cat $procedureStatus|grep CLUSTERSTATE|grep $hostId|awk -F' '  '{print $3}'`
		fi
		if [ "$status" = "STOPPED" ]; then
			status="STOPPED"
			let stoppedNode+=1
		else
			#recognize first running server as rejoin leader
			if [ "x$START_HOST" == "x" ]; then
				if [ "x$IHOST" != "x" ]; then 
					START_HOST=$IHOST
				else
					START_HOST=$singleServer
				fi
			fi
			let runningNode+=1
		fi
		serversProcedureStatus=$serversProcedureStatus$singleServer"		$status\n"
	done
}

function checkPID
{
	if [ ! -f "$1" ]; then
		#file not exist ,no script running
		return 0
	fi
	
	previsouPID=`cat $1`
	checkExist=`ps -p $previsouPID`
	if [ $? -eq 0 ]; then
		echo "there already have monitor script running, exit the script, PID is $previsouPID"
		exit 1
	fi
	
}


if [ "$1" = "spr_db" ]; then
	DEPLOYMENT_FILE_PATH=$DEPLOYMENT_FILE_PATH"spr/config_log"
elif [ "$1" = "session_db" ]; then
	DEPLOYMENT_FILE_PATH=$DEPLOYMENT_FILE_PATH"session/config_log"
else
	echo "Wrong parameter, usage $0 spr_db|session_db /opt/SIU_snap/VoltDB"
	exit 1
fi


if [ "x$2" = "x" ]; then
	echo "VDB instance fold is madantory"
	exit 1
fi
#check whether have another monitor script running
filePID="$PWD/.$1.pid"
checkPID $filePID

echo $$ > $filePID


#check file exist or not
if [ ! -f "$dbListFile" ]; then
	echo "$dbListFile not exist"
	exit 1
fi

echo "start monitor VDB status"
echo "$*"
echo "$(date '+%Y-%m-%d %H:%M:%S %z')"


DATABASE_INFO=`cat $dbListFile | grep $1`
adminport=`echo $DATABASE_INFO | awk '{print $5}'`
adminuser=`echo $DATABASE_INFO | awk '{print $12}'`
adminpwd=`echo $DATABASE_INFO | awk '{print $13}'`
datapath=`echo $DATABASE_INFO | awk '{print $3}'`  
hostList=`echo $DATABASE_INFO | awk '{print $2}'` 
voltdb_client_port=`echo $DATABASE_INFO | awk '{print $4}'`
voltdb_internal_port=`echo $DATABASE_INFO | awk '{print $7}'`
voltdb_repl_port=`echo $DATABASE_INFO | awk '{print $9}'`
#voltdb_jmx_port=`echo $DATABASE_INFO | awk '{print $9}'`
voltdb_zookeeper_port=`echo $DATABASE_INFO | awk '{print $8}'`
database_work_model=`echo $DATABASE_INFO | awk '{print $15}'`
adminpwd=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $adminpwd`



#init procedure file
echo "" > $procedureStatus


#db thread status check
checkServerThread $1
#db procedure status check
queryProcedureStatus
checkProcedureStatus $1

if [ "$threadAliveDB" -eq 0 ]; then
	#cluster down, start cluster
	${DBI_HOME}target/$1/snap_vdb_shell.sh start
	
	#recheck thread and procedure status
	checkServerThread $1
	queryProcedureStatus
	checkProcedureStatus $1
elif [ $threadDeadDB -eq 1 -a $stoppedNode -eq 1 ]; then
	#only one server down, start rejoin
	rejoinDB $1 $DEPLOYMENT_FILE_PATH
	echo "server rejoin done, maybe need more time for starting"
	
	#recheck thread and procedure status
	checkServerThread $1
	queryProcedureStatus
	checkProcedureStatus $1
elif [ $threadDeadDB -gt 0 -o $stoppedNode -gt 0 ]; then
	#print warning log
	echo "WARNING: VDB cluster has server down, please check VDB log for detail"
fi

if [ $runningNode -eq 0 ]; then
	echo "WARNING:VDB cluster still down, maybe need start VDB cluster by manually"
fi
echo "DB status monitor done"

echo -e "Thread status\n$serversThreadStatus"
echo -e "Procedure status\n$serversProcedureStatus"
echo -e "Total running DB $runningNode"
echo -e "Total stopped DB $stoppedNode"
echo "$(date '+%Y-%m-%d %H:%M:%S %z')"

rm $filePID
rm $procedureStatus
