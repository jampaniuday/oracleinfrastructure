#!/bin/bash
# 

# General variables
PWD_FILE=/home/orainf/.passwords

# Local variables
TMP_LOG_DIR=/tmp/oi_conf
LOCKFILE=$TMP_LOG_DIR/lock_sql
CONFIG_FILE=$TMP_LOG_DIR/ldap_out_sql.txt
D_CVS_REPO=$HOME/conf_repo

INFO_MODE=DEBUG


# Load usefull functions
if [ ! -f $HOME/scripto/bash/bash_library.sh ]; then
  echo "[error] $HOME/scripto/bash/bash_library.sh not found. Exiting. "
  exit 1
else
  . $HOME/scripto/bash/bash_library.sh
fi


mkdir -p $TMP_LOG_DIR
check_directory "$TMP_LOG_DIR"
check_directory $D_CVS_REPO

# Sanity check
check_lock $LOCKFILE

# functions
f_store_sql_output_in_file()
{
  msgd "${FUNCNAME[0]} Begin."

  CONFIG_FILE=$1
  V_SQL=$2
  V_NAME=$3

  F_TMP=$TMP_LOG_DIR/sql.tmp

  msgd "CONFIG_FILE: $CONFIG_FILE"
  check_file $CONFIG_FILE
  msgd "V_SQL: $V_SQL"
  check_parameter $V_SQL
  msgd "V_NAME: $V_NAME"
  check_parameter $V_NAME

  msgd "Look through the provided targets"
  while read LINE
  do
    echo $LINE
    CN=`echo $LINE | awk '{print $1}'` 
    msgd "CN: $CN"
    check_parameter $CN

    V_USER=`echo $LINE | awk '{print $2}'`
    msgd "V_USER: $V_USER"
    check_parameter $V_USER

    INDEX_HASH=`echo $LINE | awk '{print $3}'`
    msgd "INDEX_HASH: $INDEX_HASH"
    HASH=`echo "$INDEX_HASH" | base64 --decode -i`
    msgd "HASH: $HASH"
    if [ -f "$PWD_FILE" ]; then
      V_PASS=`cat $PWD_FILE | grep $HASH | awk '{print $2}' | base64 --decode -i`
      #msgd "V_PASS: $V_PASS"
    else
      msge "Unable to find the password file. Exiting"
      exit 0
    fi

    # OK, I have username, password and the database, it is time to connect
    testavail=`sqlplus -S /nolog <<EOF
set head off pagesize 0 echo off verify off feedback off heading off
connect $V_USER/$V_PASS@$CN
select trim(1) result from dual;
exit;
EOF`

    if [ "$testavail" != "1" ]; then
      msge "DB $CN not available, exiting !!"
      exit 0
    fi

    sqlplus -s /nolog << EOF > $F_TMP
    set head off pagesize 0 echo off verify off feedback off heading off
    set linesize 200
    connect $V_USER/$V_PASS@$CN
    $V_SQL
EOF
#    run_command_d "cat $F_TMP"

    run_command "cp $F_TMP $D_CVS_REPO/$CN/$V_NAME"
    run_command "cd $D_CVS_REPO/$CN"
    cvs add $V_NAME > /dev/null 2>&1
    cvs commit -m "Autocommit for $CN" $V_NAME


#WIP



exit 0
  done < $CONFIG_FILE


  msgd "${FUNCNAME[0]} End."
} #f_store_sql_output_in_file


# Actual execution
msgd "Ask the ldap for all the hosts to chec. We check there where init files are monitored"

$HOME/scripto/perl/ask_ldap.pl "(orainfDbInitFile=*)" "['cn', 'orainfDbRrdoraUser', 'orainfDbRrdoraIndexHash']" > $CONFIG_FILE

check_file $CONFIG_FILE
run_command_d "cat $CONFIG_FILE"

# Execute main function used, where parameters mean:
# - file with target attributes
# - SQL to be executed
# - output file name
f_store_sql_output_in_file $CONFIG_FILE "select BUG_NUMBER from APPLSYS.AD_BUGS where ARU_RELEASE_NAME not in ('11i') order by BUG_NUMBER;" "AD_BUGS.txt"
f_store_sql_output_in_file $CONFIG_FILE "SELECT sql_handle, plan_name, creator, origin  FROM dba_sql_plan_baselines order by sql_handle;" "SPM.txt"

# On exit remove lock file
rm -f $LOCKFILE
