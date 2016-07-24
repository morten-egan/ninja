set echo off
set heading off
set feedback off

select npg_name || ' (' || pg_version || ' - ' || installed_schema || ')'
from ninja_installed_packages
order by npg_name;

exit;
