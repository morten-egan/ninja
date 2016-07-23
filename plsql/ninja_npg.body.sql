create or replace package body ninja_npg

as

	procedure install_p (
		package_name							in				varchar2
		, package_version					in				varchar2 default null
		, repository							in				varchar2 default null
	)

	as

		l_ninja_npg							ninja_parse.ninja_package;
		l_ninja_binary					blob;
		l_ninja_id							varchar2(1024) := sys_guid();

		-- Exception
		install_failed					exception;
		pragma									exception_init(install_failed, -20001);

	begin

		dbms_application_info.set_action('install_p');

		-- As the very first step, set the ID of the package installation.
		l_ninja_npg.ninja_id := l_ninja_id;

		ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Starting installation of: ' || package_name);

		-- First we check if the package is already installed, and if it is,
		-- inform that we should be using update instead.
		if not ninja_npg_utils.check_install_status(package_name) then
			-- We are ok to install
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package: ' || package_name || ' ready to be installed.');
			-- Download binary to start the process
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Downloading NPG file.');
			l_ninja_binary := ninja_download.get_npg(package_name, package_version, repository);
			-- Unpack the spec file into the npg type
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Unpacking npg zip file.');
			ninja_parse.unpack_binary_npg(l_ninja_binary, l_ninja_npg);
			-- Now the spec file is unpackd, and we have the basic npg structure.
			-- Let us validate requirements
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Validating NPG requirements.');
			ninja_parse.validate_package(l_ninja_npg);
			-- Requirements are validated. Let us install the package
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Compiling sources.');
			ninja_compile.compile_npg(l_ninja_npg);
			-- Let us check if the compilation was successfull. If not rollback.
			if l_ninja_npg.package_meta.pg_install_status < 0 then
				-- We failed in the install. Let us rollback the installation.
				ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package ' || package_name || ' installation failed. Rolling back install.');
				ninja_compile.rollback_npg(l_ninja_npg);
				-- We have rolled back. Raise exception to inform about failure.
				raise_application_error(-20001, 'Installation failed. Rollback initiated.');
			else
				-- Sources are installed successfully. Register installed package
				ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Sources installed successfully.');
				ninja_register.register_install(l_ninja_npg);
			end if;
		else
			-- Already installed. Use update instead
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package ' || package_name || ' already installed. Please use update instead.');
			raise_application_error(-20001, 'Already installed. Use update_p.');
		end if;

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end install_p;

	procedure update_p (
		package_name						in				varchar2
		, package_version				in				varchar2 default null
		, repository						in				varchar2 default null
	)

	as

	begin

		dbms_application_info.set_action('update_p');

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end update_p;

	procedure delete_p(
		package_name							in				varchar2
		, force_delete						in				varchar2 default 'no'
	)

	as

	begin

		dbms_application_info.set_action('delete_p');

		-- ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Starting installation of: ' || package_name);

		if ninja_npg_utils.check_install_status(package_name) then
			-- Package is installed.
			ninja_delete.delete_package(package_name, force_delete);
		else
			null;
		end if;

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
