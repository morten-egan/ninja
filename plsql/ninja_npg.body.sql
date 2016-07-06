create or replace package body ninja_npg

as

	procedure install_p (
		package_name							in				varchar2
		, package_version					in				varchar2 default null
		, repository							in				varchar2 default null
	)

	as

		l_ninja_npg				ninja_parse.ninja_package;
		l_ninja_binary		blob;

	begin

		dbms_application_info.set_action('install_p');

		-- First we check if the package is already installed, and if it is,
		-- inform that we should be using update instead.
		if not ninja_npg_utils.check_install_status(package_name) then
			-- We are ok to install
			-- Download binary to start the process
			l_ninja_binary := ninja_download.get_npg(package_name, package_version, repository);
			-- Unpack the spec file into the npg type
			ninja_parse.unpack_binary_npg(l_ninja_binary, l_ninja_npg);
			-- Now the spec file is unpackd, and we have the basic npg structure.
			-- Let us validate requirements
			ninja_parse.validate_package(l_ninja_npg);
			-- Requirements are validated. Let us install the package
			ninja_compile.compile_npg(l_ninja_npg);
			-- Sources are installed successfully. Register installed package
			ninja_register.register_install(l_ninja_npg);
		else
			-- Already installed. Use update instead
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
