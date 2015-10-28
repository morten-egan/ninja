create or replace package body ninja_validate

as

	function obj_already_exist (
		object_name						in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		assert_exception	exception;
		pragma				exception_init(assert_exception, -44002);
		obj_verified		varchar2(128);
	
	begin
	
		dbms_application_info.set_action('obj_already_exist');

		obj_verified := dbms_assert.sql_object_name(object_name);
		l_ret_val := true;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when assert_exception then
				return l_ret_val;
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end obj_already_exist;

	function db_version_check (
		db_version_met						in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		chk_stmt			varchar2(1000);
	
	begin
	
		dbms_application_info.set_action('db_version_check');

		chk_stmt := 'select dbms_db_version.'|| db_version_met ||' from dual';
		execute immediate chk_stmt into l_ret_val;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end db_version_check;

begin

	dbms_application_info.set_client_info('ninja_validate');
	dbms_session.set_identifier('ninja_validate');

end ninja_validate;
/