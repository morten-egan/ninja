accept npg_user char format 'a30' prompt 'Enter the schema name for the NPG installation: '
accept npg_user_pwd char format 'a50' prompt 'Enter the password for the schema: ' hide

set verify off;

@@sql/user.sql &npg_user &npg_user_pwd

@@sql/network_acl.sql &npg_user

alter session set current_schema = &npg_user;

@@plsql/ninja_npg.spec.sql

grant execute on ninja_npg to public;
create public synonym ninja_npg for ninja_npg;

@@sql/tables

set define off

-- PLSQL Specs
@@plsql/zip_util_pkg.spec.sql
@@plsql/ninja_parse.spec.sql
@@plsql/ninja_npg_utils.spec.sql
@@plsql/ninja_download.spec.sql
@@plsql/ninja_validate.spec.sql
@@plsql/ninja_compile.spec.sql
@@plsql/ninja_delete.spec.sql
@@plsql/ninja_register.spec.sql
@@plsql/ninja_npg.spec.sql

-- PLSQL Bodies
@@plsql/zip_util_pkg.body.sql
@@plsql/ninja_parse.body.sql
@@plsql/ninja_npg_utils.body.sql
@@plsql/ninja_download.body.sql
@@plsql/ninja_validate.body.sql
@@plsql/ninja_delete.body.sql
@@plsql/ninja_compile.body.sql
@@plsql/ninja_register.body.sql
@@plsql/ninja_npg.body.sql

@@sql/initial_meta.sql

exit;
