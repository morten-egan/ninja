insert into ninja_repositories values ('http://npg.plsql.ninja', sysdate, sysdate, sys_guid());
insert into ninja_pgm_meta values (ninja_npg.version_major, ninja_npg.version_minor, ninja_npg.version_fix);
commit;
