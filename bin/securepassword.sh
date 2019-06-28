#!/bin/bash
###############################################################################
#
# securepassword.sh
#
# encrypt the password plain text
#
###############################################################################


SNAPNAM=$(basename "$0" ".sh")
SNAPDIR=$(dirname "$0")
if [[ "$(echo $SNAPDIR | cut -c1)" != "/" ]]; then SNAPDIR="$PWD/$SNAPDIR"; fi
SNAPDIR="$(cd "$SNAPDIR"; echo $PWD)";

EIUM_MAIN=`echo $SNAPDIR | awk -F/ '{print $3}'`
EIUM_HOME=/opt/$EIUM_MAIN

DBI_HOME="$(cd "$SNAPDIR/.."; echo $PWD)"
DBI_BIN="$DBI_HOME/bin"
DBI_SCRIPTS="$DBI_HOME/dbscripts"
DBI_TPL="$DBI_HOME/template"
DBI_CONF="$DBI_HOME/config"
DBI_LIB="$DBI_HOME/lib"

RTC_HOME=${DBI_HOME}/../../
RTP_HOME=${EIUM_HOME}/RTP
EIUM_VOLTDB_TOOL=${RTC_HOME}/tools/vdbtool

DATABASE_WORK_MODEL=none


CLASSPATH=.:$EIUM_VOLTDB_TOOL:${EIUM_HOME}/lib/datastruct-api.jar:
CLASSPATH=${CLASSPATH}`find "${EIUM_HOME}/lib" -name '*.jar'|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "${EIUM_VOLTDB_TOOL}/lib" -name '*.jar'|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "${RTP_HOME}/virgo/repository/snap" -name '*.jar'|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "${DBI_LIB}" -name '*.jar'|tr '\n' :`
CLASSPATH=${CLASSPATH}`find "$DBI_HOME/../../repository" -name '*.jar'|tr '\n' :`

if [ -z $1 ]; then
    echo "Usage securepassword.sh <plain text>"
	exit 0
elif [ $1 == '-h' ]; then
     echo "Usage securepassword.sh <plain text>"
	exit 0
else	
    SNAP_encrypt_PASS=`${JAVA_HOME}/bin/java -cp "${CLASSPATH}" com.hp.atom.vdb.tools.PasswdTool encrypt $1`
    echo "encrypt the '$1' is $SNAP_encrypt_PASS"
fi
