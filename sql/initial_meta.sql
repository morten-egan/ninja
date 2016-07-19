-- Default repository
insert into ninja_repositories values ('http://npg.plsql.ninja', sysdate, sysdate, sys_guid());
-- Insert ninja NPG version.
insert into ninja_pgm_meta values (ninja_npg.version_major, ninja_npg.version_minor, ninja_npg.version_fix);
-- Create the default settings
insert into ninja_settings values ('raise_on_install', 'true');
-- Commit initial meta.
commit;
