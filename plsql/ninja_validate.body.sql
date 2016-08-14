create or replace package body ninja_validate

as

	function obj_already_exist (
		object_name						in				varchar2
	)
	return boolean

	as

		l_ret_val							boolean := false;
		assert_exception			exception;
		pragma								exception_init(assert_exception, -44002);
		obj_verified					varchar2(128);

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
		l_interm_chk	number := 0;

	begin

		dbms_application_info.set_action('db_version_check');

		chk_stmt := 'declare v1 number; begin if dbms_db_version.'|| db_version_met ||' then :b1 := 1; end if; end;';
		execute immediate chk_stmt using in out l_interm_chk;

		if l_interm_chk > 0 then
			l_ret_val := true;
		end if;

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
		obj_name							in				varchar2
		, obj_type						in				varchar2
	)
	return boolean

	as

		l_ret_val				boolean := false;
		l_obj_status		varchar2(50);
		l_tst						varchar2(30);

	begin

		dbms_application_info.set_action('object_is_valid');

		select username
		into l_tst
		from user_users;

		-- Catch object_type for known objects where we have to select in all_users instead.
		if upper(obj_type) in ('CONTEXT') then
			select status
			into l_obj_status
			from all_objects
			where object_name = upper(obj_name)
			and object_type = upper(obj_type);
		else
			select status
			into l_obj_status
			from user_objects
			where object_name = upper(obj_name)
			and object_type = upper(obj_type);
		end if;

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

	function option_is_enabled (
		opt_name									in				varchar2
	)
	return boolean

	as

	  l_ret_var               	boolean := false;
		l_option_value						varchar2(20);

	begin

	  dbms_application_info.set_action('option_is_enabled');

		select
			value
		into
			l_option_value
		from
			v$option
		where
			upper(parameter) = upper(opt_name);

		if l_option_value = 'TRUE' then
			l_ret_var := true;
		end if;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end option_is_enabled;

	function can_execute (
		package_name							in				varchar2
	)
	return boolean

	as

	  l_ret_var               boolean := false;
		l_priv_count						number := 0;

	begin

	  dbms_application_info.set_action('can_execute');

		select count(*)
		into l_priv_count
		from all_tab_privs
		where type = 'PACKAGE'
		and upper(table_name) = upper(package_name);

		if l_priv_count > 0 then
			l_ret_var := true;
		end if;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end can_execute;

	function npg_require (
		require_string						in				varchar2
	)
	return boolean

	as

	  l_ret_var               boolean := false;
		l_require_npg_name			varchar2(1024);
		l_require_npg_version		varchar2(1024) := null;

	begin

	  dbms_application_info.set_action('npg_require');

		if instr(require_string,'@') > 0 then
			l_require_npg_name := substr(require_string,1,instr(require_string,'@') - 1);
			l_require_npg_version := substr(require_string, instr(require_string,'@') + 1);
		else
			l_require_npg_name := require_string;
		end if;

		if ninja_npg_utils.check_install_status(l_require_npg_name) then
			-- At least the package is installed.
			-- Check if we should verify version.
			if l_require_npg_version is not null then
				-- We need to check the version.
				null;
			else
				-- We only require the package, no specific version.
				l_ret_var := true;
			end if;
		end if;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end npg_require;

begin

	dbms_application_info.set_client_info('ninja_validate');
	dbms_session.set_identifier('ninja_validate');

end ninja_validate;
/
