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

		chk_stmt := 'begin :b1 := dbms_db_version.'|| db_version_met ||'; end;';
		execute immediate chk_stmt using in out l_ret_val;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end db_version_check;

	function sys_priv_check (
		sys_priv						in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_priv_count		pls_integer := 0;
	
	begin
	
		dbms_application_info.set_action('sys_priv_check');

		select
			count(*)
		into
			l_priv_count
		from
			session_privs
		where
			privilege = upper(sys_priv);

		if l_priv_count > 0 then
			l_ret_val := true;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end sys_priv_check;

	function object_is_valid (
		obj_name						in				varchar2
		, obj_type						in				varchar2
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_obj_status		varchar2(50);
	
	begin
	
		dbms_application_info.set_action('object_is_valid');

		select status
		into l_obj_status
		from user_objects
		where object_name = upper(obj_name)
		and object_type = upper(obj_type);

		if l_obj_status = 'VALID' then
			l_ret_val := true;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end object_is_valid;

begin

	dbms_application_info.set_client_info('ninja_validate');
	dbms_session.set_identifier('ninja_validate');

end ninja_validate;
/