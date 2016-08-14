-- Default repository
insert into ninja_repositories values ('http://npg.plsql.ninja', sysdate, sysdate, sys_guid());
-- Create the default settings
insert into ninja_settings values ('raise_on_install', 'false');
insert into ninja_settings values ('execute_object_timeout', '20');
-- Commit initial meta.
commit;
