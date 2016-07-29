-- 1. Reorg of the RCV_HEADERS_INTERFACE table
ALTER session SET nls_date_format = 'YYYY-MM-DD HH24';
alter session set NLS_DATE_FORMAT = "YYYY/MM/DD HH24:MI:SS";
SELECT /*+ FULL(a)*/
  COUNT(*) FROM RCV_HEADERS_INTERFACE a;
/* this should take <1sek, and consume <2200 blocks in consistent gets, return <50000 rows  */
 
-- 2. MV are refreshed in fast mode
SELECT mview_name,
  update_log,
  refresh_mode,
  refresh_method,
  build_mode,
  fast_refreshable,
  last_refresh_type,
  last_refresh_date
FROM all_mviews
WHERE mview_name LIKE 'XX_%_MV'
AND last_refresh_type = 'COMPLETE'
ORDER BY last_refresh_date;
/*
we should only see: XX_AP_TAX_CODES_MV, XX_HR_ORGANIZATIONS_UNITS_MV

GEHC_GFB_REGION_MV		DEMAND	COMPLETE	DEFERRED	NO	COMPLETE
XX_HR_ORGANIZATIONS_UNITS_MV		DEMAND	FORCE	IMMEDIATE	NO	COMPLETE

since 2015.11.01 we see:

XXXX_GFB_REGION_MV		DEMAND	FORCE	IMMEDIATE	NO	COMPLETE	2015/11/04 15:25:18
XX_HR_ORGANIZATIONS_UNITS_MV		DEMAND	FORCE	PREBUILT	NO	COMPLETE	2015/11/16 08:23:12
XX_AP_TAX_CODES_MV		DEMAND	FORCE	IMMEDIATE	NO	COMPLETE	2015/11/16 10:09:05
*/



SELECT mview_name,
  update_log,
  refresh_mode,
  refresh_method,
  build_mode,
  fast_refreshable,
  last_refresh_type,
  last_refresh_date
FROM all_mviews
WHERE mview_name LIKE 'XX_%_MV'
--WHERE mview_name LIKE '%'
AND last_refresh_type = 'FAST'
ORDER BY last_refresh_date;

/*
This should be:
XX_AP_PAYMENTS_CHECKS_MV		DEMAND	FORCE	PREBUILT	DIRLOAD_DML	FAST	2015/11/15 22:16:00
XX_FND_FLEXVALUES_MV		DEMAND	FORCE	PREBUILT	DIRLOAD_DML	FAST	2015/11/16 05:58:06
XX_GL_CODECOMBINATIONS_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 05:58:11
XX_AP_HOLDS_ALL_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_AP_INVOICES_ALL_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_AP_DISTRIBUTION_SETS_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_AP_VENDOR_SEARCH_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_FND_LOOKUP_VALUES_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_AP_TERMS_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 10:02:03
 XX_PO_RELEASES_ALL_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:16
 XX_PO_VENDOR_SITES_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:26
 XX_PO_DISTRIBUTIONS_ALL_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:31
 XX_PO_LOOKUP_LOAD_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:31
 XX_PO_LINE_LOCATIONS_ALL_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:31
 XX_AP_BANK_MV		DEMAND	FORCE	IMMEDIATE	DIRLOAD_DML	FAST	2015/11/16 11:49:56

*/

-- auto check

select distinct last_refresh_type 
FROM all_mviews
WHERE mview_name in ('XX_AP_PAYMENTS_CHECKS_MV','XX_FND_FLEXVALUES_MV','XX_GL_CODECOMBINATIONS_MV',
'XX_AP_HOLDS_ALL_MV','XX_AP_INVOICES_ALL_MV','XX_AP_DISTRIBUTION_SETS_MV','XX_AP_VENDOR_SEARCH_MV',
'XX_FND_LOOKUP_VALUES_MV','XX_AP_TERMS_MV','XX_PO_RELEASES_ALL_MV','XX_PO_VENDOR_SITES_MV',
'XX_PO_DISTRIBUTIONS_ALL_MV','XX_PO_LOOKUP_LOAD_MV','XX_PO_LINE_LOCATIONS_ALL_MV','XX_AP_BANK_MV')
;

select mview_name,
  update_log,
  refresh_mode,
  refresh_method,
  build_mode,
  fast_refreshable,
  last_refresh_type,
  last_refresh_date
FROM all_mviews
WHERE mview_name in ('GEHC_GFB_REGION_MV','XX_HR_ORGANIZATIONS_UNITS_MV','XX_AP_TAX_CODES_MV');


select distinct last_refresh_type 
FROM all_mviews
WHERE mview_name in ('GEHC_GFB_REGION_MV','XX_HR_ORGANIZATIONS_UNITS_MV','XX_AP_TAX_CODES_MV');

select count(1)
FROM all_mviews
WHERE mview_name in ('GEHC_GFB_REGION_MV','XX_HR_ORGANIZATIONS_UNITS_MV','XX_AP_TAX_CODES_MV')
and last_refresh_type in ('COMPLETE','NA')
;






-- 3. Disable trace enabled programs
SELECT fcp.CONCURRENT_PROGRAM_NAME,
  fcpl.USER_CONCURRENT_PROGRAM_NAME
FROM fnd_concurrent_programs fcp,
  fnd_concurrent_programs_tl fcpl
WHERE fcp.concurrent_program_id = fcpl.concurrent_program_id
AND enable_trace                ='Y';

select count(1) from fnd_concurrent_programs WHERE enable_trace ='Y';

/*
This is what is generally seen: (should be none, but this is what we have and noone considers this an issue)

MSRFWOR	Refresh Collection Snapshots
GEHC_AP_GLOBAL_HOLD	GEHC Internal AP On Hold Detail Report
GEMCLONE	GEMS eOM and OM Extract to Downstream Systems
GEMOMDSR	Demand Sourcing Requisitions Processor
MSCCLRFS	APS Collections Refresh Snapshot Thread
XX_AP_RBC_EFT	GE AP RBC EFT Payment Program
GEMOMXOR	GEMS Demand Orders Listing

*/

-- Disable enabled FND: Diagnostics
SELECT fpo.profile_option_name SHORT_NAME,
  fpot.user_profile_option_name NAME,
  DECODE (fpov.level_id, 10001, 'Site', 10002, 'Application', 10003, 'Responsibility', 10004, 'User', 10005, 'Server', 'UnDef') LEVEL_SET,
  DECODE (TO_CHAR (fpov.level_id), '10001', '', '10002', fap.application_short_name, '10003', frsp.responsibility_key, '10005', fnod.node_name, '10006', hou.name, '10004', fu.user_name, 'UnDef') "CONTEXT",
  fpov.profile_option_value VALUE
FROM fnd_profile_options fpo,
  fnd_profile_option_values fpov,
  fnd_profile_options_tl fpot,
  fnd_user fu,
  fnd_application fap,
  fnd_responsibility frsp,
  fnd_nodes fnod,
  hr_operating_units hou
WHERE fpo.profile_option_id        = fpov.profile_option_id(+)
AND fpo.profile_option_name        = fpot.profile_option_name
AND fu.user_id(+)                  = fpov.level_value
AND frsp.application_id(+)         = fpov.level_value_application_id
AND frsp.responsibility_id(+)      = fpov.level_value
AND fap.application_id(+)          = fpov.level_value
AND fnod.node_id(+)                = fpov.level_value
AND hou.organization_id(+)         = fpov.level_value
AND fpot.user_profile_option_name IN ('FND: Diagnostics','FND: Debug Log Enabled')
AND fpov.profile_option_value      = 'Y'
ORDER BY short_name, context;

-- for automated check
SELECT distinct fpov.level_id  
FROM fnd_profile_options fpo,
  fnd_profile_option_values fpov,
  fnd_profile_options_tl fpot,
  fnd_user fu,
  fnd_application fap,
  fnd_responsibility frsp,
  fnd_nodes fnod,
  hr_operating_units hou
WHERE fpo.profile_option_id        = fpov.profile_option_id(+)
AND fpo.profile_option_name        = fpot.profile_option_name
AND fu.user_id(+)                  = fpov.level_value
AND frsp.application_id(+)         = fpov.level_value_application_id
AND frsp.responsibility_id(+)      = fpov.level_value
AND fap.application_id(+)          = fpov.level_value
AND fnod.node_id(+)                = fpov.level_value
AND hou.organization_id(+)         = fpov.level_value
AND fpot.user_profile_option_name IN ('FND: Diagnostics','FND: Debug Log Enabled')
AND fpov.profile_option_value      = 'Y'
;


-- other checks from Bob
SET linesize 100
SET pagesize 999
column today new_value _date noprint
SELECT TO_CHAR(SYSDATE,'DD-MON-RR') today FROM dual;
ttitle CENTER 'Debug and Trace Profile Options Set to YES' -
RIGHT _date ' Page:' FORMAT 999 sql.pno SKIP 2             -
Column app_short format a6 heading "APP"
column optname format a35 heading "PROFILE"
column d_level format a36 heading "WHO HAS IT SET"
column optval format a6 heading "SET TO"
column updated format a10 heading "UPDATED ON"
SELECT DISTINCT a.application_short_name app_short,
  user_profile_option_name optname,
  DECODE(level_id, 10001,'SITE', 10002,'APP : '
  ||a2.application_short_name, 10003,'RESP: '
  ||r.responsibility_key, 10004,'USER: '
  ||u.user_name, 'Unknown') d_level,
  profile_option_value optval,
  v.last_update_date updated
FROM fnd_profile_options_vl o,
  fnd_profile_option_values v,
  fnd_application a,
  fnd_application a2,
  fnd_responsibility r,
  fnd_user u
WHERE ( upper(o.user_profile_option_name) LIKE '%DEBUG%'
OR upper(o.user_profile_option_name) LIKE '%TRACE%'
  --or upper(o.user_profile_option_name) like '%LOGG%'
  )
AND a.application_id    = v.application_id
AND o.application_id    = v.application_id
AND o.profile_option_id = v.profile_option_id
  -- Find the associate level for profile
AND r.application_id (+)    = v.level_value_application_id
AND r.responsibility_id (+) = v.level_value
AND a2.application_id (+)   = v.level_value
AND u.user_id (+)           = v.level_value
AND profile_option_value    = 'Y'
ORDER BY 2,1,3,4;


/*
There should be no programs that have trace enabled during the LT
-- ?any other debug programs?
*/


-- 4. Disable pending requests
SELECT phase_code,
  status_code,
  COUNT(*)
FROM fnd_concurrent_requests
GROUP BY phase_code,
  status_code;
UPDATE bla_fnd_concurrent_requests
SET phase_code  ='C',
  status_code   ='X'
WHERE phase_code='P';
/*
There should be no pending requests, phase_code='P'
*/

-- automated check
SELECT COUNT(1) FROM fnd_concurrent_requests where phase_code  ='P';



-- 5. MTL_MATERIAL_TRANSACTIONS_TEMP initrans change and reord
ALTER session SET nls_date_format = 'YYYY-MM-DD HH24';
SELECT owner,
  table_name, ini_trans, pct_free, 
  last_analyzed
FROM dba_tables
WHERE table_name='MTL_MATERIAL_TRANSACTIONS_TEMP'
AND owner       ='INV';

SELECT owner,
  index_name, ini_trans, pct_free,
  last_analyzed
FROM dba_indexes
WHERE index_name in ('MTL_MATERIAL_TRANS_TEMP_N1','MTL_MATERIAL_TRANS_TEMP_U1')
AND owner       ='INV';

/*
Should be rebuilded - and have the stats refreshed on the day the restore is complete (likely when LT is run)
with initrans 50
*/

--6. FND_PROFILE_OPTIONS and FND_PROFILE_OPTION_VALUES - Re-org with pctfree 50 nad 100% GS
ALTER session SET nls_date_format = 'YYYY-MM-DD HH24';
SELECT owner,
  table_name, pct_free,
  last_analyzed, num_rows, sample_size, blocks
FROM dba_tables
WHERE table_name in ('FND_PROFILE_OPTIONS','FND_PROFILE_OPTION_VALUES')
AND owner       ='APPLSYS';

/*
?? Does not looks like re-org and 100% GS

APPLSYS	FND_PROFILE_OPTIONS	      20	26-SEP-15	10216	  5008	1014
APPLSYS	FND_PROFILE_OPTION_VALUES	20	26-SEP-15	189540	18954	2816
*/

--06. Init parameters
show parameter db_file_multiblock_read_count;

select * from v$parameter where name = 'db_file_multiblock_read_count';
select name, value, isdefault, ismodified from v$parameter where name = 'db_file_multiblock_read_count';
/*
This should be default and unset, 
db_file_multiblock_read_count	128	TRUE	FALSE

http://kerryosborne.oracle-guy.com/2008/11/reset-oracle-initora-spfile-parameters/
*/

select isdefault, ismodified from v$parameter where name = 'db_file_multiblock_read_count';


--7. result_cache
select * from v$parameter where name like '%result_cache%';

/*
This should be like the following:
result_cache_mode MANUAL
result_cache_max_size 1G
result_cache_max_result 5
result_cache_remote_expiration 0
_result_cache_global FALSE
client_result_cache_size 0
client_result_cache_lag 3000
*/

--Make sure we have optimizer_features_enable set to 11.2.0.4, without this RC does not work
select * from v$parameter where name = 'optimizer_features_enable';

--8. FND_CONCURRENT_REQUESTS reorg

select table_name, num_rows, blocks, last_analyzed from all_tables where table_name = 'FND_CONCURRENT_REQUESTS';
SELECT /*+ FULL(a)*/ COUNT(*) FROM FND_CONCURRENT_REQUESTS a;
/*
This should NOT be
                        rows  blocks 
FND_CONCURRENT_REQUESTS	27730	330240	15/09/05

This should BE more like:
                        rows  blocks 
FND_CONCURRENT_REQUESTS	31035	25600	15/09/22
*/

-- 08 Check recent table GS

@o

select table_name, last_analyzed, sample_size, num_rows, blocks from all_tables where table_name='EGO_MTL_SY_ITEMS_EXT_B' and owner ='EGO';
select table_name, last_analyzed, sample_size, num_rows, blocks from all_tables where table_name='MTL_PARAMETERS' and owner ='INV';
select table_name, last_analyzed, sample_size, num_rows, blocks from all_tables where table_name='MTL_ITEM_LOCATIONS' and owner ='INV';
select table_name, last_analyzed, sample_size, num_rows, blocks from all_tables where table_name='QP_QUALIFIERS' and owner ='QP';

-- automated, < 7
select round(sysdate - last_analyzed) from all_tables where table_name='EGO_MTL_SY_ITEMS_EXT_B' and owner ='EGO';


/*
�	Need to ensure ego.ego_mtl_sy_items_ext_b, inv.mtl_parameters, inv.mtl_item_locations and qp.qp_qualifiers needs to be in plan for GS; otherwise, see issues with Siebel interface for order booking into GLPROD.  
Found inv.mtl_parameters needed GS during the initial testing of order booking from Siebel.
*/



--09. Profile options
--Checking if some profile options have expected values

select p.profile_option_name PROFILE_SHORT_NAME, n.user_profile_option_name PROFILE_NAME, 
       decode(v.level_id, 10001, 'Site', 10002, 'Application', 10003, 'Responsibility', 10004, 'User', 10005, 'Server', 'Site') PROFILE_LEVEL, 
       decode(to_char(v.level_id), '10001', 'Site', '10002', app.application_short_name, '10003', rsp.responsibility_key, '10005', svr.node_name, '10006', org.name, '10004', usr.user_name, 'Site') LEVEL_VALUE, 
       v.profile_option_value VALUE, SUBSTR(v.last_update_date,1,25) LAST_UPDATE_DATE
from   fnd_profile_options p, fnd_profile_option_values v, fnd_profile_options_tl n, fnd_user usr, 
       fnd_application app, fnd_responsibility rsp, fnd_nodes svr, hr_operating_units org 
where  p.profile_option_id = v.profile_option_id (+) 
and    p.profile_option_name = n.profile_option_name 
and    usr.user_id (+) = v.level_value 
and    rsp.application_id (+) = v.level_value_application_id 
and    rsp.responsibility_id (+) = v.level_value 
and    app.application_id (+) = v.level_value 
and    svr.node_id (+) = v.level_value 
and    org.organization_id (+) = v.level_value 
and    upper(n.user_profile_option_name) like upper('HR%Cross%Business%Group%') 
and    n.language = 'US'
order by PROFILE_SHORT_NAME, PROFILE_LEVEL;

/*
Expecting:
HR_CROSS_BUSINESS_GROUP	HR:Cross Business Group	Site	Site	N	2015-10-08 16
*/

-- auto test, expecting N
select v.profile_option_value VALUE
from   fnd_profile_options p, fnd_profile_option_values v, fnd_profile_options_tl n, fnd_user usr, 
       fnd_application app, fnd_responsibility rsp, fnd_nodes svr, hr_operating_units org 
where  p.profile_option_id = v.profile_option_id (+) 
and    p.profile_option_name = n.profile_option_name 
and    usr.user_id (+) = v.level_value 
and    rsp.application_id (+) = v.level_value_application_id 
and    rsp.responsibility_id (+) = v.level_value 
and    app.application_id (+) = v.level_value 
and    svr.node_id (+) = v.level_value 
and    org.organization_id (+) = v.level_value 
and    n.user_profile_option_name = 'HR:Cross Business Group'
and    n.language = 'US'
;



select p.profile_option_name PROFILE_SHORT_NAME, n.user_profile_option_name PROFILE_NAME, 
       decode(v.level_id, 10001, 'Site', 10002, 'Application', 10003, 'Responsibility', 10004, 'User', 10005, 'Server', 'Site') PROFILE_LEVEL, 
       decode(to_char(v.level_id), '10001', 'Site', '10002', app.application_short_name, '10003', rsp.responsibility_key, '10005', svr.node_name, '10006', org.name, '10004', usr.user_name, 'Site') LEVEL_VALUE, 
       v.profile_option_value VALUE, SUBSTR(v.last_update_date,1,25) LAST_UPDATE_DATE
from   fnd_profile_options p, fnd_profile_option_values v, fnd_profile_options_tl n, fnd_user usr, 
       fnd_application app, fnd_responsibility rsp, fnd_nodes svr, hr_operating_units org 
where  p.profile_option_id = v.profile_option_id (+) 
and    p.profile_option_name = n.profile_option_name 
and    usr.user_id (+) = v.level_value 
and    rsp.application_id (+) = v.level_value_application_id 
and    rsp.responsibility_id (+) = v.level_value 
and    app.application_id (+) = v.level_value 
and    svr.node_id (+) = v.level_value 
and    org.organization_id (+) = v.level_value 
and    upper(n.user_profile_option_name) like upper('INV%Use%TM%') 
and    n.language = 'US'
order by PROFILE_SHORT_NAME, PROFILE_LEVEL;

/*
Expecting:
INV_USE_ENHANCED_TM	INV: Use Enhanced TM	Site	Site	1	2015-10-22 14
*/

-- auto test, expecting 1
select v.profile_option_value VALUE
from   fnd_profile_options p, fnd_profile_option_values v, fnd_profile_options_tl n, fnd_user usr, 
       fnd_application app, fnd_responsibility rsp, fnd_nodes svr, hr_operating_units org 
where  p.profile_option_id = v.profile_option_id (+) 
and    p.profile_option_name = n.profile_option_name 
and    usr.user_id (+) = v.level_value 
and    rsp.application_id (+) = v.level_value_application_id 
and    rsp.responsibility_id (+) = v.level_value 
and    app.application_id (+) = v.level_value 
and    svr.node_id (+) = v.level_value 
and    org.organization_id (+) = v.level_value 
and    n.user_profile_option_name = 'INV: Use Enhanced TM'
and    n.language = 'US'
;




--10. Prevent SGA resize despite sga_target=0
SELECT value from v$parameter where name='_memory_imm_mode_without_autosga';

show parameter memory
/*
This hidden parameter should be st
NAME                             TYPE        VALUE 
-------------------------------- ----------- ----- 
_memory_imm_mode_without_autosga boolean     FALSE 
*/

SELECT value from v$parameter where name='shared_pool_size';
SELECT value from v$parameter where name='shared_pool_reserved_size';

show parameter shared
/*
We go with 20G shared pool
NAME                             TYPE        VALUE 
-------------------------------- ----------- ----- 
shared_pool_reserved_size big integer 1200M                              
shared_pool_size          big integer 20G                                
*/

SELECT COMPONENT ,OPER_TYPE,oper_mode,FINAL_SIZE Final,to_char(start_time,'dd-mon hh24:mi:ss') Started FROM V$SGA_RESIZE_OPS;
select * from V$SGA_RESIZE_OPS;
SELECT count(*) FROM V$SGA_RESIZE_OPS where oper_type in ('GROW','SHRINK') and component not in ('streams pool'); 
/*
Make sure there are no dynamic resize operations are going on.

We should NOT see any SHRINK or GROW operations going on
*/

show parameter streams
show parameter db_cache_advice

--11. Check redo size >= 5G
select * from v$log;
select distinct bytes from v$log;

--12. Check DOP on couple of tables
select table_name, num_rows, blocks, last_analyzed, degree from all_tables where table_name in ('OE_ORDER_LINES_ALL', 'MTL_SYSTEM_ITEMS_B', 'MTL_ITEM_CATEGORIES');
select distinct degree from all_tables where table_name in ('OE_ORDER_LINES_ALL', 'MTL_SYSTEM_ITEMS_B', 'MTL_ITEM_CATEGORIES');

--13. Invalids
select object_name, owner, object_type from dba_objects where status != 'VALID' and object_type not in ('SYNONYM') order by owner;
select object_name, owner, object_type from dba_objects where status != 'VALID' and object_type not in ('SYNONYM') and owner = 'APPS' order by owner;
select owner,count(1) from dba_objects where status != 'VALID' and object_type not in ('SYNONYM') group by owner order by owner;

select count(1) from dba_objects where status != 'VALID' and object_type not in ('SYNONYM') order by owner;
/*
what is normal?
        ALL   APPS
ITEST - 280   116
GLRAC - 1028  100
*/

--automation, for the lack of other ideas I make sure we are below 100 invalids for APPS
select count(1) from dba_objects where status != 'VALID' and object_type not in ('SYNONYM') and owner = 'APPS';

--14. custom_indexes. 
--GEMS_RA_CUSTOMER_TRX_N97

select owner, index_name, ini_trans, pct_free, last_analyzed FROM dba_indexes WHERE index_name in ('GEMS_RA_CUSTOMER_TRX_N97');
/*
Expected output
AR	GEMS_RA_CUSTOMER_TRX_N97	2	10	06-NOV-15
*/

select owner, index_name, ini_trans, pct_free, last_analyzed FROM dba_indexes WHERE index_name in ('JA_IN_RA_CUSTOMER_TRX_ALL_N1');



-- Automated test
select 1 FROM dba_indexes WHERE index_name in ('GEMS_RA_CUSTOMER_TRX_N97') and owner='AR';

--15. SPM count
select count(1) from dba_sql_plan_baselines
where to_char(created,'YYYY') = '2015'
and origin like 'MANUAL%';



--XXX Abandoned. CM cache size 2 x the number of processes - this proved not to help

select User_Concurrent_Queue_Name,  Target_Node,       
       Max_Processes, Cache_Size, sleep_seconds, description
from fnd_concurrent_queues_vl
where cache_size < 2 * max_processes;

/*
We should only see
PA Streamline Manager	ERP-CCM-STG-02	1	1
GEMS System Admin Jobs	ERP-CCM-STG-05	25	25
GEMS Data Load	ERP-CCM-STG-03	10	10

Just to check how is it set:
*/

select User_Concurrent_Queue_Name,  Target_Node,       
       Max_Processes, Cache_Size, sleep_seconds, description
from fnd_concurrent_queues_vl
where max_processes > 0;




-- XXX. Monitoring
/* Nice links
- http://blog.tanelpoder.com/2008/08/03/library-cache-latches-gone-in-oracle-11g/
- http://tech.e2sn.com/oracle/troubleshooting/latch-contention-troubleshooting

*/
-- sessions
select count(*) from gv$session;
select * from gv$session;
select status,schemaname,machine,program,type,event,state,sql_id from gv$session where schemaname in ('APPS','APPLSYSPUB');
select schemaname, count(*) ala from gv$session group by schemaname;
select event, count(*) from v$session group by event order by count(*) desc;

-- waits
select event, count(*) from v$session_wait group by event order by count(*) desc;

-- RC
select * from V$RESULT_CACHE_OBJECTS;
select * from V$RESULT_CACHE_OBJECTS where ;
select count(*) from V$RESULT_CACHE_OBJECTS;
execute DBMS_RESULT_CACHE.MEMORY_REPORT(TRUE);
SELECT * FROM gv$sgastat WHERE POOL='shared pool' AND NAME LIKE 'Result%' AND INST_ID =1;

SELECT INST_ID INT, ID, TYPE, CREATION_TIMESTAMP, BLOCK_COUNT, COLUMN_COUNT, PIN_COUNT, ROW_COUNT FROM GV$RESULT_CACHE_OBJECTS;


-- latches specyfic
select * from v$session where event ='latch free';
select sql_id, count(*) from v$session where event ='library cache load lock' group by sql_id order by count(*) desc;
select * from v$session_wait where event='latch free';
select * from V$LATCHHOLDER;

-- latches and mutex general
select * from v$latch where name ='cache buffers chains';
select name, gets, wait_time from v$latch order by wait_time desc;
select * from v$mutex_sleep order by sleeps desc;

select * from v$mutex_sleep_history order by sleep_timestamp desc;

set linesize 200
set verify off
@tpt/latchprof name % % 200
@tpt/latchprof name,sid,sqlid % % 10000
@tpt/latchprof sid,name % "cache buffers chains" 100
@tpt/latchprof sid,name % "KWQS pqueue ctx latch" 200
@tpt/latchprof name,sqlid % "cache buffers chains" 100

@tpt/snapper stats 5 1 7256
@tpt/sqlid 806cmqtfckysb

--- completed CM in the last minute
select
fcpt.USER_CONCURRENT_PROGRAM_NAME,
DECODE(fcr.phase_code,
'C', 'Completed',
'I', 'Inactive',
'P', 'Pending',
'R', 'Running',
fcr.phase_code
) PHASE ,
DECODE(fcr.status_code,
'A', 'Waiting',
'B', 'Resuming',
'C', 'Normal',
'D', 'Cancelled',
'E', 'Errored',
'F', 'Scheduled',
'G', 'Warning',
'H', 'On Hold',
'I', 'Normal',
'M', 'No Manager',
'Q', 'Standby',
'R', 'Normal',
'S', 'Suspended',
'T', 'Terminating',
'U', 'Disabled',
'W', 'Paused',
'X', 'Terminated',
'Z', 'Waiting',
fcr.status_code
) STATUS,
count(*)
from apps.fnd_concurrent_programs_tl fcpt,apps.FND_CONCURRENT_REQUESTs fcr
where fcpt.CONCURRENT_PROGRAM_ID=fcr.CONCURRENT_PROGRAM_ID
and fcpt.language = USERENV('Lang')
and fcr.ACTUAL_START_DATE > sysdate - 1/24/60
group by fcpt.USER_CONCURRENT_PROGRAM_NAME,fcr.phase_code,fcr.status_code
/

--- running CM, based on modified view
select * from XX_FND_CONCURRENT_WORKER_REQ;

SELECT * FROM 
(
SELECT   /*+ FIRST_ROWS */
fcqt.user_concurrent_queue_name, fcq.concurrent_queue_name, 
        fcq.target_node, fcq.running_processes actual, fcq.max_processes target, 
         DECODE (fcq.enabled_flag,'Y', 'Y','N', 'N',fcq.enabled_flag) ENABLED,
         SUM (DECODE (fcwr.phase_code, 'R', 1, 0)) running,
           SUM (DECODE (fcwr.phase_code, 'P', 1, 0))
         - SUM (DECODE (fcwr.hold_flag, 'Y', 1, 0))
         - SUM (DECODE (SIGN (fcwr.requested_start_date - SYSDATE), 1, 1, 0)) pending,
         SUM (DECODE (fcwr.hold_flag, 'Y', 1, 0)) hold,
         SUM (DECODE (SIGN (fcwr.requested_start_date - SYSDATE), 1, 1, 0)) sched,
         NVL (paused_jobs.paused_count, 0) paused, fcq.sleep_seconds, 
 fcq.application_id, fcq.concurrent_queue_id
    FROM apps.ge_fnd_concurrent_worker_req fcwr,
         applsys.fnd_concurrent_queues fcq,
         applsys.fnd_concurrent_queues_tl fcqt,
         (SELECT   fcp.concurrent_queue_id, COUNT (*) paused_count
              FROM applsys.fnd_concurrent_requests fcr, applsys.fnd_concurrent_processes fcp
             WHERE fcr.phase_code = 'R'
               AND fcr.status_code = 'W'                             -- Paused
               AND fcr.controlling_manager = fcp.concurrent_process_id
          GROUP BY fcp.concurrent_queue_id) paused_jobs
   WHERE fcwr.queue_application_id(+) = fcq.application_id
     AND fcwr.concurrent_queue_id(+) = fcq.concurrent_queue_id
     AND fcq.concurrent_queue_id = paused_jobs.concurrent_queue_id(+)
     AND fcq.application_id = fcqt.application_id
     AND fcq.concurrent_queue_id = fcqt.concurrent_queue_id
     AND fcqt.LANGUAGE = USERENV ('LANG')
     AND fcq.running_processes > 0
GROUP BY fcq.concurrent_queue_name, fcqt.user_concurrent_queue_name, fcq.application_id,
         fcq.concurrent_queue_id, fcq.target_node, fcq.max_processes, fcq.running_processes,
         fcq.sleep_seconds, fcq.cache_size,
         DECODE (fcq.enabled_flag,'Y', 'Y','N', 'N',fcq.enabled_flag),
         paused_jobs.paused_count
ORDER BY DECODE (fcq.enabled_flag,'Y', 'Y','N', 'N',fcq.enabled_flag) DESC,
         DECODE (fcq.concurrent_queue_name,'FNDICM', 'AAA','STANDARD', 'AAB','Your name', 'AAC',fcq.concurrent_queue_name)
) 
/
--WHERE user_concurrent_queue_name LIKE 'SFM%';

---- Does not want to work at GE ?!
ALTER session SET nls_date_format = 'YYYY-MM-DD HH24';
SELECT owner,  table_name, pct_free,  last_analyzed, num_rows, sample_size, blocks FROM dba_tables
WHERE table_name in ('FND_CONCURRENT_QUEUES','FND_CONCURRENT_QUEUES_TL','FND_CONCURRENT_REQUESTS','FND_CONCURRENT_PROCESSES')
AND owner       ='APPLSYS';

---- this view hangs forever
select count(*) from FND_CONCURRENT_WORKER_REQUESTS;

@o



--- WIP
select /*+ RULE */ * from dba_jobs_running;

set verify off
set linesize 200
@tpt/latchprof name,sid,sqlid % % 3000

@tpt/latchprof name,sid,sqlid % "cache buffers chains" 1000

@tpt/sqlid f3rznjycf1n84
@tpt/sqlid 7cm0dwfcyxur8
@tpt/sqlid 806cmqtfckysb
@tpt/sqlid 0bujgc94rg3fj
@users

@tpt/snapper stats 10 1 6119

show parameter result

select * from v$sql;
select * from v$sql order by last_load_time desc;

select * from v$sql where SQL_TEXT like '%result_cache%';
select * from v$sql where SQL_TEXT like '%DS_SVC%';
select * from v$sql where SQL_TEXT like '%parallel%';
select count(*), ala from (
select substr(sql_text, 1, 60) ala
from v$sql
) group by ala order by count(*) desc
;

SELECT scan_count, count(*)
FROM gv$result_cache_objects
group by scan_count
ORDER BY 2,1;


select schemaname, count(*) ala from v$session group by schemaname;

@p

SELECT s.sid, t.sql_text
FROM v$session s, v$sql t
WHERE s.event LIKE '%cursor: pin S wait on X%'
AND t.sql_id = s.sql_id;

select * from all_tables where table_name = 'FND_CONCURRENT_REQUESTS';
select * from dba_tables where table_name = 'FND_CONCURRENT_REQ';

show parameter shared

SELECT COMPONENT ,OPER_TYPE,FINAL_SIZE Final,to_char(start_time,'dd-mm hh24:mi:ss') Started FROM V$SGA_RESIZE_OPS; 

