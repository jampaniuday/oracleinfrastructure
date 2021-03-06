#!/bin/bash
#$Id$
#
# /tmp/ala.txt - file that lists snaps, result of
# > spool /tmp/ala.txt
#> @?/rdbms/admin/awrrpt.sql
#Enter value for report_type: text
#Enter value for num_days: 30
#
# username, you will be asked for password
# Example
# $ ./01_bulk_generate.sh /tmp/ala.txt rboguszewicz 10:00 12:00 8
#
# Optionaly add at the end date from which to start
# $ ./01_bulk_generate.sh EBSDB4 apps 08:00 16:00 8 2015-08-12

# Load usefull functions
V_INTERACTIVE=1

check_parameter()
{
  check_variable "$1" "$2"
}

check_variable()
{
  if [ -z "$1" ]; then
    error_log "[ check_variable ] Provided variable ${2} is empty. Exiting. " ${RECIPIENTS}
    exit 1
  fi
}

error_log()
{
  echo "[ error ]["`hostname`"]""["$0"]" $1
  MSG=$1
  shift
  for i in $*
  do
    if `echo ${i} | grep "@" 1>/dev/null 2>&1`
    then
      echo "[ info ] Found @ in adress, sending above error to ${i}"
      $MAILCMD -s "[error]["`hostname`"]""["$0"] ${MSG}" ${i} < /dev/null > /dev/null
    else
      echo "[ info ] Not found @ in adress, sending above error to ${i}@orainf.com"
      $MAILCMD -s "[ error ]["`hostname`"]""["$0"] ${MSG}" ${i}@orainf.com < /dev/null > /dev/null
    fi
    shift
  done
}

msgb()
{
  if [ "$INFO_MODE" = "DEBUG" ] ; then
    echo -n "| `/bin/date '+%Y%m%d %H:%M:%S'` "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[35m'; fi
    echo -n "[block] "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[39m\E[49m'; fi
    echo "$1"
  fi
}

msge()
{
  if [ "$INFO_MODE" = "ERROR" ] || [ "$INFO_MODE" = "INFO" ] || [ "$INFO_MODE" = "DEBUG" ] ; then
    echo -n "| `/bin/date '+%Y%m%d %H:%M:%S'` "
    echo -e -n '\E[31m\07'
    echo -n "[error]  "
    echo -e -n '\E[39m\E[49m'
    echo "$1"
  fi
}

msgd()
{
  if [ "$INFO_MODE" = "DEBUG" ] ; then
    echo -n "| `/bin/date '+%Y%m%d %H:%M:%S'` "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[32m'; fi
    echo -n "[debug]    "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[39m\E[49m'; fi
    echo "$1"
  fi
}

msgi()
{
  if [ "$INFO_MODE" = "INFO" ] || [ "$INFO_MODE" = "DEBUG" ] ; then
    echo -n "| `/bin/date '+%Y%m%d %H:%M:%S'` "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[32m'; fi
    echo -n "[info]     "
    if [ "$V_INTERACTIVE" -eq 1 ]; then echo -e -n '\E[39m\E[49m'; fi
    echo "$1"
  fi
}

check_file()
{
  if [ -z "$1" ]; then
    error_log "[ check_file ] Provided parameter is empty. Exiting. " ${RECIPIENTS}
    exit 1
  fi

  if [ ! -f "$1" ]; then
    error_log "[ error ] $1 not found. Exiting. " ${RECIPIENTS}
    exit 1
  else
    msgd "$1 found."
  fi
}

# Runs the command provided as parameter.
# Does exit if the command fails.
# Sends error message if the command fails.
run_command_e()
{
  if [ "$INFO_MODE" = "INFO" ] || [ "$INFO_MODE" = "DEBUG" ] ; then
    msg "\"$1\""
  fi

  # Determining if we are running in a debug mode. If so wait for any key before eval
  if [ -n "$DEBUG_MODE" ]; then
    if [ "$DEBUG_MODE" -eq "1" ] ; then
      echo "[debug wait] Press any key if ready to run the printed command"
      read
    fi
  fi

  eval $1
  if [ $? -ne 0 ]; then
    error_log "[critical] An error occured during: \"$1\". Exiting NOW." ${RECIPIENTS}
    exit 1
  fi
  return 0
} #run_command_e

f_generate_awr()
{
  msgb "${FUNCNAME[0]} Beginning."
  V_SNAP_START=$1
  V_SNAP_END=$2

  msgd "V_SNAP_START: $V_SNAP_START"
  msgd "V_SNAP_END: $V_SNAP_END"
  check_parameter $V_SNAP_START
  check_parameter $V_SNAP_END

  msgd "Generating text AWR"
  sqlplus -S /nolog <<EOF > /dev/null
connect $V_USER/$V_PASS
set head off pagesize 0 echo off verify off feedback off heading off
spool $D_OUTPUT_DIR/AWR_txt_day/awr_${ORACLE_SID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.txt
SELECT output FROM TABLE(dbms_workload_repository.AWR_REPORT_TEXT($V_DBID,1,$V_SNAP_START,$V_SNAP_END));
spool off

spool $D_OUTPUT_DIR/AWR_html_day/awr_${ORACLE_SID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.html
SELECT output FROM TABLE(dbms_workload_repository.AWR_REPORT_HTML($V_DBID,1,$V_SNAP_START,$V_SNAP_END));
spool off

exit;
EOF

msgd "OK, we have AWR reports generated. Now it is time for SQL reports."
check_file "$D_OUTPUT_DIR/AWR_txt_day/awr_${ORACLE_SID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.txt"
F_SQLID=$D_OUTPUT_DIR/sqlid.tmp
cat $D_OUTPUT_DIR/AWR_txt_day/awr_${ORACLE_SID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.txt | grep --before-context=1 "Module:" | grep -v "Module:" | grep -v '\-\-' | awk '{print $NF}' | sort -u > $D_OUTPUT_DIR/sqlid.tmp

msgd "We have all the sqlid from AWE in $D_OUTPUT_DIR/sqlid.tmp. Now loop through them and generate reports."
while read V_SQLID
do
  msgd "SQL report for: $V_SQLID"

  msgd "Generating SQLID report"
  sqlplus -S /nolog <<EOF > /dev/null
connect $V_USER/$V_PASS
set head off pagesize 0 echo off verify off feedback off heading off
spool $D_OUTPUT_DIR/AWR_txt_day/hash_history/awr_${ORACLE_SID}_${V_SQLID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.txt
SELECT output FROM TABLE(dbms_workload_repository.AWR_SQL_REPORT_TEXT($V_DBID,1,$V_SNAP_START,$V_SNAP_END,'$V_SQLID'));
spool off

spool $D_OUTPUT_DIR/AWR_html_day/hash_history/awr_${ORACLE_SID}_${V_SQLID}_${CHECK_FOR_DATE}_${TIME_START}_${CHECK_FOR_DATE}_${TIME_END}.html
SELECT output FROM TABLE(dbms_workload_repository.AWR_SQL_REPORT_HTML($V_DBID,1,$V_SNAP_START,$V_SNAP_END,'$V_SQLID'));
spool off

exit;
EOF


done < $D_OUTPUT_DIR/sqlid.tmp


#WIP

  msgb "${FUNCNAME[0]} Finished."
} #f_generate_awr


INFO_MODE=DEBUG

# Sanity checks
check_parameter $1
check_parameter $2
check_parameter $3

F_SNAP_FILE=$1
V_USER=$2
DATE_START=$3
#TIME_START=$3
#TIME_END=$4
#NR_DAYS_BACK=$5

check_file $F_SNAP_FILE

msgd "Determine output directory"
msgd "ORACLE_SID: $ORACLE_SID"
D_OUTPUT_DIR=/tmp/awr_reports/${ORACLE_SID}_${DATE_START}
msgd "D_OUTPUT_DIR: $D_OUTPUT_DIR"
mkdir -p $D_OUTPUT_DIR/AWR_txt_day/hash_history
mkdir -p $D_OUTPUT_DIR/AWR_html_day/hash_history



echo "Provide password for user $V_USER"
read -s V_PASS

F_SQLPLUS=`which sqlplus`
msgd "F_SQLPLUS: $F_SQLPLUS"
check_file $F_SQLPLUS

testavail=`sqlplus -S /nolog <<EOF
set head off pagesize 0 echo off verify off feedback off heading off
connect $V_USER/$V_PASS
select trim(1) result from dual;
exit;
EOF`

msgd "testavail: $testavail"
if [ "$testavail" != "1" ]; then
  msge "Not connected to $CN exiting !! Turn on DEBUG on check the logs."
  exit 0
else
  msgi "DB available, continuing"
fi

msgd "Getting DBID"
V_DBID=`sqlplus -S /nolog <<EOF
set head off pagesize 0 echo off verify off feedback off heading off
connect $V_USER/$V_PASS
select dbid from v\\$database;
exit;
EOF`

msgd "V_DBID: $V_DBID"
check_parameter $V_DBID

TIME_START="00:00"
TIME_END="01:00"

myvar=1
while [ $myvar -ne 24 ]
do

  CHECK_FOR_DATE=$DATE_START
  msgi "#################################################################"
  msgi "Computing fo date: ${CHECK_FOR_DATE} $TIME_START $TIME_END"
  msgi "#################################################################"

  # If this is Sunday or Saturday skip that day
  echo "Checking file with snaps for date and time"
  msgd "CHECK_FOR_DATE: $CHECK_FOR_DATE"
  #cat $F_SNAP_FILE
  # awrrpt.sql prints date in format 06 Apr 2018
  CHECK_FOR_DATE_AWR_STYLE=`date -d"$CHECK_FOR_DATE" +"%d %b %Y"`
  msgd "CHECK_FOR_DATE_AWR_STYLE: $CHECK_FOR_DATE_AWR_STYLE"

  unset V_SNAP_START
  unset V_SNAP_END
  cat $F_SNAP_FILE | grep "${CHECK_FOR_DATE_AWR_STYLE}"
  V_SNAP_START=`cat $F_SNAP_FILE | grep "${CHECK_FOR_DATE_AWR_STYLE}" | grep "${TIME_START}" | awk '{print $1}'`
  msgd "V_SNAP_START: $V_SNAP_START"

  V_SNAP_END=`cat $F_SNAP_FILE | grep "${CHECK_FOR_DATE_AWR_STYLE}" | grep "${TIME_END}" | awk '{print $1}'`
  msgd "V_SNAP_END: $V_SNAP_END"

  if [ -z ${V_SNAP_START} ] || [ -z ${V_SNAP_END} ] ; then
    msgd "I could not fine snapshots for both times, skipping AWR creations"
  else
    msgd "I have both snapshots then I can generate the AWR command"
    f_generate_awr ${V_SNAP_START} ${V_SNAP_END}
  fi

  msgd "That was for:"
  msgd "TIME_START: $TIME_START"
  msgd "TIME_END: $TIME_END"
  msgd "myvar: $myvar"


  msgd "Next loop will be for:"
  TIME_START=`date +%H:%M -d "$CHECK_FOR_DATE $myvar hour"`
  msgd "TIME_START: $TIME_START"

  myvar=$(( $myvar + 1 ))

  TIME_END=`date +%H:%M -d "$CHECK_FOR_DATE $myvar hour"`
  msgd "TIME_END: $TIME_END"
  msgd "myvar: $myvar"

#exit 0

done

echo "Done."

