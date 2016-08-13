set echo off
set heading off
set feedback off
set verify off

select npg_name || npg_output
from table(ninja_npg.list_p('&1'));

exit;
