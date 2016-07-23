set define off

@@sql/user.sql

@@sql/network_acl.sql

connect ninja/ninja

@@sql/tables

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
