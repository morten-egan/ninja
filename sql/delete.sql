set termout off
WHENEVER SQLERROR EXIT SQL.SQLCODE;

REM Install package requested.
begin
  ninja_npg.delete_p(
    package_name => '&1'
    , cli_generated_id => '&2'
  );
end;
/

set termout on
set heading off
set echo off
set feedback off
set verify off

select entry from ninja_install_log where ninja_id = '&2' order by entry_time asc;

exit;
