create user ninja identified by ninja
default tablespace users
temporary tablespace temp
quota unlimited on users;

grant create session to ninja;
grant create table to ninja;
grant create procedure to ninja;
grant execute on utl_http to ninja;
grant create type to ninja;