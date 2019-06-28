#!/bin/bash
###############################################################################
#
# snap_db_installer.sh
#
# HP Subscriber, Network, and Policy Solution software (HP SNAP)
# Copyright 2012 - 2013 Hewlett-Packard Development Company, L.P.
#
# This tool creates/drops the SNAP databases
#
###############################################################################


SNAPNAM=$(basename "$0" ".sh")
SNAPDIR=$(dirname "$0")
if [[ "$(echo $SNAPDIR | cut -c1)" != "/" ]]; then SNAPDIR="$PWD/$SNAPDIR"; fi
SNAPDIR="$(cd "$SNAPDIR"; echo $PWD)";
SNAPLOG="${SNAPDIR}/${SNAPNAM}-$(date '+%Y%m%d%H%M%S').log"
rm -f $SNAPLOG && cat /dev/null > "$SNAPLOG" && chmod 660 "$SNAPLOG"

EIUM_INSTALLATION_INI=$SNAPDIR/../../../../siu_install.ini
if [ ! -f $EIUM_INSTALLATION_INI ]; then
    echo " The $EIUM_INSTALLATION_INI file does not exist!"
	exit 1
fi
EIUM_HOME=`cat $EIUM_INSTALLATION_INI | grep "SiuRoot" | cut -d'=' -f2 `
EIUM_PLUGIN=$EIUM_HOME/plugins
VAR_EIUM=`cat $EIUM_INSTALLATION_INI | grep "VarRoot" | cut -d'=' -f2 `
VOLTDB_HOME=$EIUM_HOME/VoltDB
MYSQL_HOME=$EIUM_HOME/mysql

TIMER_PLUGIN=com.hp.usage.timers_

#Warning: Please won't remove/modify below flag comment!!!!
##--REUSED PART BEGIN--

SNAPTMD=/tmp
SNAPTMP=$SNAPTMD/$SNAPNAM.$$.tmp
SNAPTM1=$SNAPTMD/$SNAPNAM.$$.tm1
SNAPTM2=$SNAPTMD/$SNAPNAM.$$.tm2
SNAPTM3=$SNAPTMD/$SNAPNAM.$$.tm3
SNAPTM4=$SNAPTMD/$SNAPNAM.$$.tm4
SNAPTM5=$SNAPTMD/$SNAPNAM.$$.tm5

PROCESS_NUM=$$

DBI_HOME="$(cd "$SNAPDIR/.."; echo $PWD)"
DBI_BIN="$DBI_HOME/bin"
DBI_SCRIPTS="$DBI_HOME/dbscripts"
DBI_TPL="$DBI_HOME/template"
DBI_CONF="$DBI_HOME/config"
DBI_LIB="$DBI_HOME/lib"

DATABASE_WORK_MODEL=none
# getProperty
# $1- content of properties file as string
# $2- property name
function getProperty
{
     
    PROP_VALUE=`echo "$1"|grep -w $2|cut -d'=' -f 2-`
    if [[ "$?" != "0" ]]; then
	    echo $?
        PROP_VALUE=""
    fi
    #echo "$2=$PROP_VALUE"
}

function checkMandatoryValue
{
     if [ $1 == "" ]; then
	     echo "The $2 value is mandatory!!"
		 exit 1
	 fi
}
# read common properties for db installation
# $1- content of properties file as string
function readCommonProperty
{
    # database type
	#echo "readCommonProperty is:"$1
    getProperty "$1" DATABASE_TYPE
    DATABASE_TYPE=$PROP_VALUE
	checkMandatoryValue $DATABASE_TYPE DATABASE_TYPE
	
	# database name
    getProperty "$1" DATABASE_NAME
    DATABASE_NAME=$PROP_VALUE
	checkMandatoryValue $DATABASE_NAME DATABASE_NAME
	
	# applications: ocs:abm
    #getProperty "$1" APPLICATIONS
    #APPLICATIONS=$PROP_VALUE
	#checkMandatoryValue $APPLICATIONS APPLICATIONS
}
# readProperty
# $1- content of properties file as string
function readVoltDBProperty
{
    
	#getProperty "$1" VOLTDB_HTTPLISTEN_ADDRESS
    #VOLTDB_HTTPLISTEN_ADDRESS=$PROP_VALUE
	
	#getProperty "$1" VOLTDB_VEM_PORT
    #VOLTDB_VEM_PORT=$PROP_VALUE
	
	#voltdb Java Home
	getProperty "$1" VOLTDB_JAVA_HOME
    VOLTDB_JAVA_HOME=$PROP_VALUE
	
	# voltdb source list for replication 
	getProperty "$1" VOLTDB_DR_SOURCE
    VOLTDB_DR_SOURCE=$PROP_VALUE
	
	# voltdb DR ID
	getProperty "$1" VOLTDB_DR_ID
    VOLTDB_DR_ID=$PROP_VALUE
	
    #echo "readVoltDBProperty is:"$1
    # true - Only generate/drop catalog and deployment file; false - Generate/drop catalog and deployment file and create/drop the database as well
    getProperty "$1" ONLY_DEPLOYMENT_OPERATION
    ONLY_DEPLOYMENT_OPERATION=$PROP_VALUE

    # voltdb instance name
    getProperty "$1" VOLTDB_INSTANCE_NAME
    VOLTDB_INSTANCE_NAME=$PROP_VALUE

	# voltdb admin user
    getProperty "$1" VOLTDB_ADMIN_USERNAME
    VOLTDB_ADMIN_USERNAME=$PROP_VALUE
	
	# voltdb admin passord
    getProperty "$1" VOLTDB_ADMIN_PASSWORD
    VOLTDB_ADMIN_PASSWORD=$PROP_VALUE
	
    # voltdb user name
    getProperty "$1" VOLTDB_USER_NAME
    VOLTDB_USER_NAME=$PROP_VALUE
    

    # voltdb user password
    getProperty "$1" VOLTDB_USER_PASSWORD
    VOLTDB_USER_PASSWORD=$PROP_VALUE

	# voltdb k-factor
    #getProperty "$1" VOLTDB_KFACTOR
    #VOLTDB_KFACTOR=$PROP_VALUE

	# voltdb sites perHost
    getProperty "$1" VOLTDB_SITES_PER_HOST
    VOLTDB_SITES_PER_HOST=$PROP_VALUE
	
	getProperty "$1" VOLTDB_EXPORT_ROLL_PERIOD
	VOLTDB_EXPORT_ROLL_PERIOD=$PROP_VALUE
    
	# (true - Only generate database without cluster node; false - Generate VoltDB database and add cluster node in it as well, default value is false), # # if the property value is true, then two properties(VOLTDB_HOST_LIST,VOLTDB_SSH_USER) will be skiped;
    #getProperty "$1" VOLTDB_WITHOUT_CLUSTER_NODE
    #VOLTDB_WITHOUT_CLUSTER_NODE=$PROP_VALUE
	
	# if VOLTDB_WITHOUT_CLUSTER_NODE=true, the property can be ignored
	getProperty "$1" VOLTDB_NODE_LIST
    VOLTDB_NODE_LIST=$PROP_VALUE
	
	# if VOLTDB_WITHOUT_CLUSTER_NODE=true, the property can be ignored
	#getProperty "$1" VOLTDB_SSH_USER
    #VOLTDB_SSH_USER=$PROP_VALUE
	
	# voltdb root path
	getProperty "$1" VOLTDB_ROOT_PATH
    VOLTDB_ROOT_PATH=$PROP_VALUE
	
	# voltdb client port
	getProperty "$1" VOLTDB_CLIENT_PORT
    VOLTDB_CLIENT_PORT=$PROP_VALUE

	# voltdb admin port
	getProperty "$1" VOLTDB_ADMIN_PORT
    VOLTDB_ADMIN_PORT=$PROP_VALUE
	
	# voltdb http port
	getProperty "$1" VOLTDB_HTTP_PORT
    VOLTDB_HTTP_PORT=$PROP_VALUE
	
	# voltdb internal port
	getProperty "$1" VOLTDB_INTERNAL_PORT
    VOLTDB_INTERNAL_PORT=$PROP_VALUE
    
	# voltdb jmx port
	#getProperty "$1" VOLTDB_JMX_PORT
    #VOLTDB_JMX_PORT=$PROP_VALUE
	
	# voltdb log port
	#getProperty "$1" VOLTDB_LOG_PORT
    #VOLTDB_LOG_PORT=$PROP_VALUE
	
	# voltdb zookeeper port
	getProperty "$1" VOLTDB_ZOOKEEPER_PORT
    VOLTDB_ZOOKEEPER_PORT=$PROP_VALUE
	
	# voltdb replication port
	getProperty "$1" VOLTDB_REPLICATION_PORT
    VOLTDB_REPLICATION_PORT=$PROP_VALUE
	
	# voltdb start port
	#getProperty "$1" VOLTDB_START_PORT
    #VOLTDB_START_PORT=$PROP_VALUE
	
	# voltdb working model
	getProperty "$1" VOLTDB_WORK_MODEL
	VOLTDB_WORK_MODEL=$PROP_VALUE
	
	# voltdb heap max
	getProperty "$1" VOLTDB_HEAPMAX
	VOLTDB_HEAPMAX=$PROP_VALUE
	
	getProperty "$1" VOLTDB_PLACEMENT_GROUPS
	VOLTDB_PLACEMENT_GROUPS=$PROP_VALUE
}

function readMySQLProperty
{
    # mysql home directory
    getProperty "$1" MYSQL_HOME_DIRECTORY
    MYSQL_HOME_DIRECTORY=$PROP_VALUE
   
   # mysql database port
    getProperty "$1" MYSQL_DATABASE_HOST
    MYSQL_DATABASE_HOST=$PROP_VALUE
	
    # mysql database port
    getProperty "$1" MYSQL_DATABASE_PORT
    MYSQL_DATABASE_PORT=$PROP_VALUE

    # mysql database dba username
    getProperty "$1" MYSQL_DATABASE_DBA_USERNAME
    MYSQL_DATABASE_DBA_USERNAME=$PROP_VALUE
    

    # mysql database dba password
    getProperty "$1" MYSQL_DATABASE_DBA_PASSWORD
    MYSQL_DATABASE_DBA_PASSWORD=$PROP_VALUE

	# mysql database name
    getProperty "$1" MYSQL_DATABASE_NAME
    MYSQL_DATABASE_NAME=$PROP_VALUE
	
	# mysql database username
    getProperty "$1" MYSQL_DATABASE_USERNAME
    MYSQL_DATABASE_USERNAME=$PROP_VALUE
	
	# mysql database user password
    getProperty "$1" MYSQL_DATABASE_PASSWORD
    MYSQL_DATABASE_PASSWORD=$PROP_VALUE
}

function snapWriteLog
{
    echo "$*"
    echo "$(date '+%Y-%m-%d %H:%M:%S %z') | $*" >>"$SNAPLOG"
    return 0
}

export COMMON="Base System"
export ABM="Account Balance Management System (ABM)"
export ABM_SIMULATOR="ABM Simulator (ABM Simulator)"
export OCS="Online Charging System (OCS)"
export OFCS="Offline Charging System (OFCS)"
export RRS="Re-Rating System (RRS)"
export SFRE="Stateful Rating System (SFRE)"
export SLRE="Stateless Rating System (SLRE)"
export LB="SNAP Load Balance System (LB)"
export SPR_PROXY="SPR Proxy (SPR Proxy)"
export MNF="Message Notification Framework (MNF)"
export STUDIO="SNAP Studio (Studio)"


export RTC_HOME=${DBI_HOME}/../../
export RTP_HOME=${EIUM_HOME}/RTP
#export EIUM_VOLTDB_TOOL=${RTP_HOME}/virgo/tools/vdbtool
export EIUM_VOLTDB_TOOL=${RTC_HOME}/tools/vdbtool

#######################################################################
function snapUsage ()
{
    cat <<EOF

This tool used to create/drop databases for snap applications

  Usage: $SNAPNAM [-uhs] [properties file]

   where:
     -h                   : [OPTIONAL]  display this usage. Default: not active
     -u                   : [OPTIONAL]  mode to uninstall database. Default: not active 
	 -s [properties file]   : [OPTIONAL]  database silent installation, properties fie is the installation of pre-configured parameters. Deault: not active
EOF
}

#######################################################################

function snapEcho
{
    echo "$*" 
}

function snapEchoLog
{
    echo "$(date '+%Y-%m-%d %H:%M:%S %z') | $*" >>"$SNAPLOG"
}

function getDisplayInfo
{
   
   SNAP_MENU_INFO_CNT=1;
   SNAP_MENU_DIS_NAME=`echo $1|awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}'|while read opt; do  
        if [ $2 = $SNAP_MENU_INFO_CNT ];
		then 
		   echo $opt
		fi   
        SNAP_MENU_INFO_CNT=$((SNAP_MENU_INFO_CNT + 1))
    done`
}

#######################################################################
function snapExit
{
    if [ $debug -eq 0 ]; then
	   rm -f $SNAPTMP $SNAPTM1 $SNAPTM2 $SNAPTM3 $SNAPTM4 $SNAPTM5 
       rm -rf $VOLTDBTMD
       unset SNAPTPH SNAPTMP SNAPTM1 SNAPTM2 SNAPTM3 SNAPTM4 SNAPTM5
	fi
    snapWriteLog
	snapWriteLog "DB operation fail!"
	echo ""
    echo "This script is terminated, and output log is in file '$SNAPLOG'."
    snapWriteLog
    exit 1
}

#######################################################################
function snapContinue
{
    echo ""
    SNAPAGR=
    while [[ -z "$SNAPAGR" ]]; do
        read -p "  $1  Do you want to continue? [yes or no]: " SNAPANS SNAPRST
        case $SNAPANS in
            [yY] | [yY][eE][sS])
                SNAPAGR=1
                ;;
            [nN] | [nN][oO])
                unset SNAPAGR SNAPANS SNAPRST
                snapExit
                ;;
        esac
    done
    unset SNAPAGR SNAPANS SNAPRST
}

#######################################################################
function snapEditValue
{
    SNAPOK=
    while [[ -z "$SNAPOK" ]]
    do
        echo
        echo "$1"
        read -p "    Accept current value or enter new value [$2]: " SNAPANS
        if [[ "x$SNAPANS" = "x" ]]
        then
            SNAPANS="$2"
        fi
        if [[ "$(echo "$SNAPANS" | tr -d [:cntrl:])" != "$SNAPANS" ]]
        then
            snapWriteLog "    Value cannot contain control characters."
        else
            if [[ "x$SNAPANS" = "x" ]]
            then
                snapWriteLog "    Value cannot be empty."
            else
                SNAPOK=1
            fi
        fi
    done
    eval $3=\"$SNAPANS\"
    unset SNAPOK SNAPANS
}

######################################################################
function snapEditPassword
{
    SNAPOK=
    while [[ -z "$SNAPOK" ]]
    do
        echo
        echo "$1"
        read -p "    Accept current value or enter new value [******] " SNAPANS
        if [[ "x$SNAPANS" = "x" ]]
        then
            SNAPANS="$2"
        fi
        if [[ "$(echo "$SNAPANS" | tr -d [:cntrl:])" != "$SNAPANS" ]]
        then
            snapWriteLog "    Value cannot contain control characters."
        else
            if [[ "x$SNAPANS" = "x" ]]
            then
                snapWriteLog "    Value cannot be empty."
            else
                SNAPOK=1
            fi
        fi
    done
    eval $3=\"$SNAPANS\"
    unset SNAPOK SNAPANS
}

#######################################################################
function snapEditPort
{
    echo
    echo "$1"

    SNAPOK=
    while [[ -z "$SNAPOK" ]]
    do
        read -p "    Accept current port or enter new one [$2]: " SNAPANS
        if [[ "x$SNAPANS" = "x" ]]
        then
            SNAPANS="$2"
        fi
        if [[ "$(echo "$SNAPANS" | tr -d [:cntrl:])" != "$SNAPANS" ]]
        then
            snapWriteLog "    Value cannot contain control characters."
        else
            if [[ $SNAPANS -lt 0 || $SNAPANS -gt 65535 ]]; then
                snapWriteLog "    Port value shall be in the range [0-65535]."
                continue  
            fi
        fi
        
        # Validate the port
		if [[ "$IS_ONLY_GENERATE_CATALOG" = "false" ]]; then 
            netstat -nlp 2>&1 |grep -w $SNAPANS > /dev/null
            if [ "$?" != 0 ]; then
                SNAPOK=1
            else
                snapWriteLog "    Given port $SNAPANS is used by other processes, please give a right one."
            fi
		else
		     SNAPOK=1
		fi
    done
    eval $3=\"$SNAPANS\"
    unset SNAPOK SNAPANS
}

#######################################################################
function snapCheckDir
{
    if [[ ! -d "$1" ]]
    then
        mkdir -p "$1"
    fi
}

###############################################################################
# Show snap menu in the universal format, $1 as sub title and $2 as menu options
function snapShowMenu
{
    snapEcho
    snapEcho "$1:"
    snapEcho
    snapEcho "      0. Exit"
    SNAP_MENU_CNT=1;
    echo $2|awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}'|while read opt; do  
        snapEcho "      ${SNAP_MENU_CNT}. ${opt}";
        SNAP_MENU_CNT=$((SNAP_MENU_CNT + 1))
    done
    SNAP_MENU_CNT=`echo $2|awk 'BEGIN{FS=":"} END{ print NF}'`
}

###############################################################################
# Choose right database name from 1 to 4, 0 to exit
function makeDBNameChoice
{
    # Show snap database name selector menu
    sub_title="Please enter your database name choice"   
 #   options="SNAP DB (snapDB):SPR DB (sprDB):Session DB (sessionDB):LB DB (lbDB)"
	options="SNAP DB (snapDB):SPR DB (sprDB):Session DB (sessionDB)"
    if [ -d "$DBI_SCRIPTS/cdr_db" ]; then 
        options="$options:CDR DB (cdrDB)"
    fi
    snapShowMenu "$sub_title" "$options"

    DBNAGR=
    while [[ -z "$DBNAGR" ]]
    do
        read -p "    Choose your database name: " DB_NAME
        if [[ "$DB_NAME" = "0" ]] ; then
            snapExit
        fi
        if [[ $DB_NAME -le $SNAP_MENU_CNT && $DB_NAME -gt 0 ]] ; then
            DBNAGR=1 
            getDisplayInfo "$options" "$DB_NAME"
            snapEchoLog "Chosen database name: [$SNAP_MENU_DIS_NAME]" 
        fi
    done
    unset DBNAGR
}

################################################################################
# choose voltdb database model:
#             No replication database
#             Passive DR - Master database
#             Passive DR - Replica database
#             Cross DR - Active database
function selectVoltDBWorkModel
{
    sub_title="Please enter your voltdb working model"
	options="No duplication database:Passive DR - Master database:Passive DR - Replica database:Cross DR - Active database"
	snapShowMenu "$sub_title" "$options"
	VoltModel=
	while [[ -z $VoltModel ]]
	do
	    read -p "    Choose your voltdb database model:" DB_MODEL
		if [[ "$DB_MODEL" = "0" ]]; then
		    snapExit
		fi
		if [[ $DB_MODEL -le $SNAP_MENU_CNT && $DB_MODEL -gt 0 ]] ; then
            VoltModel=1 
            getDisplayInfo "$options" "$DB_MODEL"
            snapEchoLog "Chosen voltdb database model: [$SNAP_MENU_DIS_NAME]" 
        fi
	done
	unset VoltModel
}

#################################################################################
## find config db name in silent installation
function findConfigDBName
{
    DB_NAME=
    REAL_NAME=$1
    case $REAL_NAME in
        snap_db) DB_NAME=1;;
	    spr_db) DB_NAME=2;;
	    session_db) DB_NAME=3;;
#	    lb_db) DB_NAME=4;;
#	    cdr_db) DB_NAME=5;;
	    *) echo "Invaild database name";;
     esac
     snapEchoLog "chooed DB NAME is:"$DB_NAME	
}

###############################################################################
# Choose db type from 1 to 2, 0 to exit
function makeDBTypeChoice
{
    sub_title="Please enter your database choice"
    case "$DB_NAME" in
        1 | 5) # means snap_db,cdr_db
		    dbTypeOption="MySQL"
            snapShowMenu "$sub_title" "MySQL" ;;
        2 | 3 | 4) # means spr_db, session_db, lb_db
		    dbTypeOption="VoltDB"
            snapShowMenu "$sub_title" "VoltDB" ;;
        * )
            echo "Invalid choice" ;;
    esac

    DBTAGR=
    while [[ -z "$DBTAGR" ]]
    do
        read -p "    Choose your database type: " DB_TYPE
        if [[ "$DB_TYPE" = "0" ]] ; then
            snapExit
        fi
        if [[ $DB_TYPE -le $SNAP_MENU_CNT ]] ; then
            DBTAGR=1 
            getDisplayInfo "$dbTypeOption" "$DB_TYPE"
            #snapWriteLog "Chosen database type: [$DB_TYPE]" 
            snapWriteLog "Chosen database type: [$SNAP_MENU_DIS_NAME]" 
        fi
    done
    unset DBTAGR
}

function findDBType
{
    DB_TYPE=
    case $1 in
        Mysql|mysql) if [ $DB_NAME == 1 -o $DB_NAME == 5 ]; then
                              DB_TYPE=1		 
				         fi;;
        Voltdb|voltdb|VoltDB) if [ $DB_NAME == 2 ]; then
                              DB_TYPE=1
				          elif [ $DB_NAME == 3 -o $DB_NAME == 4 ]; then
                               DB_TYPE=1	 
				           fi;;					  
           *) echo "Invaild DB Type";;
       esac
       snapWriteLog "chooed DB type is:"$DB_TYPE 
}
###############################################################################
# Choose right application from 1 to 4, 7 to exit
function makeAppChoice
{
    L_APPS=$1
    sub_title="Please enter your application choice"
    confirm_title="Confirm Current Choices"

    # transform the right menu options
    getAppMenuOpts "${L_APPS}"

    case "$DB_NAME" in
        1 | 2 | 3 | 4 | 5 | 6)
            snapShowMenu "$sub_title" "${MENU_OPTS}:${confirm_title}"
            ;;
        * )
            echo "Invalid choice";;
    esac

    DSTAGR=
    CHOSED=1
    while [[ -z "$DSTAGR" ]]
    do
        read -p "    Choose your applications, [$CHOSED]: " APP_MODE
        if [ "x$APP_MODE" = "x" ]; then
            APP_MODE=1
        fi
        if [[ "$APP_MODE" = "0" ]] ; then
            snapExit
        fi
        if [[ "$APP_MODE" = "$SNAP_MENU_CNT" && "x$CHOSED" != "x" ]] ; then
            DSTAGR=1
            snapWriteLog "Chosen applications: ${CHOSED_APPS[@]}"
        fi
        if [[ $APP_MODE -lt $SNAP_MENU_CNT && $APP_MODE -gt 0 ]] ; then
            echo "${CHOSED}" | grep "$APP_MODE" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                CHOSED=`echo "$CHOSED $APP_MODE"|sed 's/^[ \t]*//g'`    
                chosed_app=`echo $L_APPS|awk 'BEGIN{FS=":"}END{print $'$APP_MODE'}'`
                CHOSED_APPS=(${CHOSED_APPS[@]} "${chosed_app}")
            fi
        fi
    done
	#echo "==============done CHOSED_APPS:"${CHOSED_APPS[@]}
    unset DSTAGR
}

#######################################################################
function createCacheTBS
{
    # get data file path
    DBFILE_PATH="$SNAP_DBFILE_PATH"
	if [ $silent -ne 1  ]; then
         snapEditValue "  * Directory for save cache user data file" "$DBFILE_PATH" "DBFILE_PATH"
		 snapContinue
	fi

    

    snapCheckDir $DBFILE_PATH
    DBFILE=\'$DBFILE_PATH/SNAP_${SNAP_CACHE_USER}_DAT.dbf\'

    # create table space
    snapWriteLog "INFO: Create cache user tablespace cachetblsp ..."
    "$ORACLE_HOME/bin/sqlplus" /NOLOG << EOF >>"$SNAPLOG" 2>&1
    spool $SNAPTM1
    CONNECT / AS SYSDBA;
    CREATE TABLESPACE cachetblsp DATAFILE $DBFILE SIZE 100M;
    select 'count='||count(*) from dba_data_files where TABLESPACE_NAME = 'CACHETBLSP' or TABLESPACE_NAME='cachetblsp';
    spool off
    quit;
EOF

    # check if create success or not.
    typeset -i TBSCNT
    TBSCNT=`grep ^count ${SNAPTM1} | head -1 | cut -d= -f2`
    if [ "$TBSCNT" = "1" ]; then
        snapWriteLog "INFO: Cache user tablespace cachetblsp successfully created!"
    else
        snapWriteLog "ERROR: Cache user tablespace cachetblsp failed to be created!"
        snapExit
    fi
}

#######################################################################
function checkCacheTBS
{
    "$ORACLE_HOME/bin/sqlplus" /NOLOG << EOF >>"$SNAPLOG" 2>&1
    spool $SNAPTM1
    CONNECT / AS SYSDBA;
    select 'count='||count(*) from dba_data_files where TABLESPACE_NAME = 'CACHETBLSP' or TABLESPACE_NAME='cachetblsp';
    spool off
    quit;
EOF
    typeset -i TBSCNT
    TBSCNT=`grep ^count ${SNAPTM1} | head -1 | cut -d= -f2`
    rm -f ${SNAPTM1}
    if [ "$TBSCNT" = "0" ]; then
        createCacheTBS
    else
        if [ $silent -ne 1 ]; then
          snapContinue
        fi		
    fi
}


#--------------------------------------------------
# Call VEM Restuful API.
# $1- Http method: 1, 2, 3, 4 means GET/PUT/POST/DELETE
# $2- Restful path
# $3- JSON Data
function RestExec 
{

    case $1 in
        1) snapEchoLog "curl -X GET -sw \"http_code=%{http_code}\" \"$MGTHOST/api/1.0$2\""  
           RET=$(curl -X GET -sw "http_code=%{http_code}" "$MGTHOST/api/1.0$2")
           ;;    
        2) snapEchoLog "curl -X PUT -sw \"http_code=%{http_code}\" \"$MGTHOST/api/1.0$2\"" 
           RET=$(curl -X PUT -sw "http_code=%{http_code}" "$MGTHOST/api/1.0$2");;               
        3) snapEchoLog "curl -L -sw \"http_code=200\" -d \"@$3\" \"$MGTHOST/api/1.0$2\" | grep -oP \"(?<=\"id\"\:)[0-9]+\""   
           RET=$(curl -L -sw "http_code=200" -d "@$3" "$MGTHOST/api/1.0$2" | grep -oP '(?<="id"\:)[0-9]+') 
           ;;
        4) snapEchoLog "curl -X DELETE -sw \"http_code=%{http_code}\" \"$MGTHOST/api/1.0$2\"" 
           RET=$(curl -X DELETE -sw "http_code=%{http_code}" "$MGTHOST/api/1.0$2");;    
        *) Invalid option [$1];
    esac
	
    echo $RET|grep "http_code=[200|202]" 2>&1 >/dev/null
    if [[ $? -ne 0 && $1 -ne 3 ]]; then
        #echo "Call Restful URL [$MGTHost/man/api/1.0$2] failed." >> $SNAPLOG
		snapWriteLog "Call Restful URL [$MGTHost/man/api/1.0$2] failed."
		snapExit
        #return 1
    else
        echo "$RET"
    fi
}

#--------------------------------------------------
# $1-property file, $2- property name, like IsEmbeddedVEM
function getVarInPropertyFile
{
    propValue=`grep $2 $1|cut -d= -f2 2>/dev/null`
    echo $propValue
}

##############################################################################
# check the transparent hugepage
function prepareCheckHugepage
{
    chk_user=$1
	chk_host=$2
	snapWriteLog ""
	snapWriteLog "Check transparent hugepage in [$chk_host]"
	
    existFile=`ssh $chk_user@$chk_host "ls /sys/kernel/mm/transparent_hugepage/enabled 2>&1 > /dev/null"`
	if [ $? -eq 0 ]; then
	    NEVER=`ssh $chk_user@$chk_host "cat /sys/kernel/mm/transparent_hugepage/enabled" | grep -i "\[never\]"`
	   if [ $? -ne 0 ]; then
	       snapWriteLog "ERROR: [$chk_host] The kernel is configured to use transparent huge pages (THP). This is not supported when running VoltDB. Use the following commands to disable this feature for the current session:"
		   snapWriteLog "ERROR:"
		   snapWriteLog "ERROR: sudo bash -c \"echo never > /sys/kernel/mm/transparent_hugepage/enabled\""
		   snapWriteLog "ERROR: sudo bash -c \"echo never > /sys/kernel/mm/transparent_hugepage/defrag\""
		   snapWriteLog "ERROR:"
		   snapExit
	   fi
   fi
   
   existFile=`ssh $chk_user@$chk_host "ls /sys/kernel/mm/transparent_hugepage/defrag 2>&1 > /dev/null"`
	if [ $? -eq 0 ]; then
	    NEVER=`ssh $chk_user@$chk_host "cat /sys/kernel/mm/transparent_hugepage/defrag" | grep -i "\[never\]"`
	   if [ $? -ne 0 ]; then
	       snapWriteLog "ERROR: [$chk_host] The kernel is configured to use transparent huge pages (THP). This is not supported when running VoltDB. Use the following commands to disable this feature for the current session:"
		   snapWriteLog "ERROR:"
		   snapWriteLog "ERROR: sudo bash -c \"echo never > /sys/kernel/mm/transparent_hugepage/enabled\""
		   snapWriteLog "ERROR: sudo bash -c \"echo never > /sys/kernel/mm/transparent_hugepage/defrag\""
		   snapWriteLog "ERROR:"
		   snapExit
	   fi
   fi
}

###############################################################################
# check VoltDB environment 
function checkVoltDBEnv
{  
   DB_INSTANCE_NAME=$1
   
   VOLTDBTMD="$SNAPTMD/voltdb.$$"
   snapCheckDir $VOLTDBTMD
   
   # check ttisql
   if [[ ! -f "$VOLTDB_HOME/bin/voltdb"  ]]; then
       snapWriteLog "ERROR:  VOLTDB home doesn't correctly set in Environment variable:"
       snapWriteLog "       VOLTDB_HOME=$VOLTDB_HOME"
       snapExit
   fi
   
   if [ $uninstall -ne 1  ]; then
		if [ $silent -eq 1  ]; then
			   if [ -z $VOLTDB_JAVA_HOME ]; then
				   VOLTDB_JAVA_HOME=$JAVA_HOME
			   fi
			   VOLTDB_JAVA_HOME=$VOLTDB_JAVA_HOME
			   if [ -z $VOLTDB_HEAPMAX ]; then
				   VOLTDB_HEAPMAX=2048
			   fi
			   VOLTDB_HEAPMAX=$VOLTDB_HEAPMAX
		else
			   snapEditValue "  * VoltDB JAVA HOME(Java 8)" "$JAVA_HOME" "VOLTDB_JAVA_HOME"
			   VOLTDB_HEAPMAX=2048
			   snapEditValue "  * The maximum heap size for the Java process(megabytes)" "$VOLTDB_HEAPMAX" "VOLTDB_HEAPMAX"
		 fi
	else
        if [ $auto_uninstall -eq 1  ]; then
	       if [ -z $VOLTDB_JAVA_HOME ]; then
		       VOLTDB_JAVA_HOME=$JAVA_HOME
		   fi
        else
	        snapEditValue "  * VoltDB JAVA HOME(Java 8)" "$JAVA_HOME" "VOLTDB_JAVA_HOME"
        fi
	fi
	
	export JAVA_HOME=$VOLTDB_JAVA_HOME
	export PATH=$JAVA_HOME/bin:$PATH

	TMP_DEPLOYMENT="${DBI_CONF}/voltdb_log4j.xml"
    sed -e "s~\$PLACEHOLDER_VAR_EIUM_HOME~$VAR_EIUM~" \
        -e "s~\$PLACEHOLDER_DB_NAME~$DB_INSTANCE_NAME~" \
        ${TMP_DEPLOYMENT} > "${VOLTDBTMD}/voltdb_log4j.xml"
	export LOG4J_CONFIG_PATH=${VOLTDBTMD}/voltdb_log4j.xml	
		
	
   if [[ ! -f "$JAVA_HOME/bin/java"  ]]; then
       snapWriteLog "ERROR:  JAVA home doesn't correctly set in Environment variable:"
       snapWriteLog "       JAVA_HOME=$JAVA_HOME"
       snapExit
   fi

   if [[ ! -d "$EIUM_VOLTDB_TOOL"  ]]; then
       snapWriteLog "ERROR: RTC home directory doesn't correctly set in Environment variable:"
       snapWriteLog "       RTC_HOME=$RTC_HOME"
       snapExit
   fi


   if [ $uninstall -ne 1  ]; then
	   if [ $DB_MODEL -ne 1 ]; then
		   DR_ID=1
		   if [ $silent -eq 1  ]; then
			   if [ -z $VOLTDB_DR_ID ]; then
				   DR_ID=1
			   fi
			   DR_ID=$VOLTDB_DR_ID
		   else
			   snapEditValue "  * VoltDB DR ID (0~127)" "$DR_ID" "DR_ID"
		   fi
	   fi
	   
	   echo
	   if [ $DB_MODEL -eq 3 -o $DB_MODEL -eq 4 ]; then
		   DR_SOURCE_NODES_LST=""
		   if [ $silent -eq 1  ]; then
			   if [ -z $VOLTDB_DR_SOURCE ]; then
				   DR_SOURCE_NODES_LST=""
			   fi
			   DR_SOURCE_NODES_LST=$VOLTDB_DR_SOURCE
		   else
			   while [ "x$DR_SOURCE_NODES_LST" == "x" ]; do
				   read -p "  * Input the DR source node list in format '<source host>:[<replication port>,...]':" DR_SOURCE_NODES_LST
			   done
		   fi
	   fi
   fi
   
   IS_ONLY_GENERATE_CATALOG="false"
   if [ $silent == 1 -o $auto_uninstall == 1 ]; then
       if [ -z $ONLY_DEPLOYMENT_OPERATION ]; then
	        ONLY_DEPLOYMENT_OPERATION="false"
	   fi
       IS_ONLY_GENERATE_CATALOG=$ONLY_DEPLOYMENT_OPERATION
   elif [ $uninstall -ne 1 ]; then 
       snapEditValue "  * VoltDB installation option: (true - Only generate/drop catalog and deployment file; false - Generate/drop catalog and deployment file and create/drop the database as well)" "$IS_ONLY_GENERATE_CATALOG" "IS_ONLY_GENERATE_CATALOG"
   fi
   
   
   IS_ONLY_GENERATE_CATALOG=$(echo "$IS_ONLY_GENERATE_CATALOG"|tr [:upper:] [:lower:])

   if [[ "$IS_ONLY_GENERATE_CATALOG" = "false" ]]; then 
       base64 --version >/dev/null
       if [ $? -ne 0 ]; then
           snapWriteLog "ERROR: base64 tool can't be found in PATH=$PATH, please check."
           snapExit
       fi

       ssh -V 2>/dev/null
       if [ $? -ne 0 ]; then
           snapWriteLog "ERROR: ssh tool can't be found in PATH=$PATH, please check."
           snapExit
       fi
   fi
}

###############################################################################
# install db in volt db through VEM restful API.
#
function generateCatalogAndDeployment
{
    # Merge the ddc and sql files
	if [ $DB_MODEL -eq 4 ]; then 
	    echo "SET DR=ACTIVE;" > "$VOLTDBTMD/${VOLTDB_DB_NAME}.sql"
	else	
		echo > "$VOLTDBTMD/${VOLTDB_DB_NAME}.sql"
	fi
  
	 getAppSPJars "${DB_FLAG_NAME}" "voltdb" "*.jar" 
	 echo "SP_JARS is "$SP_JARS
    (echo >> "$VOLTDBTMD/${VOLTDB_DB_NAME}.sql" &&                                               
        getCommonSchema &&                                                                                                                      \
                                                                                                                                                \
        getAppSqls "${DB_FLAG_NAME}" "voltdb" "*.vdbcfg" "dummy"   &&                                                                           \
        for (( i=0 ; i < ${#CHOSED_APP_SQLS[@]} ; i++ )); do cp ${CHOSED_APP_SQLS[i]}  "$VOLTDBTMD/ddc"; done &&                                \
        getIntegrationAppSqls "${DB_FLAG_NAME}" "voltdb" "*.vdbcfg" "dummy"   &&                                                                \
        for (( i=0 ; i < ${#CHOSED_APP_SQLS[@]} ; i++ )); do cp ${CHOSED_APP_SQLS[i]}  "$VOLTDBTMD/ddc"; done &&                                \
        getAppSqls "${DB_FLAG_NAME}" "voltdb" "*.sql" "dummy"      &&                                                                           \
        for (( i=0 ; i < ${#CHOSED_APP_SQLS[@]} ; i++ )); do cat ${CHOSED_APP_SQLS[i]} >> "$VOLTDBTMD/${VOLTDB_DB_NAME}.sql"; done)
    if [ "$?" = "0" ]; then
        snapWriteLog
        snapWriteLog "VoltDB ddc and sql files for ${VOLTDB_DB_NAME} are merged successfully."
    else
        snapWriteLog "VoltDB ddc and sql files for ${VOLTDB_DB_NAME} are failed to be merged."
        snapExit
    fi

	
	#echo "CLASSPATH are:${CLASSPATH}"
	
    # EIUM voltdb tool used to generate store procedures and compile to java classes
	srcFolder="$VOLTDBTMD/src"
    (cd "$VOLTDBTMD" &&                                                                                \
            ${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.ProGenTools >$SNAPTM1 2>&1) 
	 if [ -d "$srcFolder" ]; then
       ( cd "$VOLTDBTMD" &&                                                                            \
	     find src -name '*.java' > javasourcefiles  &&                                                  \
        ${JAVA_HOME}/bin/javac -cp "${CLASSPATH}" -d bin @javasourcefiles >> $SNAPTM1 2>&1)
        if [ "$?" = "0" ]; then
            snapWriteLog
            snapWriteLog "VoltDB store procedures for ${VOLTDB_DB_NAME} are generated successfully."
        else
            cat $SNAPTM1 >>$SNAPLOG
            cat $SNAPTM1
            snapWriteLog "VoltDB store procedures for ${VOLTDB_DB_NAME} are failed to be generated."
            snapExit
        fi
     else		
		mkdir -p $VOLTDBTMD/bin 2>&1 >/dev/null
		cp $VOLTDBTMD/ddl/*.sql $VOLTDBTMD/ 2>&1 >/dev/null
	    snapWriteLog "Have no store procedures generated from vdbcfg files." 
	fi   
    #export JAVA_HOME=$VOLTDB_JAVA_HOME
	#export PATH=$JAVA_HOME/bin:$PATH
    # voltdb to generate catalog
	TIMER_PLUGIN_FOLDER_NAME=`ls -t $EIUM_PLUGIN | grep "$TIMER_PLUGIN" | head -1`
	snapWriteLog "Timer plugin folder name is:$TIMER_PLUGIN_FOLDER_NAME"
	
	if [ -z $TIMER_PLUGIN_FOLDER_NAME ]; then
         snapWriteLog "The Timer plugin folder is not exist, build the catalog.jar without FSM timer schema."
		 (cd "$VOLTDBTMD" &&    \
        ${VOLTDB_HOME}/bin/voltdb compile -c bin${SP_JARS} -o "${VOLTDB_DB_NAME}.jar" "${VOLTDB_DB_NAME}.sql" "ddl_schema.sql"  2>&1 >$SNAPTM1) 
    else
        if [ -f $EIUM_PLUGIN/$TIMER_PLUGIN_FOLDER_NAME/voltdb.ddl -a -f $EIUM_PLUGIN/$TIMER_PLUGIN_FOLDER_NAME/voltdb-procs.jar ]; then
           FSM_DDL=`ls -at  $EIUM_PLUGIN/${TIMER_PLUGIN_FOLDER_NAME}/voltdb.ddl | head -n 1`
	       FSM_JAR=`ls -at $EIUM_PLUGIN/$TIMER_PLUGIN_FOLDER_NAME/voltdb-procs.jar | head -n 1`
	   
	       snapWriteLog "Build the catalog.jar with FSM timer schema."
		   (cd "$VOLTDBTMD" &&    \
        ${VOLTDB_HOME}/bin/voltdb compile -c bin${SP_JARS}:$FSM_JAR -o "${VOLTDB_DB_NAME}.jar" "${VOLTDB_DB_NAME}.sql" "ddl_schema.sql" "$FSM_DDL"  2>&1 >$SNAPTM1)
        else
            snapWriteLog "Have no voltdb.ddl or voltdb-process.jar in the $EIUM_PLUGIN/$TIMER_PLUGIN_FOLDER_NAME folder, build the catalog.jar without FSM timer schema."
	        (cd "$VOLTDBTMD" &&    \
        ${VOLTDB_HOME}/bin/voltdb compile -c bin${SP_JARS} -o "${VOLTDB_DB_NAME}.jar" "${VOLTDB_DB_NAME}.sql" "ddl_schema.sql"  2>&1 >$SNAPTM1) 
       fi
    fi
		
    if [[ "$?" = "0" && -f "$VOLTDBTMD/${VOLTDB_DB_NAME}.jar" ]]; then
        snapWriteLog
        snapWriteLog "VoltDB catalog for ${VOLTDB_DB_NAME} is compiled successfully."
    else
        cat $SNAPTM1 >>$SNAPLOG
        cat $SNAPTM1
        snapWriteLog "VoltDB catalog for ${VOLTDB_DB_NAME} is failed to be compiled."
        snapExit
    fi
    
	case "$DB_MODEL" in
        1) TMP_DEPLOYMENT="${DBI_TPL}/${DB_FLAG_NAME}_no_repl_deployment.tmpl";;
        2) TMP_DEPLOYMENT="${DBI_TPL}/${DB_FLAG_NAME}_master_deployment.tmpl";;
        3) TMP_DEPLOYMENT="${DBI_TPL}/${DB_FLAG_NAME}_replica_deployment.tmpl";;
        4) TMP_DEPLOYMENT="${DBI_TPL}/${DB_FLAG_NAME}_replica_deployment.tmpl";;
        *) echo "Invalid VoltDB Working  Model"
		   snapExit
		   ;;
    esac
	
   # TMP_DEPLOYMENT="${DBI_TPL}/${DB_FLAG_NAME}_deployment.tmpl"
    # replace parameter in the deployment.xml
   sed -e "s~\$PLACEHOLDER_KFACTOR~$VOLTDB_KFACTOR~" \
        -e "s~\$PLACEHOLDER_SITES_PER_HOSTS~$VOLTDB_SITES_PER_HOST~" \
		-e "s~\$PLACEHOLDER_EXPORT_ABM_ENABLED~$ABM_EXPORT_ENABLE~" \
		-e "s~\$PLACEHOLDER_VOLTDB_EXPORT_ROLL_PERIOD~$VOLTDB_EXPORT_ROLL_PERIOD~" \
		-e "s~\$PLACEHOLDER_VAR_EIUM~$VAR_EIUM~" \
        -e "s~\$PLACEHOLDER_HOST_COUNT~$VOLTDB_HOST_COUNT~" \
		-e "s~\$PLACEHOLDER_ADMIN_USER~$VOLTDB_ADMIN_USER~" \
        -e "s~\$PLACEHOLDER_ADMIN_PASSWORD~$VOLTDB_ADMIN_PWD~" \
        -e "s~\$PLACEHOLDER_DB_USER~$VOLTDB_USER~" \
        -e "s~\$PLACEHOLDER_DB_PASSWORD~$VOLTDB_PWD~" \
        -e "s~\$PLACEHOLDER_DB_ROOT~$VOLTDB_ROOT~" \
        -e "s~\$PLACEHOLDER_ADMIN_PORT~$VOLTDB_ADMIN_PORT~" \
        -e "s~\$PLACEHOLDER_HTTPD_PORT~$VOLTDB_HTTPD_PORT~" \
		-e "s~\$PLACEHOLDER_SOURCE_NODELIST~$DR_SOURCE_NODES_LST~" \
		-e "s~\$PLACEHOLDER_DRID~$DR_ID~" \
        ${TMP_DEPLOYMENT} > "${VOLTDBTMD}/deployment.xml"
    if [ "$?" = "0" ]; then 
        snapWriteLog
        snapWriteLog "Voltdb deployment.xml for ${VOLTDB_DB_NAME} is configured successfully."
    else
        snapWriteLog
        snapWriteLog "Voltdb deployment.xml for ${VOLTDB_DB_NAME} is failed to be configured."
        snapExit
    fi
}

###############################################################################
# read the xml file and put regarding elements into variables: TAG_NAME, ATTRIBUTES
function read_xml_file {
    local IFS=\>
    read -d\< ENTITY CONTENT
    local RET=$?
    TAG_NAME=${ENTITY%% *}   # delete the longest pattern space from the end
    ATTRIBUTES_T=${ENTITY#* }  # delete the shortest pattern space from the head
    ATTRIBUTES=${ATTRIBUTES_T%*/}
    return $RET
}

###############################################################################
# parse regarding elements into key-value pairs
function parse_xml_elements {
    eval local $ATTRIBUTES 2>&1 >/dev/null
    if [[ $TAG_NAME = "cluster" ]] ; then
        echo "cluster.kfactor=$kfactor"
        echo "cluster.sitesperhost=$sitesperhost"
        echo "cluster.hostcount=$hostcount"
    elif [[ $TAG_NAME = "user" ]] ; then
        echo "users.user.name=$name"
        echo "users.user.password=$password"
        echo "users.user.roles=$roles"
    elif [[ $TAG_NAME = "voltdbroot" ]] ; then
        echo "paths.voltdbroot.path=$path"
    elif [[ $TAG_NAME = "snapshots" ]] ; then
        echo "paths.snapshots.path=$path"
    elif [[ $TAG_NAME = "commandlogsnapshot" ]] ; then
        echo "paths.commandlogsnapshot.path=$path"
    elif [[ $TAG_NAME = "commandlog" ]] ; then
        if [[ "x$path" != "x" ]]; then 
            echo "paths.commandlog.path=$path"
        fi
        if [[ "x$enabled" != "x" ]]; then
            echo "commandlog.logsize=$logsize"
            echo "commandlog.enabled=$enabled"
            echo "commandlog.synchronous=$synchronous"
        fi
    elif [[ $TAG_NAME = "admin-mode" ]] ; then
        echo "admin-mode.port=$port"
    elif [[ $TAG_NAME = "heartbeat" ]] ; then
        echo "heartbeat.timeout=$timeout"
    elif [[ $TAG_NAME = "httpd" ]] ; then
        echo "httpd.port=$port"
    elif [[ $TAG_NAME = "jsonapi" ]] ; then
        echo "httpd.jsonapi.enabled=$enabled"
    elif [[ $TAG_NAME = "frequency" ]] ; then
        echo "commandlog.frequency.transactions=$transactions"
        echo "commandlog.frequency.time=$time"
    elif [[ $TAG_NAME = "snapshot" ]] ; then
        if [ "x$priority" != "x" ]; then 
            echo "systemsettings.snapshot.priority=$priority"
        fi
        if [ "x$enabled" != "x" ]; then
            echo "snapshot.enabled=$enabled"
            echo "snapshot.retain=$retain"
            echo "snapshot.frequency=$frequency"
        fi
    elif [[ $TAG_NAME = "temptables" ]] ; then
        echo "systemsettings.temptables.maxsize=$maxsize"
    fi
}

###############################################################################
# install db in volt db through VEM restful API.
#
function createAndStartDB
{
    hostList=$1
	hostList=${hostList#*,}
    sshUser=$2
    dbName=$3

	ServerStr=
	leader_node=
	leader_node_external=
	nodes_network=
	#mask the voltdb user password
	${VOLTDB_HOME}/bin/voltdb mask ${VOLTDBTMD}/deployment.xml 2>&1 > /dev/null
	GROUP_NAME_MAPPING=""
    # Compose the server lists
		for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
			if [ "x$server" = "x" ]; then
				continue
			fi
			
			IHOST=`cat $VOLTDB_IHOST_LIST|grep "#${server}="|cut -d'=' -f 2-`
			PHOST=`cat $VOLTDB_PHOST_LIST|grep "#${server}="|cut -d'=' -f 2-`
			if [ -z $IHOST ]; then
			    IHOST=$server
			fi
			if [ -z $PHOST ]; then
			    PHOST=$server
			fi
			
			if [ -f $VOLTDB_RHOST_LIST ]; then
			    RHOST=`cat $VOLTDB_RHOST_LIST|grep "#${server}="|cut -d'=' -f 2-`
			else
			    RHOST=$server
			fi
			if [ -f $VOLTDB_AHOST_LIST ]; then
			    AHOST=`cat $VOLTDB_AHOST_LIST|grep "#${server}="|cut -d'=' -f 2-`
			else
			    AHOST=$server
			fi
			
			if [ -z $IHOST ]; then
			   if [[ "x$leader_node" == "x" ]]; then
			        leader_node=$server
					leader_node_external=$server
			   fi
			else
			   if [[ "x$leader_node" == "x" ]]; then
			        leader_node=$IHOST
					leader_node_external=$server
			   fi
			fi
			
			
			ORIGINAL_REPL_PORT=$VOLTDB_REPL_PORT
			if [ "x$RHOST" != "x" ]; then
			    VOLTDB_REPL_PORT_INTERFACE=$RHOST:$VOLTDB_REPL_PORT   
			fi
			
			ORIGINAL_ADMIN_PORT=$VOLTDB_ADMIN_PORT
			if [ "x$AHOST" != "x" ]; then
			    VOLTDB_ADMIN_PORT_INTERFACE=$AHOST:$VOLTDB_ADMIN_PORT   
			fi
			
			ORIGINAL_CLIENT_PORT=$VOLTDB_CLIENT_PORT
			VOLTDB_CLIENT_PORT_INTERFACE=$server:$VOLTDB_CLIENT_PORT
			VOLTDB_HTTPD_PORT_INTERFACE=$PHOST:$VOLTDB_HTTPD_PORT
			
			case "$DB_MODEL" in
			    1) snapWriteLog "Start the non-replication database: ${dbName} in the ${sshUser}@${server}";;
				2) snapWriteLog "Start the passive-DR master database: ${dbName} in the ${sshUser}@${server}";;
				3) snapWriteLog "Start the passive-DR replica database: ${dbName} in the ${sshUser}@${server}";;
				4) snapWriteLog "Start the cross-DR active database: ${dbName} in the ${sshUser}@${server}";;
				*) echo "Invalid VoltDB Working  Model"
		           snapExit
		           ;; 
			esac 
			
			echo "" > ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "export JAVA_HOME=$VOLTDB_JAVA_HOME " >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "export PATH=$JAVA_HOME/bin:$PATH  " >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "mkdir -p ${VAR_EIUM}/csv " >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "export LOG4J_CONFIG_PATH=${VOLTDBTMD}/voltdb_log4j.xml" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "export VOLTDB_HEAPMAX=$VOLTDB_HEAPMAX" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			echo "export VOLTDB_OPTS=\"${VOLTDB_OPTS} -XX:+PerfDisableSharedMem -DDISABLE_IMMEDIATE_SNAPSHOT_RESCHEDULING=true -DDISABLE_JMX=true\"" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			#echo " echo \$JAVA_HOME" >> ${VOLTDBTMD}/voltdb_create.sh
			#get the matched group name with the server host
			getPlacementGroupName $server
			if [ "x$GROUP_NAME_MAPPING" == "x" ]; then
			    GROUP_NAME_MAPPING="$server:$matched_group_name"
			else
			    GROUP_NAME_MAPPING="$GROUP_NAME_MAPPING;$server:$matched_group_name"
			fi
            		
			if [ $DB_MODEL -ne 3 ]; then
			    DATABASE_WORK_MODEL=ACTIVE
			   # echo "export VOLTDB_OPTS=\"-Dvolt.rmi.agent.port=${VOLTDB_JMX_PORT}\"" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
				echo "${VOLTDB_HOME}/bin/voltdb create --force --deployment=${VOLTDBTMD}/deployment.xml --host=$leader_node:$VOLTDB_START_PORT --client=$VOLTDB_CLIENT_PORT_INTERFACE --internal=$VOLTDB_INTERNAL_PORT  --replication=$VOLTDB_REPL_PORT_INTERFACE --zookeeper=$VOLTDB_ZOOKEEPER_PORT  --admin=$VOLTDB_ADMIN_PORT_INTERFACE --http=$VOLTDB_HTTPD_PORT_INTERFACE  --externalinterface=$server  --internalinterface=$IHOST --publicinterface=$PHOST $placement_group -B  ${VOLTDBTMD}/${dbName}.jar 2>&1 > ${VOLTDBTMD}/create_db.log" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			else
			   DATABASE_WORK_MODEL=REPLICA
			 #  echo "export VOLTDB_OPTS=\"-Dvolt.rmi.agent.port=${VOLTDB_JMX_PORT}\"" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			   echo "${VOLTDB_HOME}/bin/voltdb create --force --replica --deployment=${VOLTDBTMD}/deployment.xml --host=$leader_node:$VOLTDB_START_PORT --client=$VOLTDB_CLIENT_PORT_INTERFACE --internal=$VOLTDB_INTERNAL_PORT --replication=$VOLTDB_REPL_PORT_INTERFACE --zookeeper=$VOLTDB_ZOOKEEPER_PORT  --admin=$VOLTDB_ADMIN_PORT_INTERFACE --http=$VOLTDB_HTTPD_PORT_INTERFACE --externalinterface=$server  --internalinterface=$IHOST --publicinterface=$PHOST $placement_group -B  ${VOLTDBTMD}/${dbName}.jar 2>&1 > ${VOLTDBTMD}/create_db.log" >> ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh
			fi
			ssh -nq ${sshUser}@${server} "mkdir -p ${VOLTDBTMD}"
			scp ${VOLTDBTMD}/deployment.xml ${sshUser}@${server}:${VOLTDBTMD} 2>&1 > /dev/null
			scp ${VOLTDBTMD}/${dbName}.jar ${sshUser}@${server}:${VOLTDBTMD} 2>&1 > /dev/null
			scp ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh ${sshUser}@${server}:${VOLTDBTMD} 2>&1 > /dev/null
			scp ${VOLTDBTMD}/voltdb_log4j.xml ${sshUser}@${server}:${VOLTDBTMD} 2>&1 > /dev/null
			ssh -nq ${sshUser}@${server} "chmod +x ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh"
			ssh -nq ${sshUser}@${server} "sh ${VOLTDBTMD}/voltdb_create_${PROCESS_NUM}.sh"
			
			#nodes_network=$nodes_network$server"/"$IHOST"/"$PHOST","
			#if [ "x$RHOST" != "x" ]; then
			 #  nodes_network=$nodes_network$server"/"$IHOST"/"$PHOST"/"$RHOST","
			#fi
			#if [ "x$AHOST" != "x" ]; then
			   nodes_network=$nodes_network$server"/"$IHOST"/"$PHOST"/"$RHOST"/"$AHOST","
			#fi
		done
		
		nodes_network_info=${nodes_network%?}
		echo "nodes_network_info is:"$nodes_network_info

		#loop checking the database start successful
		ChekVoltDBStartSuccess
		
		if [ $? -eq 0 ]; then
		     VOLTDB_DATA_STORE_PATH=${VOLTDB_ROOT}
		     if [ $DB_NAME == 2 ]; then
			     VOLTDB_DATA_STORE_PATH="$VOLTDB_DATA_STORE_PATH/dbs/spr"
			 elif [ $DB_NAME == 3 ]; then
			     VOLTDB_DATA_STORE_PATH="$VOLTDB_DATA_STORE_PATH/dbs/session"
			 fi
		     # insert  a record into the .database.ini file
			 VOLTDB_PWD_ORI=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool encrypt $VOLTDB_PWD_ORI`
			 VOLTDB_ADMIN_PWD_ORI=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool encrypt $VOLTDB_ADMIN_PWD_ORI`
			 info_data="#${dbName} ${nodes_network_info} ${VOLTDB_DATA_STORE_PATH} ${ORIGINAL_CLIENT_PORT} ${ORIGINAL_ADMIN_PORT} ${VOLTDB_HTTPD_PORT} ${VOLTDB_INTERNAL_PORT} ${VOLTDB_ZOOKEEPER_PORT} ${ORIGINAL_REPL_PORT} ${VOLTDB_USER} ${VOLTDB_PWD_ORI} ${VOLTDB_ADMIN_USER} ${VOLTDB_ADMIN_PWD_ORI} ${VOLTDB_START_PORT} ${DATABASE_WORK_MODEL} ${GROUP_NAME_MAPPING}"
			 # distribute the .database.ini file to cluster node.
			 for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
			     ssh -nq ${sshUser}@${server} "echo '${info_data}' >> ${VOLTDB_HOME}/.database.ini"
				 ssh -nq ${sshUser}@${server} "rm -f /tmp/deployment.xml /tmp/${dbName}.jar"
			 done
		else
		    snapWriteLog "The database create and start failed, please contact to administrator!"
			snapExit
		fi
}

###############################################################################
# generate maintain script for specific db on voltdb
function generateVDBScript
{
    # replace parameter in the snap_vdb_shell.tmpl
    sed -e "s~\PLACEHOLDER_VOLTDB_JAVA_HOME~$VOLTDB_JAVA_HOME~" \
        -e "s~\PLACEHOLDER_VOLTDB_HOME~$VOLTDB_HOME~" \
        -e "s~\PLACEHOLDER_VOLTDB_DB_NAME~${VOLTDB_DB_NAME}~" \
		-e "s~\PLACEHOLDER_VOLTDB_CLUSTER_HOST~${leader_node_external}~" \
		-e "s~\PLACEHOLDER_VOLTDB_SSH_USER~${VOLTDB_SSH_USER}~" \
		-e "s~\PLACEHOLDER_EIUM_VOLTDB_TOOL~${EIUM_VOLTDB_TOOL}~" \
		-e "s~\PLACEHOLDER_EIUM_HOME~${EIUM_HOME}~" \
		-e "s~\PLACEHOLDER_VDB_FLAG_NAME~${DB_FLAG_NAME}~" \
		-e "s~\PLACEHOLDER_VOLTDB_HEAPMAX~${VOLTDB_HEAPMAX}~" \
        "${DBI_TPL}/snap_vdb_shell.tmpl" > "${VOLTDBTMD}/snap_vdb_shell.sh"
    
    if [ "$?" = "0" ]; then 
        snapWriteLog
        snapWriteLog "Voltdb snap_vdb_shell.sh for ${VOLTDB_DB_NAME} is configured successfully."
    else
        snapWriteLog
        snapWriteLog "Voltdb snap_vdb_shell.sh for ${VOLTDB_DB_NAME} is failed to be configured."
        snapExit
    fi

}

###############################################################################
# generate maintain script for specific db on voltdb
function generateVDBScriptAndDistribute
{
   hostList=$1
   hostList=${hostList#*,}
    sshUser=$2
	dbName=$3
	for server in `echo "$hostList"|awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
	   if [ "x$server" = "x" ]; then
		    continue
	   fi
	   if [[ "x$leader_node" == "x" ]]; then
			leader_node=$server
	   fi
	   sed -e "s~\PLACEHOLDER_VOLTDB_JAVA_HOME~$VOLTDB_JAVA_HOME~" \
        -e "s~\PLACEHOLDER_VOLTDB_HOME~$VOLTDB_HOME~" \
        -e "s~\PLACEHOLDER_VOLTDB_DB_NAME~${VOLTDB_DB_NAME}~" \
		-e "s~\PLACEHOLDER_VOLTDB_CLUSTER_HOST~${server}~" \
		-e "s~\PLACEHOLDER_VOLTDB_SSH_USER~${VOLTDB_SSH_USER}~" \
		-e "s~\PLACEHOLDER_EIUM_VOLTDB_TOOL~${EIUM_VOLTDB_TOOL}~" \
		-e "s~\PLACEHOLDER_EIUM_HOME~${EIUM_HOME}~" \
		-e "s~\PLACEHOLDER_VDB_FLAG_NAME~${DB_FLAG_NAME}~" \
		-e "s~\PLACEHOLDER_VOLTDB_HEAPMAX~${VOLTDB_HEAPMAX}~" \
        "${DBI_TPL}/snap_vdb_shell.tmpl" > "${VOLTDBTMD}/snap_vdb_shell_${server}.sh"
	    ssh -nq ${sshUser}@${server} "mkdir -p $DBI_HOME/target/${VOLTDB_DB_NAME}"
		#scp ${VOLTDBTMD}/${VOLTDB_DB_NAME}.jar ${sshUser}@${server}:$DBI_HOME/target/${VOLTDB_DB_NAME} 2>&1 > /dev/null
		#scp ${VOLTDBTMD}/deployment.xml ${sshUser}@${server}:$DBI_HOME/target/${VOLTDB_DB_NAME} 2>&1 > /dev/null
		scp ${VOLTDBTMD}/voltdb_log4j.xml ${sshUser}@${server}:$DBI_HOME/target/${VOLTDB_DB_NAME} 2>&1 > /dev/null
		scp ${VOLTDBTMD}/snap_vdb_shell_${server}.sh ${sshUser}@${server}:$DBI_HOME/target/${VOLTDB_DB_NAME}/snap_vdb_shell.sh 2>&1 > /dev/null
		ssh -nq ${sshUser}@${server} "chmod +x $DBI_HOME/target/${VOLTDB_DB_NAME}/snap_vdb_shell.sh"
		
		if [ "$?" = "0" ]; then 
            snapWriteLog
            snapWriteLog "Voltdb snap_vdb_shell.sh for ${VOLTDB_DB_NAME} is configured successfully in the ${server}:$DBI_HOME/target/${VOLTDB_DB_NAME}."
        else
            snapWriteLog
            snapWriteLog "Voltdb snap_vdb_shell.sh for ${VOLTDB_DB_NAME} is failed to be configured in the ${server}:$DBI_HOME/target/${VOLTDB_DB_NAME}."
            snapExit
        fi
	done
}

###############################################################################
# create datasource in VoltDB
# $1-db real name; $2-ddc file; $3-db sql 
function createDBInVoltDB
{
    DB_FLAG_NAME=$1
    PORT_OFFSET=$2

    # get database name
	if [ $silent -eq 1  ]; then
	    if [ -z $VOLTDB_INSTANCE_NAME ]; then
		    VOLTDB_INSTANCE_NAME=$DB_FLAG_NAME
		fi
	    VOLTDB_DB_NAME=$VOLTDB_INSTANCE_NAME
    else
	  snapEditValue "  * VoltDB database instance name" "$DB_FLAG_NAME" "VOLTDB_DB_NAME"
    fi	
    

    # create the temp dir for voltdb building
    #VOLTDBTMD="$SNAPTMD/voltdb.$$"
    snapCheckDir "$VOLTDBTMD/ddc"
    snapCheckDir "$VOLTDBTMD/bin"
    (cd $VOLTDBTMD; ln -s $EIUM_VOLTDB_TOOL/ddl . 2>/dev/null)
    (cd $VOLTDBTMD; ln -s $EIUM_VOLTDB_TOOL/procedures . 2>/dev/null)

    # Check the database is exist? Currently, don't confirm the database is existing or not
  # if [[ "$IS_ONLY_GENERATE_CATALOG" = "false" ]]; then 
  #      dbId=`getDBInVoltDB $VOLTDB_DB_NAME`
  #      if [[ "x$dbId" != "x" ]]; then
  #          snapWriteLog "  ERROR: database named $VOLTDB_DB_NAME already exits, please check or remove the original one first!"
  #          snapExit
  #      fi
  #  fi
	
   # IS_ONLY_GENERATE_DATABASE="false"
   LEADER_HOST=
    if [[ "$IS_ONLY_GENERATE_CATALOG" = "false" ]]; then     
	#	if [ $silent -eq 1  ]; then
	#	   if [ -z $VOLTDB_WITHOUT_CLUSTER_NODE ]; then
	#	        VOLTDB_WITHOUT_CLUSTER_NODE="true"
	#	   fi
#		    IS_ONLY_GENERATE_DATABASE=$VOLTDB_WITHOUT_CLUSTER_NODE
 #       else
		    VOLTDB_SSH_USER=$(whoami)
			 
	#	    snapEditValue "  * VoltDB Server installation option: (true - Only generate database without cluster node; false - Generate VoltDB database and add cluster node in it as well)" "$IS_ONLY_GENERATE_DATABASE" "IS_ONLY_GENERATE_DATABASE"
     #   fi
	    
	#	if [[ "$IS_ONLY_GENERATE_DATABASE" = "false" ]]; then
	         HOST_CNT=0
			 VOLTDB_IHOST_LIST=$VOLTDBTMD/ihostlist
			 VOLTDB_PHOST_LIST=$VOLTDBTMD/phostlist
			 VOLTDB_RHOST_LIST=$VOLTDBTMD/rhostlist
			 VOLTDB_AHOST_LIST=$VOLTDBTMD/ahostlist
		    if [ $silent -eq 1  ]; then
			  USERHOST=$VOLTDB_NODE_LIST
			  if [[ "x$USERHOST" != "x" ]]; then 
			      for node in `echo $USERHOST | awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ;do
					if [[ "$node" =~ (.+)/(.*)/(.*)/(.*)/(.*) || "$node" =~ (.+)/(.*)/(.*)/(.*) || "$node" =~ (.+)/(.*)/(.*)  ]]; then
						   FIRSTHOST=${BASH_REMATCH[1]}
						   ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST echo hello 2>&1 > /dev/null
						   
				           if [ $? -ne 0 ]; then
					            snapWriteLog "SSH user [$VOLTDB_SSH_USER] can't access [$FIRSTHOST], Please check."
					            snapExit
				           fi
						   
						   prepareCheckHugepage $VOLTDB_SSH_USER $FIRSTHOST
						   
						   lsDatabaseInfo=`ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST "ls $VOLTDB_HOME/.database.ini 2>&1 > /dev/null"`
								   
						   if [[ "$?" == "0" ]]; then
	                             CheckDatabaseInfo=`ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST "cat $VOLTDB_HOME/.database.ini | grep '#$VOLTDB_DB_NAME '"`
		                         if [[ "$?" == "0" ]]; then
							 	    echo " the database $VOLTDB_DB_NAME exist in the $FIRSTHOST server, please re-configure."
									snapExit
							   	 else
								    VOLTDB_HOST_LIST="$VOLTDB_HOST_LIST,${BASH_REMATCH[1]}"
						            echo "    Current VoltDB host list in a cluster is: [$VOLTDB_HOST_LIST]"
						            echo "#$FIRSTHOST=${BASH_REMATCH[2]}" >> $VOLTDB_IHOST_LIST
						            echo "#$FIRSTHOST=${BASH_REMATCH[3]}" >> $VOLTDB_PHOST_LIST
									#if [[ "$node" =~ (.+)/(.*)/(.*)/(.*) ]]; then
									#    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
									#fi	
									#if [[ "$node" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
									#    echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
									#fi
									
									if [[ "$node" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
									    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
										echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
									elif [[ "$node" =~ (.+)/(.*)/(.*)/(.*) ]]; then
									    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
									fi
									
									
									if [[ "x$LEADER_HOST" == "x" ]]; then
									     LEADER_HOST=${BASH_REMATCH[1]}
									fi
									HOST_CNT=$((HOST_CNT+1))
								fi
	                       else
						         VOLTDB_HOST_LIST="$VOLTDB_HOST_LIST,${BASH_REMATCH[1]}"
						         echo "    Current VoltDB host list in a cluster is: [$VOLTDB_HOST_LIST]"
						         echo "#$FIRSTHOST=${BASH_REMATCH[2]}" >> $VOLTDB_IHOST_LIST
						         echo "#$FIRSTHOST=${BASH_REMATCH[3]}" >> $VOLTDB_PHOST_LIST
								 #if [[ "$node" =~ (.+)/(.*)/(.*)/(.*) ]]; then
								 #	    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
								 #fi
								 #if [[ "$node" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
								  #	    echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
							     #fi
								 
								  if [[ "$node" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
									    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
										echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
									elif [[ "$node" =~ (.+)/(.*)/(.*)/(.*) ]]; then
									    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
									fi
								 
								 
								 if [[ "x$LEADER_HOST" == "x" ]]; then
									     LEADER_HOST=${BASH_REMATCH[1]}
								 fi
								 HOST_CNT=$((HOST_CNT+1))
						   fi
					else
						   echo "  ERROR:$node is not in right format: '<external(client,replication,admin) interface>/<internal interface>/<public(http) interface>' or '<external(client,admin) interface>/<internal interface>/<public(http) interface>/<replication interface>' or '<external(client) interface>/<internal interface>/<public(http) interface>/<replication interface>/<admin interface>',  please re-configure."
						   snapExit
					fi
				  done
			   else
                    echo " ERROR: VOLTDB node list is empty."	
                     snapExit					
			   fi
			   if [ -z $VOLTDB_SSH_USER ]; then
			       VOLTDB_SSH_USER=$(whoami)
			   fi
			   VOLTDB_SSH_USER=$VOLTDB_SSH_USER
			   
            else
			    #snapEditValue "  * VoltDB ssh user to access the cluster" "$VOLTDB_SSH_USER" "VOLTDB_SSH_USER"
			    echo 
			    echo "  * VoltDB host list in a cluster to be configured, at least one host shall be provided."
			    LEADER_HOST=""
			    while [[ "x$USERHOST" != "x" || "x$VOLTDB_HOST_LIST" == "x" ]]; do
				       #read -p "    Input the string in format: '<external interface>/<internal interface>/<public interface>' or exit in format: '<empty>[Enter]':" USERHOST
					   read -p $'    Input the string in format: "<external(client,admin,replication) interface>/<internal interface>/<public(http) interface>" \x0a or "<external(client,admin) interface>/<internal interface>/<public(http) interface>/<replication interface>" \x0a or "<external(client) interface>/<internal interface>/<public(http) interface>/<replication interface>/<admin interface>" \x0a or exit in format: "<empty>[Enter]":' USERHOST
				       if [[ "x$USERHOST" != "x" ]]; then 
					        if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*)/(.*) || "$USERHOST" =~ (.+)/(.*)/(.*)/(.*) || "$USERHOST" =~ (.+)/(.*)/(.*) ]]; then
							      FIRSTHOST=${BASH_REMATCH[1]}
								  ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST echo hello 2>&1 > /dev/null
				                  if [ $? -ne 0 ]; then
					                   snapWriteLog "SSH user [$VOLTDB_SSH_USER] can't access [$FIRSTHOST], Please check."
					                   snapExit
				                   fi
							      lsDatabaseInfo=`ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST "ls $VOLTDB_HOME/.database.ini 2>&1 > /dev/null"`
								   
								  if [[ "$?" == "0" ]]; then
	                                    CheckDatabaseInfo=`ssh -nq $VOLTDB_SSH_USER@$FIRSTHOST "cat $VOLTDB_HOME/.database.ini | grep '#$VOLTDB_DB_NAME '"`
		                                if [[ "$?" == "0" ]]; then
										    echo " the database $VOLTDB_DB_NAME exist in the $FIRSTHOST server, please re-input"
										else
										    VOLTDB_HOST_LIST="$VOLTDB_HOST_LIST,${BASH_REMATCH[1]}"
						                    echo "    Current VoltDB host list in a cluster is: [$VOLTDB_HOST_LIST]"
						                    echo "#$FIRSTHOST=${BASH_REMATCH[2]}" >> $VOLTDB_IHOST_LIST
						                    echo "#$FIRSTHOST=${BASH_REMATCH[3]}" >> $VOLTDB_PHOST_LIST
											#if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*) ]]; then
									        #      echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
									        #fi
											#if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
									        #      echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
							                #fi
											
											if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
											   echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
											   echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
											   
											elif [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*) ]]; then
											   echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
											fi
											
											if [[ "x$LEADER_HOST" == "x" ]]; then
									            LEADER_HOST=${BASH_REMATCH[1]}
									        fi
											HOST_CNT=$((HOST_CNT+1))
										fi
	                              else
						               VOLTDB_HOST_LIST="$VOLTDB_HOST_LIST,${BASH_REMATCH[1]}"
						               echo "    Current VoltDB host list in a cluster is: [$VOLTDB_HOST_LIST]"
						               echo "#$USERHOST=${BASH_REMATCH[2]}" >> $VOLTDB_IHOST_LIST
						               echo "#$USERHOST=${BASH_REMATCH[3]}" >> $VOLTDB_PHOST_LIST
									   #if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*) ]]; then
									   #    echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
								       #fi
									   #if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
									   #           echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
							           #fi
									   
									   if [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
											   echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
											   echo "#$FIRSTHOST=${BASH_REMATCH[5]}" >> $VOLTDB_AHOST_LIST
											   
								       elif [[ "$USERHOST" =~ (.+)/(.*)/(.*)/(.*) ]]; then
											   echo "#$FIRSTHOST=${BASH_REMATCH[4]}" >> $VOLTDB_RHOST_LIST
									   fi
											
									   if [[ "x$LEADER_HOST" == "x" ]]; then
									       LEADER_HOST=${BASH_REMATCH[1]}
									   fi
									   HOST_CNT=$((HOST_CNT+1))
								  fi		
					        else
						          #echo "  ERROR:$USERHOST is not in right format: '<external interface>/<internal interface>/<public interface>',  please re-input."
								  echo -e "  ERROR:$USERHOST is not in right format: '<external(client, admin, replication) interface>/<internal interface>/<public(http) interface>' \n         or '<external(client, admin) interface>/<internal interface>/<public(http) interface>/<replication interface>' \n          or
								  <external(client) interface>/<internal interface>/<public(http) interface>/<replication interface>/<admin interface>,  please re-input."
					        fi
					       echo
				       fi
			   done	
               snapEditValue "  * VoltDB node placement groups, e.g. <external_interface1>:<group_name1>;<external_interface2>:<group_name2>......" "$VOLTDB_PLACEMENT_GROUPS" "VOLTDB_PLACEMENT_GROUPS"			   
            fi
			
		#fi
		
        VOLTDB_HOST_COUNT=1
      
		# Now the host count is calculated automatically
		VOLTDB_HOST_COUNT=${HOST_CNT}
		snapWriteLog "The database cluster host count is:${VOLTDB_HOST_COUNT}"
     
    else
	   if [ $silent -eq 1  ]; then
	       USERHOST=$VOLTDB_NODE_LIST
		   HOST_CNT=`echo $USERHOST | awk -F ':' '{print NF}'`
		   VOLTDB_HOST_COUNT=${HOST_CNT}
		   snapWriteLog "The database cluster host count is:${VOLTDB_HOST_COUNT}"
	   else
           VOLTDB_HOST_COUNT=1
           snapEditValue "  * VoltDB host count in a cluster" "$VOLTDB_HOST_COUNT" "VOLTDB_HOST_COUNT"
	  fi	
    fi
	
	VOLTDB_ADMIN_USER="vdbadmin"
	if [ $silent -eq 1  ]; then
	      snapWriteLog "VoltDB placement groups is: ${VOLTDB_PLACEMENT_GROUPS}"
	
	      if [ -z $VOLTDB_ADMIN_USERNAME ]; then
		     VOLTDB_ADMIN_USERNAME=$VOLTDB_ADMIN_USER
		 fi
	     VOLTDB_ADMIN_USER=$VOLTDB_ADMIN_USERNAME
		 snapWriteLog "VoltDB admin user name is: ${VOLTDB_ADMIN_USER}"
		 
		 if [ -z $VOLTDB_ADMIN_PASSWORD ]; then
		     VOLTDB_ADMIN_PASSWORD=$VOLTDB_ADMIN_USER
		 fi
		 VOLTDB_ADMIN_PWD=$VOLTDB_ADMIN_PASSWORD
		 snapWriteLog "VoltDB admin password is: ********"
		 
	     if [ -z $VOLTDB_USER_NAME ]; then
		     VOLTDB_USER_NAME=$VOLTDB_USER
		 fi
	     VOLTDB_USER=$VOLTDB_USER_NAME
		 snapWriteLog "VoltDB user name is: ${VOLTDB_USER}"
		 
		 if [ -z $VOLTDB_USER_PASSWORD ]; then
		     VOLTDB_USER_PASSWORD=$VOLTDB_USER
		 fi
		 VOLTDB_PWD=$VOLTDB_USER_PASSWORD
		 snapWriteLog "VoltDB user password is: ********"
		 
		 #if [ -z $VOLTDB_KFACTOR ]; then
		 #    VOLTDB_KFACTOR=0
		 #fi
		 #VOLTDB_KFACTOR=$VOLTDB_KFACTOR
		 #snapWriteLog "VoltDB k-factor value is: ${VOLTDB_KFACTOR}"
		 
		 if [ -z $VOLTDB_SITES_PER_HOST ]; then
		     VOLTDB_SITES_PER_HOST=10
		 fi
		 VOLTDB_SITES_PER_HOST=$VOLTDB_SITES_PER_HOST
		 snapWriteLog "VoltDB sites per-host value is: ${VOLTDB_SITES_PER_HOST}"
		 
		 if [ -z $VOLTDB_EXPORT_ROLL_PERIOD ]; then
		     VOLTDB_EXPORT_ROLL_PERIOD=60
		 fi
		 VOLTDB_EXPORT_ROLL_PERIOD=$VOLTDB_EXPORT_ROLL_PERIOD
		 snapWriteLog "VoltDB export stream rolling output filefrequency value is: ${VOLTDB_EXPORT_ROLL_PERIOD}"
    else
	  
	   snapEditValue "  * VoltDB admin user name" "$VOLTDB_ADMIN_USER" "VOLTDB_ADMIN_USER"
    
       VOLTDB_ADMIN_PWD=$VOLTDB_ADMIN_USER
       snapEditPassword "  * VoltDB admin user password" "$VOLTDB_ADMIN_PWD" "VOLTDB_ADMIN_PWD"
	   
	   snapEditValue "  * VoltDB user name" "$VOLTDB_USER" "VOLTDB_USER"
	   
	   VOLTDB_PWD=
       snapEditValue "  * VoltDB user password" "$VOLTDB_PWD" "VOLTDB_PWD"
    
       #VOLTDB_KFACTOR=0
       #snapEditValue "  * VoltDB kfactor in a cluster" "$VOLTDB_KFACTOR" "VOLTDB_KFACTOR"

       VOLTDB_SITES_PER_HOST=10
       snapEditValue "  * VoltDB sites per host in a cluster" "$VOLTDB_SITES_PER_HOST" "VOLTDB_SITES_PER_HOST"
	   
	   VOLTDB_EXPORT_ROLL_PERIOD=60
	   snapEditValue " * VoltDB export stream rolling output file in frequency (minutes)" "$VOLTDB_EXPORT_ROLL_PERIOD" "VOLTDB_EXPORT_ROLL_PERIOD"
    fi
	
	VOLTDB_KFACTOR=0
	if [ $VOLTDB_HOST_COUNT -gt 1 ]; then
	    VOLTDB_KFACTOR=1
	fi	
	snapWriteLog "VoltDB k-factor value is: ${VOLTDB_KFACTOR}"	
	
	VOLTDB_ADMIN_PWD_ORI=$VOLTDB_ADMIN_PWD
	VOLTDB_ADMIN_PWD=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $VOLTDB_ADMIN_PWD`
	
	VOLTDB_PWD_ORI=$VOLTDB_PWD
	VOLTDB_PWD=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $VOLTDB_PWD`

	
	if [ $silent -eq 1  ]; then
	    if [ -z $VOLTDB_ROOT_PATH ]; then
		    VOLTDB_ROOT_PATH=/opt/${VOLTDB_SSH_USER}/voltdb
		fi
		VOLTDB_ROOT=$VOLTDB_ROOT_PATH
		snapWriteLog "VoltDB root path is: ${VOLTDB_ROOT}"
		if [ -z $VOLTDB_CLIENT_PORT ]; then
		     VOLTDB_CLIENT_PORT="${PORT_OFFSET}1212"
		fi
		VOLTDB_CLIENT_PORT=$VOLTDB_CLIENT_PORT
		snapWriteLog "VoltDB client port is: ${VOLTDB_CLIENT_PORT}"
		if [ -z $VOLTDB_ADMIN_PORT ]; then
		     VOLTDB_ADMIN_PORT="$(($VOLTDB_CLIENT_PORT + 1))"
		fi
		VOLTDB_ADMIN_PORT=$VOLTDB_ADMIN_PORT
		snapWriteLog "VoltDB admin port is: ${VOLTDB_ADMIN_PORT}"
		if [ -z $VOLTDB_HTTP_PORT ]; then
		     VOLTDB_HTTP_PORT="$(($VOLTDB_CLIENT_PORT + 2))"
		fi
		VOLTDB_HTTPD_PORT=$VOLTDB_HTTP_PORT
		snapWriteLog "VoltDB httpd port is: ${VOLTDB_HTTPD_PORT}"
		if [ -z $VOLTDB_INTERNAL_PORT ]; then
		     VOLTDB_INTERNAL_PORT="$(($VOLTDB_CLIENT_PORT + 3))"
		fi
		VOLTDB_INTERNAL_PORT=$VOLTDB_INTERNAL_PORT
		snapWriteLog "VoltDB internal port is: ${VOLTDB_INTERNAL_PORT}"
		
		#if [ -z $VOLTDB_JMX_PORT ]; then
		#     VOLTDB_JMX_PORT="$(($VOLTDB_CLIENT_PORT + 4))"
		#fi
		#VOLTDB_JMX_PORT=$VOLTDB_JMX_PORT
		#snapWriteLog "VoltDB jmx port is: ${VOLTDB_JMX_PORT}"
		
		#if [ -z $VOLTDB_LOG_PORT ]; then
		#     VOLTDB_LOG_PORT="$(($VOLTDB_CLIENT_PORT + 5))"
		#fi
		#VOLTDB_LOG_PORT=$VOLTDB_LOG_PORT
		#snapWriteLog "VoltDB log port is: ${VOLTDB_LOG_PORT}"
		
		if [ -z $VOLTDB_ZOOKEEPER_PORT ]; then
		     VOLTDB_ZOOKEEPER_PORT="$(($VOLTDB_CLIENT_PORT + 6))"
		fi
		VOLTDB_ZOOKEEPER_PORT=$VOLTDB_ZOOKEEPER_PORT
		snapWriteLog "VoltDB zookeeper port is: ${VOLTDB_ZOOKEEPER_PORT}"
		if [ -z $VOLTDB_REPLICATION_PORT ]; then
		     VOLTDB_REPLICATION_PORT="$(($VOLTDB_CLIENT_PORT + 7))"
		fi
		VOLTDB_REPL_PORT=$VOLTDB_REPLICATION_PORT
		snapWriteLog "VoltDB replication port is: ${VOLTDB_REPL_PORT}"
		#if [ -z $VOLTDB_START_PORT ]; then
		#     VOLTDB_START_PORT="${PORT_OFFSET}5021"
		#fi
		VOLTDB_START_PORT=$VOLTDB_INTERNAL_PORT
		#snapWriteLog "VoltDB start port is: ${VOLTDB_START_PORT}"   
    else
		VOLTDB_ROOT="${VAR_EIUM}/voltdb"
        snapEditValue "  * VoltDB root path in snap applications" "$VOLTDB_ROOT" "VOLTDB_ROOT"

        VOLTDB_CLIENT_PORT="${PORT_OFFSET}1212"
        snapEditPort "  * The port VoltDB client applications use to communicate with the database cluster" "$VOLTDB_CLIENT_PORT" "VOLTDB_CLIENT_PORT"

        VOLTDB_ADMIN_PORT="$(($VOLTDB_CLIENT_PORT + 1))"
        snapEditPort "  * The port similar to client port, special used when VoltDB is in admin mode" "$VOLTDB_ADMIN_PORT" "VOLTDB_ADMIN_PORT"

        VOLTDB_HTTPD_PORT="$(($VOLTDB_CLIENT_PORT + 2))"
        snapEditPort "  * The port VoltDB listens to for web-based connections from the JSON interface" "$VOLTDB_HTTPD_PORT" "VOLTDB_HTTPD_PORT"

        VOLTDB_INTERNAL_PORT="$(($VOLTDB_CLIENT_PORT + 3))"
        snapEditPort "  * The port VoltDB cluster uses to communicate among the cluster nodes" "$VOLTDB_INTERNAL_PORT" "VOLTDB_INTERNAL_PORT"

        #VOLTDB_JMX_PORT="$(($VOLTDB_CLIENT_PORT + 4))"
        #snapEditPort "  * The port VoltDB Enterprise Manager uses JMX to collect statistics" "$VOLTDB_JMX_PORT" "VOLTDB_JMX_PORT"

        #VOLTDB_LOG_PORT="$(($VOLTDB_CLIENT_PORT + 5))"
        #snapEditPort "  * The port VoltDB Enterprise Manager uses to output log4j messages" "$VOLTDB_LOG_PORT" "VOLTDB_LOG_PORT"

        VOLTDB_ZOOKEEPER_PORT="$(($VOLTDB_CLIENT_PORT + 6))"
        snapEditPort "  * The port VoltDB Zookeeper uses to communicate among supplementary functions" "$VOLTDB_ZOOKEEPER_PORT" "VOLTDB_ZOOKEEPER_PORT"

        VOLTDB_REPL_PORT="$(($VOLTDB_CLIENT_PORT + 7))"
        snapEditPort "  * The port VoltDB uses to replicate data" "$VOLTDB_REPL_PORT" "VOLTDB_REPL_PORT"
		
		VOLTDB_START_PORT=${VOLTDB_INTERNAL_PORT}
		#VOLTDB_START_PORT="${PORT_OFFSET}5021"
		#snapEditPort " * The port VoltDB uses to start database" "$VOLTDB_START_PORT" "VOLTDB_START_PORT"
		
    fi

	if [ $silent -ne 1  ]; then
      snapContinue
    fi
	
    # generate the catalog jar and deploy.xml
    generateCatalogAndDeployment


    if [[ "$IS_ONLY_GENERATE_CATALOG" = "false" ]]; then 
        # create db through VEM restful API
        createAndStartDB "$VOLTDB_HOST_LIST" "$VOLTDB_SSH_USER" "${VOLTDB_DB_NAME}"  
        # generate vdb maintain shell script for all server
        #generateVDBScript  
		generateVDBScriptAndDistribute "$VOLTDB_HOST_LIST" "$VOLTDB_SSH_USER" "${VOLTDB_DB_NAME}" 
    fi
	
	if [[ "$IS_ONLY_GENERATE_CATALOG" = "true" ]]; then
	    #mask the voltdb user password
	    ${VOLTDB_HOME}/bin/voltdb mask ${VOLTDBTMD}/deployment.xml 2>&1 > /dev/null
	    #copy the catalog.jar and deployment.xml to $DBI_HOME/target/${VOLTDB_DB_NAME}
		mkdir -p $DBI_HOME/target/${VOLTDB_DB_NAME} 
		cp -f ${VOLTDBTMD}/${VOLTDB_DB_NAME}.jar $DBI_HOME/target/${VOLTDB_DB_NAME} 2>&1 > /dev/null
		if [ $? -eq 0 ]; then
		  snapWriteLog "copy the ${VOLTDB_DB_NAME}.jar to  $DBI_HOME/target/${VOLTDB_DB_NAME} folder."
		fi
		cp -f ${VOLTDBTMD}/deployment.xml $DBI_HOME/target/${VOLTDB_DB_NAME} 2>&1 > /dev/null
		if [ $? -eq 0 ]; then
		  snapWriteLog "copy the deployment.xml to  $DBI_HOME/target/${VOLTDB_DB_NAME} folder."
		fi
	fi



    # remove the tmp directory
    if [ $debug -eq 0 ]; then 
        rm -rf "$VOLTDBTMD" 2>/dev/null
    fi    
}

###############################################################################
# get database in voltdb through rest api.
function getDBInVoltDB
{
    DB_NAME=$1
    DBS=$(RestExec "1" "/mgmt/databases")
    dbId=$(echo $DBS|sed 's/"Database"/\n"Database"/g'|grep $DB_NAME|grep -oP '("id": [0-9]+)'|cut -d : -f 2)
    echo "$dbId"
}

function getServerInVoltDB
{
    DB_Host=$1
    ServerS=$(RestExec "1" "/servers/")
    ServerId=$(echo $ServerS|sed 's/"Server"/\n"Server"/g'|grep $DB_Host|grep -oP '("id": [0-9]+)'|cut -d : -f 2 | awk 'NR==1')
    echo "$ServerId"
}

function getVoltdbStatus() 
{
    DBINFO=$(RestExec "1" "/mgmt/databases/$VDB_ID")
    #status=$(echo $DBINFO|grep -oP '("host":.*,"status":.*,"name":)'|cut -d, -f2|cut -d: -f2|tr -d '"')   
	status=$(echo $DBINFO|grep -oP '("status":.*,"name":)'|cut -d, -f1|cut -d: -f2|tr -d '"')
    echo $status
}

function startVoltdbInCreate() 
{
    RestExec "2" "/mgmt/databases/$VDB_ID/start" >/dev/null

    # timeout (5m) = sleep time (5s) * count (60)
    cnt=1  
    while [ $cnt -lt 61 ]; do
        echo `getVoltdbStatus`|grep 'ONLINE' >/dev/null 
        if [ $? -eq 0 ]; then
            return 0;
        fi
        cnt=$((cnt+1))
        sleep 10
    done
    return 1;
}

function ChekVoltDBStartSuccess()
{
    echo "" > ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh
	echo "export JAVA_HOME=$VOLTDB_JAVA_HOME " >> ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh
	echo "export PATH=$JAVA_HOME/bin:$PATH " >> ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh
	echo  "$VOLTDB_HOME/bin/sqlcmd --servers=$leader_node_external --port=$ORIGINAL_CLIENT_PORT --user=$VOLTDB_USER --password=$VOLTDB_PWD --query=\"exec @SystemInformation overview\"" >> ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh
	 scp ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh ${sshUser}@${leader_node_external}:${VOLTDBTMD} 2>&1 > /dev/null
	 ssh -nq ${sshUser}@${leader_node_external} "chmod +x ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh"
    cnt=1
	
	while [ $cnt -lt 61 ]; do
	    snapWriteLog "Checking the ${dbName} status ......"
	    ssh -nq ${sshUser}@${leader_node_external} "sh ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh"
        if [ $? -eq 0 ]; then
		    ssh -nq ${sshUser}@${leader_node_external} "rm -f ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh"
			snapWriteLog
			snapWriteLog "The ${dbName} database start successfully."
            return 0;
        fi
        cnt=$((cnt+1))
        sleep 10
    done
	ssh -nq ${sshUser}@${leader_node_external} "rm -f ${VOLTDBTMD}/voltdb_check_${PROCESS_NUM}.sh"
    return 1;
}

###############################################################################
# delete database in voltdb through rest api.
function dropDBInVoltDB
{
    DB_FLAG_NAME=$1    
	
    # get database name
	if [ $auto_uninstall -eq 1  ]; then
	    if [ -z $VOLTDB_INSTANCE_NAME ]; then
		    VOLTDB_INSTANCE_NAME=$DB_FLAG_NAME
		fi
	    VOLTDB_DB_NAME=$VOLTDB_INSTANCE_NAME
    else
	  snapEditValue "  * VoltDB database instance name" "$DB_FLAG_NAME" "VOLTDB_DB_NAME"
    fi	
	
	echo
	# get a host Ip of the database cluster
	if [ $auto_uninstall -eq 1  ]; then
	    if [ -z $VOLTDB_NODE_LIST ]; then
			snapWritelog "VOLTDB_NODE_LIST value is empty in the properties file, exit uninstall."
			snapExit
	    fi
	    CLUSTER_HOST_LIST=`echo $VOLTDB_NODE_LIST | awk -F: '{print $1}'`
		if [[ "$CLUSTER_HOST_LIST" =~ (.+)/(.*)/(.*)/(.*)/(.*) ]]; then
		       CLUSTER_HOST=${BASH_REMATCH[5]}
		elif [[ "$CLUSTER_HOST_LIST" =~ (.+)/(.*)/(.*)/(.*) || "$CLUSTER_HOST_LIST" =~ (.+)/(.*)/(.*) ]]; then
		       CLUSTER_HOST=${BASH_REMATCH[1]}
		fi
		
	else
		CLUSTER_HOST=
		while [ "x$CLUSTER_HOST" == "x" ]; do
			read -p "  * A host(admin interface) of the database cluster:" CLUSTER_HOST
		done
	fi	
	
	#if [ $auto_uninstall -eq 1  ]; then
	#    if [ -z $VOLTDB_SSH_USER ]; then
			VOLTDB_SSH_USER=$CURRENT_USER
	 #   fi
	 #   VOLTDB_SSH_USER=$VOLTDB_SSH_USER
	#else
	 #   snapEditValue "  * VoltDB database cluster ssh username" "$CURRENT_USER" "VOLTDB_SSH_USER"
	#fi
	
	# Don't need to remove anything trhough rest
    if [[ "$IS_ONLY_GENERATE_CATALOG" != "false" ]]; then 
        return;
    fi
	
	CheckInfoExist=`ssh -nq $VOLTDB_SSH_USER@$CLUSTER_HOST "ls $VOLTDB_HOME/.database.ini"`
	if [[ "$?" != "0" ]]; then
	    snapWriteLog "The .database.ini file does not exist in the $VOLTDB_HOME folder of $CLUSTER_HOST node!"
		snapExit
	fi
	
	CheckDatabaseInfo=`ssh -nq $VOLTDB_SSH_USER@$CLUSTER_HOST "cat $VOLTDB_HOME/.database.ini | grep '#$VOLTDB_DB_NAME '"`
	if [[ "$?" != "0" ]]; then
	    snapWriteLog "Have no $VOLTDB_DB_NAME database info in the .database.ini file!"
		snapExit
	else
	    #snapWriteLog "get the $VOLTDB_DB_NAME info is:"$CheckDatabaseInfo
		clusterhosts=`echo $CheckDatabaseInfo | awk '{print $2}'`
		clientport=`echo $CheckDatabaseInfo | awk '{print $4}'`
		adminport=`echo $CheckDatabaseInfo | awk '{print $5}'`
		adminuser=`echo $CheckDatabaseInfo | awk '{print $12}'`
		adminpwd=`echo $CheckDatabaseInfo | awk '{print $13}'`
		rootPath=`echo $CheckDatabaseInfo | awk '{print $3}'`
		adminpwd=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $adminpwd`
		#echo ==============$adminpwd
		#echo "$VOLTDB_HOME/bin/sqlcmd --servers=$CLUSTER_HOST --port=$adminport --user=$adminuser --password=$adminpwd --query=\"exec @SystemInformation overview\""
		CheckDatabaseExist=`$VOLTDB_HOME/bin/sqlcmd --servers=$CLUSTER_HOST --port=$adminport --user=$adminuser --password=$adminpwd --query="exec @SystemInformation overview"`
		if [[ "$?" != "0" ]]; then
		     snapWriteLog "The $VOLTDB_DB_NAME is not running, delete the database info from the .database.ini file!"
			 removeDatabaseInINIFile $clusterhosts $VOLTDB_SSH_USER $VOLTDB_DB_NAME 
		else
		    snapWriteLog "Shut down the database:"$VOLTDB_DB_NAME
			echo "" > /tmp/voltdb_delete_${PROCESS_NUM}.sh
	        echo "export JAVA_HOME=$VOLTDB_JAVA_HOME " >> /tmp/voltdb_delete_${PROCESS_NUM}.sh
			echo "export PATH=$JAVA_HOME/bin:$PATH " >> /tmp/voltdb_delete_${PROCESS_NUM}.sh
			echo "export LOG4J_CONFIG_PATH=${VOLTDBTMD}/voltdb_log4j.xml" >> /tmp/voltdb_delete_${PROCESS_NUM}.sh
			echo "${VOLTDB_HOME}/bin/voltadmin shutdown -H ${CLUSTER_HOST}:${adminport} -u ${adminuser} -p ${adminpwd} 2>&1 > /dev/null" >> /tmp/voltdb_delete_${PROCESS_NUM}.sh
			ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "mkdir -p ${VOLTDBTMD}"
			scp /tmp/voltdb_delete_${PROCESS_NUM}.sh ${VOLTDB_SSH_USER}@${CLUSTER_HOST}:${VOLTDBTMD} 2>&1 > /dev/null
			scp ${VOLTDBTMD}/voltdb_log4j.xml ${VOLTDB_SSH_USER}@${CLUSTER_HOST}:${VOLTDBTMD} 2>&1 > /dev/null
	        ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "chmod +x ${VOLTDBTMD}/voltdb_delete_${PROCESS_NUM}.sh"
			ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "sh ${VOLTDBTMD}/voltdb_delete_${PROCESS_NUM}.sh"
			#ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "rm -f ${VOLTDBTMD}/voltdb_delete_${PROCESS_NUM}.sh"
			if [ $debug -eq 0 ]; then 
                 ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "rm -rf ${VOLTDBTMD} 2>/dev/null"
            fi
			rm -f /tmp/voltdb_delete_${PROCESS_NUM}.sh
			#ssh -nq ${VOLTDB_SSH_USER}@${CLUSTER_HOST} "${VOLTDB_HOME}/bin/voltadmin shutdown -H ${CLUSTER_HOST}:${adminport} -u ${dbuser} -p ${dbpwd} 2>&1 > /dev/null" 
			removeDatabaseInINIFile $clusterhosts $VOLTDB_SSH_USER $VOLTDB_DB_NAME
			
		fi
		snapWriteLog "Delete the database root path:"$rootPath
		deleteRootPathInClusterNodes $clusterhosts $VOLTDB_SSH_USER $rootPath
		# delete the target directory
		deleteTargetFolderInClusterNodes $clusterhosts $VOLTDB_SSH_USER $VOLTDB_DB_NAME 
        #if [ -d $DBI_HOME/target/$VOLTDB_DB_NAME ]; then 
        #    rm -rf "$DBI_HOME/target/$VOLTDB_DB_NAME"
        #fi
	fi
	   
}

##############################################################################
# distribute the .database.ini to all of cluster node
function distributeDatabaseInfo
{
    clusterhosts=$1
	sshuser=$2
	specialnode=$3
	
	for clusternode in `echo $clusterhosts | awk 'BEGIN{FS=","}{for (i=1; i<NF; i++) print $i}' 2>/dev/null` ; do
		ssh -nq $sshuser@$specialnode "scp $VOLTDB_HOME/.database.ini ${sshuser}@${clusternode}:$VOLTDB_HOME 2>&1 > /dev/null"
	done
	
}

function removeDatabaseInINIFile
{
    clusterhosts=$1
	sshuser=$2
	voltdb_name=$3
	 
	for clusternode in `echo $clusterhosts | awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
	    clusternode_host=`echo $clusternode | awk -F/ '{print $1}'`
		ssh -nq ${sshuser}@${clusternode_host} "sed -i '/${voltdb_name}/d' $VOLTDB_HOME/.database.ini"
	done 
}

##############################################################################
# delete rootpath of all cluster nodes
function deleteRootPathInClusterNodes
{
    clusterhosts=$1
	sshuser=$2
	rootpath=$3
	
	for clusternode in `echo $clusterhosts | awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
	    clusternode_host=`echo $clusternode | awk -F/ '{print $1}'`
		ssh -nq $sshuser@$clusternode_host "rm -fr $rootpath 2>&1 > /dev/null"
	done
}

##############################################################################
# delete rootpath of all cluster nodes
function deleteTargetFolderInClusterNodes
{
    clusterhosts=$1
	sshuser=$2
	voltdb_name=$3
	
	for clusternode in `echo $clusterhosts | awk 'BEGIN{FS=","}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
	    clusternode_host=`echo $clusternode | awk -F/ '{print $1}'`
		ssh -nq $sshuser@$clusternode_host "rm -fr $DBI_HOME/target/$voltdb_name 2>&1 > /dev/null"
	done
}


###############################################################################
# check Mysql environment 
function checkMysqlEnv
{
    SNAP_MYSQL_HOME=$MYSQL_HOME
	if [ $silent -eq 1 -o $auto_uninstall -eq 1 ]; then
	     if [ ! -z $MYSQL_HOME_DIRECTORY ]; then
		    SNAP_MYSQL_HOME=$MYSQL_HOME_DIRECTORY
		 fi
    else
	   snapEditValue "  * MySQL home directory" "$SNAP_MYSQL_HOME" "SNAP_MYSQL_HOME"
    fi
    
    if [ ! -f $SNAP_MYSQL_HOME/bin/mysql ]; then
        snapWriteLog "ERROR: The following mysql command does not exist:"
        snapWriteLog "       $SNAP_MYSQL_HOME/bin/mysql"
        snapWriteLog
        snapExit
    fi
    export PATH=$MYSQL_HOME/bin:$PATH

	
    
    SNAP_MYSQL_PORT="3306"
	SNAP_MYSQL_ADMIN="siu20"
	SNAP_MYSQL_DBAPASS="siu20"
	SNAP_MYSQL_HOST=$HOSTNAME
	if [ $silent -eq 1 -o $auto_uninstall -eq 1 ]; then
	    if [ ! -z $MYSQL_DATABASE_HOST ]; then
		    SNAP_MYSQL_HOST=$MYSQL_DATABASE_HOST
		fi
	    if [ ! -z $MYSQL_DATABASE_PORT ]; then
		    SNAP_MYSQL_PORT=$MYSQL_DATABASE_PORT
		fi
		if [ ! -z $MYSQL_DATABASE_DBA_USERNAME ]; then
		    SNAP_MYSQL_ADMIN=$MYSQL_DATABASE_DBA_USERNAME
		fi
		if [ ! -z $MYSQL_DATABASE_DBA_PASSWORD ]; then
		    SNAP_MYSQL_DBAPASS=$MYSQL_DATABASE_DBA_PASSWORD
		fi
    else
	    # get mysql host
	    snapEditValue "  MySql database host" "$SNAP_MYSQL_HOST" "SNAP_MYSQL_HOST"
		
	    # get mysql port
		snapEditValue "  MySql database port" "$SNAP_MYSQL_PORT" "SNAP_MYSQL_PORT"
		
		# get mysql database dba user name
		snapEditValue "  * MySql database dba user name" "$SNAP_MYSQL_ADMIN" "SNAP_MYSQL_ADMIN"
		
		# get mysql database administrator user password
		snapEditPassword "  * MySql database dba password" "$SNAP_MYSQL_DBAPASS" "SNAP_MYSQL_DBAPASS"
    fi
	
	SNAP_MYSQL_DBAPASS=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $SNAP_MYSQL_DBAPASS`
	
	#echo ========$SNAP_MYSQL_DBAPASS
	
 
    # check mysql login
    SNAP_MYSQL_CMD="$SNAP_MYSQL_HOME/bin/mysql -h$SNAP_MYSQL_HOST -P $SNAP_MYSQL_PORT -u $SNAP_MYSQL_ADMIN -p$SNAP_MYSQL_DBAPASS"
    echo "" >$SNAPTMP
    $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>/dev/null
    if [ $? -ne 0 ]; then
        snapWriteLog "  ERROR: mysql login failed with dba user: $SNAP_MYSQL_ADMIN"
        snapWriteLog
        snapExit
    fi
}

function createDBInMysql
{
    # get database name
	if [ $silent -eq 1  ]; then
	   if [ ! -z $MYSQL_DATABASE_NAME ]; then
	       SNAP_MYSQL_DB=$MYSQL_DATABASE_NAME
	   fi
    else
	  snapEditValue "  * MySql database name" "$SNAP_MYSQL_DB" "SNAP_MYSQL_DB"
    fi
    

    # check database
    if [ "$SNAP_MYSQL_DB" != "siu20" ]; then
        echo "use $SNAP_MYSQL_DB;" >$SNAPTMP
        $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>/dev/null
        if [ $? -eq 0 ]; then
            snapWriteLog "WARN: Mysql database \"$SNAP_MYSQL_DB\" already exists."
			if [ $silent -ne 1  ]; then
			    snapContinue " Drop it and create it again, "
		    else
                 snapWriteLog " Please you uninstall the database \"$SNAP_MYSQL_DB\" firstly."
				 snapWriteLog
                 snapExit				 
			fi
            echo "drop database $SNAP_MYSQL_DB;" >$SNAPTMP
            $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
            if [ $? -ne 0 ]; then
                snapWriteLog "ERROR: Failed to drop old database $SNAP_MYSQL_DB"
                snapWriteLog
                snapExit
            else
                snapWriteLog "INFO: Old database $SNAP_MYSQL_DB is successfully dropped!"
                snapWriteLog
            fi
        fi
        # create new database
        echo "create database $SNAP_MYSQL_DB;" >$SNAPTMP
        $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
        if [ $? -ne 0 ]; then
            snapWriteLog "ERROR: Failed to create database $SNAP_MYSQL_DB"
            snapWriteLog
            snapExit
        else
            snapWriteLog "INFO: Database $SNAP_MYSQL_DB is successfully created!"
            snapWriteLog
        fi
    fi
}

function createUserInMysql
{
    # get mysql database user name
	if [ $silent -eq 1  ]; then
	   if [ ! -z $MYSQL_DATABASE_USERNAME ]; then
	       SNAP_MYSQL_USER=$MYSQL_DATABASE_USERNAME
	   fi
    else
	   snapEditValue "  * MySql database user name" "$SNAP_MYSQL_USER" "SNAP_MYSQL_USER"
    fi
    
    # check user
    echo "select count(*) from mysql.user where User = '$SNAP_MYSQL_USER';" >$SNAPTMP
    $SNAP_MYSQL_CMD < $SNAPTMP >"$SNAPTM1" 2>&1
    SNAP_CNT=$(tail -1 $SNAPTM1)
    cat $SNAPTM1 >>$SNAPLOG
    if [ "$SNAP_CNT" != "0" ]; then
        snapWriteLog "WARN: Mysql user $SNAP_MYSQL_USER already exists."
		if [ $silent -ne 1  ]; then
		     snapContinue "   Drop it and create it again, "
		fi 
        echo "drop user $SNAP_MYSQL_USER;" >$SNAPTMP
		echo "drop user $SNAP_MYSQL_USER@localhost;" >>$SNAPTMP
        $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
        if [ $? -ne 0 ]; then
            snapWriteLog "ERROR: Failed to drop user $SNAP_MYSQL_USER"
            snapWriteLog
            snapExit
        else
            snapWriteLog "INFO: Mysql user $SNAP_MYSQL_USER is successfully dropped!"
            snapWriteLog
        fi
    fi
    # get mysql database user password
    #SNAP_MYSQL_PASS="$SNAP_MYSQL_USER"
	SNAP_MYSQL_PASS=
	if [ $silent -eq 1  ]; then
	   if [ ! -z $MYSQL_DATABASE_PASSWORD ]; then
	       SNAP_MYSQL_PASS=$MYSQL_DATABASE_PASSWORD
	   else
	       SNAP_MYSQL_PASS="$SNAP_MYSQL_USER"
	   fi
    else
	   snapEditValue "  * MySql database user password" "$SNAP_MYSQL_PASS" "SNAP_MYSQL_PASS"
    fi
    
	SNAP_MYSQL_PASS=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool decrypt $SNAP_MYSQL_PASS`

	 #echo ---------$SNAP_MYSQL_PASS
	
    # create new user
    echo "create user $SNAP_MYSQL_USER identified by '$SNAP_MYSQL_PASS';" >$SNAPTMP
    echo "GRANT ALL ON $SNAP_MYSQL_DB.* TO '$SNAP_MYSQL_USER'@'%' IDENTIFIED BY '$SNAP_MYSQL_PASS' WITH GRANT OPTION;;" >>$SNAPTMP
	echo "GRANT ALL ON $SNAP_MYSQL_DB.* TO '$SNAP_MYSQL_USER'@'localhost' IDENTIFIED BY '$SNAP_MYSQL_PASS' WITH GRANT OPTION;;" >>$SNAPTMP
    $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
    if [ $? -ne 0 ]; then
        snapWriteLog "ERROR: Failed to create user $SNAP_MYSQL_USER"
        snapWriteLog
        snapExit
    else
        snapWriteLog "INFO: Mysql user $SNAP_MYSQL_USER is successfully created!"
        snapWriteLog
    fi
}

###############################################################################
# create datasource in Mysql 
function runSqlsInMysql
{
    # check table exist or not. This is because if default siu20 database is used
    # data was imported before
    SNAP_TABLE=$(grep "create table" $1 |head -1|awk '{print $3}') 
    echo "use $SNAP_MYSQL_DB;" >$SNAPTMP
    echo "select * from $SNAP_TABLE;" >>$SNAPTMP
    $SNAP_MYSQL_CMD < $SNAPTMP >"$SNAPTM1" 2>&1
    if [ $? -eq 0 ]; then
        snapWriteLog "ERROR: SNAP tables already exist."
        snapWriteLog
        snapExit
    fi

    # add use database first
    echo "use $SNAP_MYSQL_DB;" >$SNAPTMP
    echo "set autocommit=0;" >>$SNAPTMP
    cat $1 >>$SNAPTMP
    echo "commit;"  >>$SNAPTMP

    # execute script
    $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
    SNAPRES="$?"
    if [[ "$SNAPRES" != "0" ]]
    then
        snapWriteLog
        snapWriteLog "ERROR: Script '$1' failed with error '$SNAPRES'."
        snapExit
    else
        snapWriteLog
        snapWriteLog "INFO: Script '$1' successfully imported."
    fi
}

###############################################################################
# drop db in mysql
function dropDBInMysql
{
    # get database name
	if [ $auto_uninstall -eq 1  ]; then
	   if [ ! -z $MYSQL_DATABASE_NAME ]; then
	       SNAP_MYSQL_DB=$MYSQL_DATABASE_NAME
	   fi
    else
	  snapEditValue "  * MySql database name" "$SNAP_MYSQL_DB" "SNAP_MYSQL_DB"
    fi
    
    # check database
    if [ "$SNAP_MYSQL_DB" != "siu20" ]; then
        echo "use $SNAP_MYSQL_DB;" >$SNAPTMP
        $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>/dev/null
        if [ $? -ne 0 ]; then
            snapWriteLog "WARN: Mysql database \"$SNAP_MYSQL_DB\" doesn't exists."
            snapWriteLog "      Do not need to remove it."
        else
		    if [ $auto_uninstall -ne 1  ]; then
                snapContinue "Drop the database [$SNAP_MYSQL_DB], "
			fi
            # drop database
            echo "drop database $SNAP_MYSQL_DB;" >$SNAPTMP
            $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
            if [ $? -ne 0 ]; then
                snapWriteLog "ERROR: Failed to drop old database $SNAP_MYSQL_DB"
                snapWriteLog
                snapExit
            else
                snapWriteLog "INFO: Old database $SNAP_MYSQL_DB is successfully dropped!"
                snapWriteLog
            fi
        fi
    fi
}

###############################################################################
# drop user in mysql
function dropUserInMysql
{
    # get user name
	if [ $auto_uninstall -eq 1  ]; then
	   if [ ! -z $MYSQL_DATABASE_USERNAME ]; then
	       SNAP_MYSQL_USER=$MYSQL_DATABASE_USERNAME
	   fi
    else
	   snapEditValue "  * MySql database user name" "$SNAP_MYSQL_USER" "SNAP_MYSQL_USER"
    fi
    
    # check user
    echo "select count(*) from mysql.user where User = '$SNAP_MYSQL_USER';" >$SNAPTMP
    $SNAP_MYSQL_CMD < $SNAPTMP >"$SNAPTM1" 2>&1
    SNAP_CNT=$(tail -1 $SNAPTM1)
    cat $SNAPTM1 >>$SNAPLOG
    if [ "$SNAP_CNT" = "0" ]; then
        snapWriteLog "WARN: Mysql user $SNAP_MYSQL_USER doesn't exists."
        snapWriteLog "      Do not need to drop it."
    else
	    if [ $auto_uninstall -ne 1  ]; then
			snapContinue "Drop the database user name [$SNAP_MYSQL_USER], "
        fi
		echo "drop user $SNAP_MYSQL_USER;" >$SNAPTMP
		echo "drop user ${SNAP_MYSQL_USER}@localhost;" >>$SNAPTMP
        $SNAP_MYSQL_CMD < $SNAPTMP >>"$SNAPLOG" 2>&1
        if [ $? -ne 0 ]; then
            snapWriteLog "ERROR: Failed to drop user $SNAP_MYSQL_USER"
            snapWriteLog
            snapExit
        else
            snapWriteLog "INFO: Mysql user $SNAP_MYSQL_USER is successfully dropped!"
            snapWriteLog
        fi
    fi
}

###############################################################################
# calculate the path in different databases and find regarding applications
findApps () {
    REAL_NAME=
    case "$DB_NAME" in
        1) REAL_NAME="snap_db";;
        2) REAL_NAME="spr_db";;
        3) REAL_NAME="session_db";;
        4) REAL_NAME="lb_db";;
        5) REAL_NAME="cdr_db";;
        *) echo "Invalid Option";;
    esac
   # echo 'DB_NAME='$DB_NAME
    
    APPS=`cd $1; find . -type d |grep "\/${REAL_NAME}\/" |grep -v 'common'|awk -F/ '{print $3}'|sort|uniq|while read a; do printf '%s:' $a; done`
    	
    APPS="common:${APPS}"
	#echo "==============done APPS:"${APPS}
	
	for opt in `echo $APPS|awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
         if [ "${opt}"x = "abm"x ]; then
		     ABM_EXPORT_ENABLE="true"
		 fi
		 CHOSED_APPS=(${CHOSED_APPS[@]} "${opt}")
    done
   
   #echo "========CHOSED_APPS is:"${CHOSED_APPS[@]}
	
}

###############################################################################
# transform the app codes to the complete menu options
getAppMenuOpts() {
    MENU_OPTS=
    U_APPS=`echo $1|tr '[:lower:]' '[:upper:]'`
    for opt in `echo $U_APPS|awk 'BEGIN{FS=":"}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null` ; do
	    eval menu_desc=\$$opt
        if [[ "$?" != "0" || "x$menu_desc" = "x" ]]; then 
            menu_desc=`echo $opt|tr '[:upper:]' '[:lower:]'`
        fi
        MENU_OPTS="${MENU_OPTS}:${menu_desc}"
    done
    MENU_OPTS=`echo ${MENU_OPTS}|cut -c2-`
	#echo "=====menu options"$MENU_OPTS
}

###############################################################################
# $1-db name; $2-db type; $3-acceptted sql pattern; $4-denied sql pattern. 
function getAppSqls 
{
    CHOSED_APP_SQLS=()
    for (( i=0; i < ${#CHOSED_APPS[@]}; i++ )); do 
        app=${CHOSED_APPS[i]} 
        if [ "$app" = "common" ]; then 
            continue
        fi
		if [ -d $DBI_SCRIPTS/"$1"/"$app"/"$2" ]; then
			for file in `find $DBI_SCRIPTS/"$1"/"$app"/"$2" -name "$3"|grep -v "$4"|sort 2>/dev/null`; do 
				CHOSED_APP_SQLS=(${CHOSED_APP_SQLS[@]} "$file")
			done 
		fi
    done 
}

#################################################################################
# $1-db name; $2-db type; $3-accept jar file;
function getAppSPJars
{
    CHOSED_APP_JARS=()
	SP_JARS=
	for (( i=0; i < ${#CHOSED_APPS[@]}; i++ )); do 
	    app=${CHOSED_APPS[i]}
		#echo "=============="$app
		if [ -d $DBI_SCRIPTS/$1/$app/$2/sp_jars ]; then
		    for file in `find $DBI_SCRIPTS/"$1"/"$app"/"$2"/sp_jars -name "$3"`; do
			     #echo "=========="$file
			    CHOSED_APP_JARS=(${CHOSED_APP_JARS[@]} "$file")
			done
		fi
	done
	#echo "------------------"${CHOSED_APP_JARS},${#CHOSED_APP_JARS[@]}
	for (( i=0; i < ${#CHOSED_APP_JARS[@]}; i++ )); do 
	    jarname=${CHOSED_APP_JARS[i]}
		SP_JARS=$SP_JARS":"$jarname
	done
	
}

###############################################################################
# $1-db name; $2-db type; $3-acceptted sql pattern; $4-denied sql pattern. 
function getIntegrationAppSqls 
{
    CHOSED_APP_SQLS=()
    for (( i=0; i < ${#CHOSED_APPS[@]}; i++ )); do 
        app=${CHOSED_APPS[i]} 
        if [ "$app" != "upm_ocs_integration" ]; then 
            continue
        fi
        for file in `find $DBI_SCRIPTS/"$1"/"$app"/"$2" -name "$3"|grep -v "$4"|sort 2>/dev/null`; do 
            CHOSED_APP_SQLS=(${CHOSED_APP_SQLS[@]} "$file")
        done 
    done 
}

###################################################################################
function getCommonSchema
{
     if [ -d "$DBI_SCRIPTS/${DB_FLAG_NAME}/common/voltdb" ]; then
	        for file in `find "$DBI_SCRIPTS/${DB_FLAG_NAME}/common/voltdb/ddc" -name '*.vdbcfg'`; do cp -t "$VOLTDBTMD/ddc" $file; done
			for file in `find $DBI_SCRIPTS/${DB_FLAG_NAME}/common/voltdb -name '*.sql'`; do cat $file >> "$VOLTDBTMD/${VOLTDB_DB_NAME}.sql"; done
	 fi
}

###################################################################################
# $1- A node external IP
function getPlacementGroupName
{
   node_external_interface=$1
   matched_group_name=""
   placement_group=""
   #echo "VOLTDB_PLACEMENT_GROUPS is:"$VOLTDB_PLACEMENT_GROUPS
   for groupmap in ` echo $VOLTDB_PLACEMENT_GROUPS | awk 'BEGIN{FS=";"}{for (i=1; i<=NF; i++) print $i}' 2>/dev/null`; do
	   external=`echo ${groupmap} | awk -F ':' '{print $1}'`
	   groupname=`echo ${groupmap} | awk -F ':' '{print $2}'`
	   if [ $node_external_interface == $external ]; then
	       matched_group_name=$groupname
	   fi
   done
   if [ "x$matched_group_name" != "x" ]; then
        placement_group="--placement-group=$matched_group_name"
   fi
   echo "the group name is:"$placement_group
}

###############################################################################
# $1-db name; $2-db type; $3-acceptted sql pattern; $4-denied sql pattern. 
function getCommonDynamicSqls
{
    CHOSED_COMMON_SQLS=()
    T_DIR="$DBI_SCRIPTS/$1/common/$2"
    for file in `find "$T_DIR" -path "$T_DIR/$3"|grep -v "$4"|sort 2>/dev/null`; do 
        CHOSED_COMMON_SQLS=(${CHOSED_COMMON_SQLS[@]} "$file")
    done 
}

##--REUSED PART END--
#Warning: Please won't remove/modify above flag comment!!!!

#######################################################################
# main program (don't remove, it's import flag)
#######################################################################
# Default options
uninstall=0
debug=0
silent=0
auto_uninstall=0
CURRENT_USER=$(whoami)
ABM_EXPORT_ENABLE="false"
VOLTDB_SSH_USER=$(whoami)

snapWriteLog "unset http_proxy https_proxy"
unset http_proxy https_proxy

# parse command line
set -- `getopt hus $*`
# check result of parsing
if [ "$?" != "0" ]; then 
    snapUsage && snapExit
fi

while [ $1 != -- ]; do
    case $1 in
        -h) snapUsage && snapExit ;;
        -u) uninstall=1;; 
		-s) silent=1;;
    esac
    shift
done
shift # skip double dash (if any)

if [ $silent -eq 1  ]; then
     if [ ! -f $1 ]; then
	     snapWriteLog "The $1 configuration file does not exist!"
		 snapExit
	 fi
     PROP_Content=`cat $1 | sed '/#/d'`
	 readCommonProperty "$PROP_Content"
	 case $DATABASE_TYPE in
        Mysql|mysql)  readMySQLProperty "$PROP_Content";;
        Voltdb|voltdb|VoltDB) readVoltDBProperty "$PROP_Content";;					  
        *) snapWriteLog "Invaild DB Type, please check the 'DATABASE_TYPE' configuration item."
		   snapExit;;
     esac
fi

snapWriteLog
if [ $uninstall -ne 1  ]; then
    snapWriteLog "This tool used to create databases for SNAP applications."
else
    snapWriteLog "This tool used to drop databases for SNAP applications."
	if [ "x$1" != "x" ]; then 
	    if [ ! -f $1 ]; then
	       snapWriteLog "The $1 configuration file does not exist!"
		    snapExit
	    fi
	    auto_uninstall=1 
		PROP_Content=`cat $1 | sed '/#/d'`
		 readCommonProperty "$PROP_Content"
		 case $DATABASE_TYPE in
			Mysql|mysql)  readMySQLProperty "$PROP_Content";;
			Voltdb|voltdb|VoltDB) readVoltDBProperty "$PROP_Content";;					  
			*) snapWriteLog "Invaild DB Type, please check the 'DATABASE_TYPE' configuration item."
			   snapExit;;
		 esac
	fi	 
fi

CHOSED_APPS=()

   CLASSPATH=.:$EIUM_VOLTDB_TOOL:${EIUM_HOME}/lib/datastruct-api.jar:
   CLASSPATH=${CLASSPATH}`find "${EIUM_HOME}/lib" -name '*.jar'|tr '\n' :`
   CLASSPATH=${CLASSPATH}`find "${EIUM_VOLTDB_TOOL}/lib" -name '*.jar'|grep -v org.slf4j.slf4j-log4j12.jar|tr '\n' :`
   CLASSPATH=${CLASSPATH}`find "${RTP_HOME}/virgo/repository/snap" -name '*.jar'|tr '\n' :`
   CLASSPATH=${CLASSPATH}`find "${DBI_LIB}" -name '*.jar'|tr '\n' :`
   CLASSPATH=${CLASSPATH}`find "$DBI_HOME/../../repository" -name '*.jar'|grep -v jdbccfg|tr '\n' :`

# Select database name
if [ $silent == 1 -o $auto_uninstall == 1 ]; then
   findConfigDBName "${DATABASE_NAME}"
else
    makeDBNameChoice
fi

# select voltdb working model
if [ $uninstall -ne 1  ]; then
    if [ $silent -eq 1 ]; then
	     DB_MODEL=$VOLTDB_WORK_MODEL
	else
        if [ $DB_NAME == 2 -o $DB_NAME == 3 ]; then
            selectVoltDBWorkModel
        fi
	fi	
fi
	 


# In uninstall mode, the app won't be selected
if [ $uninstall -ne 1 ]; then
    findApps  "$DBI_SCRIPTS"
   # snapWriteLog "Chosen applications: ${CHOSED_APPS[@]}"
fi

DB_TYPE=1
# Select regarding database type
#if [ $silent -eq 1  ]; then
#     findDBType $DATABASE_TYPE
#  else
#    makeDBTypeChoice
#fi  


snapWriteLog
case "$DB_NAME" in
    1) # snapDB
        case "$DB_TYPE" in 
            1) # MySQL
                checkMysqlEnv
                SNAP_MYSQL_DB="snap" 
                SNAP_MYSQL_USER="snap_user" 
                
                if [ $uninstall -eq 1 ]; then
                    snapWriteLog "Try to uninstall database [snapDB] on MySQL"
                    dropDBInMysql && dropUserInMysql
                else
                    snapWriteLog "Try to install database [snapDB] on MySQL"
                    createDBInMysql && createUserInMysql &&    \
                        runSqlsInMysql $DBI_SCRIPTS/snap_db/common/mysql/snap_db_mysql.sql

                    # app common may also put some dynamic sqls
                    getCommonDynamicSqls "snap_db" "mysql" "[0-9]*.sql" "dummy"
                    for (( i=0 ; i < ${#CHOSED_COMMON_SQLS[@]} ; i++ )); do  
                        runSqlsInMysql "${CHOSED_COMMON_SQLS[i]}"
                    done  

                    # application related db scripts
                    getAppSqls "snap_db" "mysql" "*.sql" "Sample"
                    for (( i=0 ; i < ${#CHOSED_APP_SQLS[@]} ; i++ )); do  
                        runSqlsInMysql "${CHOSED_APP_SQLS[i]}" 
                    done  
					
					snapWriteLog
					snapWriteLog "create fsm_timer table on Mysql"
					aa=`${EIUM_HOME}/bin/migratedb connect -dbUrl jdbc:mysql://${SNAP_MYSQL_HOST}:${SNAP_MYSQL_PORT}/${SNAP_MYSQL_DB} -dbUser ${SNAP_MYSQL_USER} -dbPassword ${SNAP_MYSQL_PASS} -- update -changeLogFile com/hp/usage/db/migration/changelogs/other/fsm-timer.xml 2>&1 >>"$SNAPLOG" `
					echo "$aa" >> "$SNAPLOG"
					echo "select count(*) from mysql.innodb_table_stats where database_name='${SNAP_MYSQL_DB}' and table_name='fsm_timer'" >$SNAPTMP
					$SNAP_MYSQL_CMD < $SNAPTMP >"$SNAPTM1" 2>&1
					SNAP_CNT=$(tail -1 $SNAPTM1)
					if [ "$SNAP_CNT" == "0" ]; then
					    snapWriteLog
					    snapWriteLog "Generate fsm_timer table failed, output log is in file '$SNAPLOG'."
					else
					    snapWriteLog
					    snapWriteLog "Generate fsm_timer table successfully."
					fi
                fi
                ;;
            *) snapWriteLog "Invalid Option";;
        esac
        ;;
    2) # sprDB
        case "$DB_TYPE" in 
            1) # VoltDB
                checkVoltDBEnv "spr_db"

                VOLTDB_USER="spr_user"
                if [ $uninstall -eq 1 ]; then
                    snapWriteLog "Try to uninstall database [sprDB] on VoltDB"
                    dropDBInVoltDB "spr_db"
                else 
                    snapWriteLog "Try to install database [sprDB] on VoltDB"
                    createDBInVoltDB "spr_db" "1" 
                fi
                ;;
            *) snapWriteLog "Invalid Option";;
        esac
        ;;
    3) # sessionDB
        case "$DB_TYPE" in 
            1) # VoltDB
                checkVoltDBEnv "session_db"

                VOLTDB_USER="session_user"
                if [ $uninstall -eq 1 ]; then
                    snapWriteLog "Try to uninstall database [sessionDB] on VoltDB"
                    dropDBInVoltDB "session_db"
                else 
                    snapWriteLog "Try to install database [sessionDB] on VoltDB"
                    createDBInVoltDB "session_db" "2" 
                fi
                ;;
            *) snapWriteLog "Invalid Option";;
        esac
        ;;
    
esac

# Output location of log file and exit.
if [ $debug -eq 0 ]; then 
    rm -f $SNAPTMP $SNAPTM1 $SNAPTM2 $SNAPTM3 $SNAPTM4 $SNAPTM5 
fi
snapWriteLog
snapWriteLog "DB operation successful!"
echo ""
echo "Finished executing the script, output log is in file '$SNAPLOG'."
cp $SNAPLOG ${SNAPDIR}/${SNAPNAM}.log
snapWriteLog
