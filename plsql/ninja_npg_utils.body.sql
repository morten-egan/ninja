create or replace package body ninja_npg_utils

as

	function check_install_status (
		package_name						in				varchar2
		, schema_name						in				varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
	)
	return boolean
	
	as
	
		l_ret_val			boolean := false;
		l_count				number;
	
	begin
	
		dbms_application_info.set_action('check_install_status');

		select count(nip.package_name)
		into l_count
		from ninja_installed_packages nip
		where nip.package_name = package_name
		and nip.installed_schema = schema_name;

		if l_count > 0 then
			l_ret_val := true;
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end check_install_status;

begin

	dbms_application_info.set_client_info('ninja_npg_utils');
	dbms_session.set_identifier('ninja_npg_utils');

end ninja_npg_utils;
/