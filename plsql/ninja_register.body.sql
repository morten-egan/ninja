create or replace package body ninja_register

as

	procedure register_install (
		npg						in out				ninja_parse.ninja_package
	)

	as

	begin

		dbms_application_info.set_action('register_install');

		-- Once here, we have installed the package and only thing missing
		-- is to register the installation in the installed packages table.
		insert into ninja_installed_packages (
			npg_name
			, installed_schema
			, installed_hash
			, pg_version
			, install_date
			, pg_author
		) values (
			npg.package_meta.pg_name
			, sys_context('USERENV', 'CURRENT_SCHEMA')
			, npg.package_meta.pg_hash
			, npg.package_meta.pg_version_major || '.' || npg.package_meta.pg_version_minor || '.' || npg.package_meta.pg_version_fix
			, sysdate
			, npg.package_meta.pg_author
		);

		commit;

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end register_install;

begin

	dbms_application_info.set_client_info('ninja_register');
	dbms_session.set_identifier('ninja_register');

end ninja_register;
/
