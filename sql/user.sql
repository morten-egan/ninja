create user &1 identified by &2
default tablespace users
temporary tablespace temp
quota unlimited on users;

grant create table to &1;
grant create procedure to &1;
grant create type to &1;
grant create public synonym to &1;
grant create any job to &1;
grant execute on dbms_crypto to &1;
grant execute on dbms_alert to &1;
grant execute on utl_http to &1;
