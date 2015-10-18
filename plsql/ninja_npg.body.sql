create or replace package body ninja_npg

as

	procedure install_p (
		package_name						in				varchar2
		, package_version					in				varchar2 default null
		, repository						in				varchar2 default null
	)
	
	as
	
		l_ninja_npg			ninja_parse.ninja_npg;
		l_ninja_binary		blob;
	
	begin
	
		dbms_application_info.set_action('install_p');

		-- pipe row(action_stat_out('1', 'INFO', '-- Installing package: ' || package_name));
		-- First we check if the package is already installed, and if it is
		-- inform that we should be using update instead.
		if not ninja_npg_utils.check_install_status(package_name) then
			-- We are ok to install
			-- Download binary to start the process
			-- pipe row(action_stat_out('2', 'INFO', '-- Starting download of ' || package_name));
			l_ninja_binary := ninja_download.get_npg(package_name, package_version, repository);
			-- pipe row(action_stat_out('3', 'INFO', '--   Download complete'));
		else
			-- Already installed. Use update instead
			-- pipe row(action_stat_out(2, 'WARNING', '--  ' || package_name || ' is already installed. Please use update if newer version exists'));
			null;
		end if;

		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end install_p;

	procedure update_p (
		package_name						in				varchar2
		, package_version					in				varchar2 default null
		, repository						in				varchar2 default null
	)
	
	as
	
		l_ret_val			npg_line;
	
	begin
	
		dbms_application_info.set_action('update_p');

		-- pipe row(action_stat_out('1', 'DECORATE', '------------------------------'));
		-- pipe row(action_stat_out('1', 'INFO', '-- Updating package: ' || package_name));
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end update_p;

	procedure delete_p(
		package_name						in				varchar2
		, force_delete						in				varchar2 default 'no'
	)
	
	as
	
		l_ret_val			npg_line;
	
	begin
	
		dbms_application_info.set_action('delete_p');

		-- pipe row(action_stat_out('1', 'DECORATE', '------------------------------'));
		-- pipe row(action_stat_out('1', 'INFO', '-- Deleting package: ' || package_name));
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end delete_p;

begin

	dbms_application_info.set_client_info('ninja_npg');
	dbms_session.set_identifier('ninja_npg');

end ninja_npg;
/