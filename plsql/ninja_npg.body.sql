create or replace package body ninja_npg

as

	procedure recursive_iu (
	  npg             					in out       	ninja_parse.ninja_package
		, repository							in						varchar2 default null
		, cli_generated_id				in						varchar2 default null
	)

	as

		l_pkg_exists							varchar2(20);

		install_failed						exception;
		pragma										exception_init(install_failed, -20001);

	begin

	  dbms_application_info.set_action('recursive_iu');

		-- Let us check if there are any extra NPG packages that we need to install.
		for i in 1..npg.requirements.count() loop
			if npg.requirements(i).require_type = 'package' and npg.requirements(i).require_met = -1 then
				ninja_npg_utils.log_entry(npg.ninja_id, 'NPG Package '|| npg.requirements(i).require_value ||' required and not installed.', cli_generated_id);
				-- Let us check
				l_pkg_exists := utl_http.request('plsql.ninja/npg/bin.cnpg?pv=' || npg.requirements(i).require_value);
				if trim(replace(l_pkg_exists,chr(10))) = '1' then
					ninja_npg_utils.log_entry(npg.ninja_id, npg.requirements(i).require_value ||' exists and is being installed.', cli_generated_id);
					-- NPG is there, we install before we continue on actual package.
					if instr(npg.requirements(i).require_value, '@') > 0 then
						install_p(
							package_name						=>				substr(npg.requirements(i).require_value, 1, instr(npg.requirements(i).require_value, '@') - 1)
							, package_version				=>				substr(npg.requirements(i).require_value, instr(npg.requirements(i).require_value, '@') + 1)
							, cli_generated_id			=>				cli_generated_id
						);
					else
						install_p(
							package_name						=>			npg.requirements(i).require_value
							, cli_generated_id			=>				cli_generated_id
						);
					end if;
				else
					-- Raise error.
					ninja_npg_utils.log_entry(npg.ninja_id, npg.requirements(i).require_value ||' does not exists.', cli_generated_id);
				end if;
			end if;
		end loop;

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end recursive_iu;

	function gs (
		sid											in				varchar2
	)
	return clob

	as

	  l_ret_var               clob;

	begin

	  dbms_application_info.set_action('gs');

		select
			compile_source
		into
			l_ret_var
		from
			ninja_compile_temp
		where
			compile_id = sid;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end gs;

	procedure sc (
	  sid             				in        varchar2
		, sm										in				varchar2
	)

	as

	begin

	  dbms_application_info.set_action('sc');

		dbms_alert.signal(
			name				=>			sid
			, message		=>			sm
		);

		commit;

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end sc;

	function cli_log (
		cli_generated_id				in				varchar2
	)
	return cli_tab
	pipelined

	as

	  l_ret_var               cli_rec;

		cursor get_log_entries is
			select
				nil.entry
				, nil.entry_time
			from
				ninja_install_log nil
			where
				nil.ninja_id = cli_generated_id
			order by
				nil.entry_time asc;

	begin

	  dbms_application_info.set_action('cli_log');

		for ent in get_log_entries loop
			l_ret_var.cli_mesg_date := ent.entry_time;
			l_ret_var.cli_generated_id := cli_generated_id;
			l_ret_var.mesg := ent.entry;
			pipe row(l_ret_var);
		end loop;

	  dbms_application_info.set_action(null);

	  return;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end cli_log;

	function list_p (
		list_type								in				varchar2 default 'short'
	)
	return list_tab
	pipelined

	as

	  l_ret_var               list_rec;
		l_listfrom							varchar2(128) := sys_context('USERENV', 'SESSION_USER');

		cursor get_installed is
			select
				npg_name
				, installed_schema
				, installed_hash
				, pg_version
				, install_date
				, pg_author
				, upgrade_date
				, install_id
			from
				ninja_installed_packages
			where
				installed_schema = l_listfrom
			order by
				npg_name asc;

	begin

	  dbms_application_info.set_action('list_p');

		for lst in get_installed loop
			if list_type = 'short' then
				l_ret_var.npg_name := lst.npg_name;
				l_ret_var.npg_output := ' (' || lst.pg_version || ' - ' || lst.installed_schema || ')';
				pipe row(l_ret_var);
			elsif list_type = 'all' then
				l_ret_var.npg_name := lst.npg_name;
				l_ret_var.npg_output := ' ';
				pipe row(l_ret_var);
				l_ret_var.npg_name := ' ';
				l_ret_var.npg_output := ' Installed on ' || to_char(lst.install_date, 'DD-Mon-YYYY');
				pipe row(l_ret_var);
				l_ret_var.npg_name := ' ';
				l_ret_var.npg_output := ' Version installed ' || lst.pg_version || ' (' || lst.installed_hash || ')';
				pipe row(l_ret_var);
			end if;
		end loop;

	  dbms_application_info.set_action(null);

	  return;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end list_p;

	procedure install_p (
		package_name							in				varchar2
		, package_version					in				varchar2 default null
		, repository							in				varchar2 default null
		, cli_generated_id				in				varchar2 default null
	)

	as

		l_ninja_npg							ninja_parse.ninja_package;
		l_ninja_binary					blob;
		l_ninja_id							varchar2(1024) := sys_guid();
		l_installto							varchar2(128) := sys_context('USERENV', 'SESSION_USER');

		-- Exception
		install_failed					exception;
		pragma									exception_init(install_failed, -20001);

	begin

		dbms_application_info.set_action('install_p');

		-- As the very first step, set the ID of the package installation.
		l_ninja_npg.ninja_id := l_ninja_id;

		ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Starting installation of: ' || package_name, cli_generated_id);
		ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Session user is: ' || l_installto, cli_generated_id);

		-- First we check if the package is already installed, and if it is,
		-- inform that we should be using update instead.
		if not ninja_npg_utils.check_install_status(package_name) then
			-- We are ok to install
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package: ' || package_name || ' ready to be installed.', cli_generated_id);
			-- Download binary to start the process
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Downloading NPG file.', cli_generated_id);
			l_ninja_binary := ninja_download.get_npg(package_name, package_version, repository);
			-- Unpack the spec file into the npg type
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Unpacking npg zip file.', cli_generated_id);
			ninja_parse.unpack_binary_npg(l_ninja_binary, l_ninja_npg);
			-- From here we need to check in each step if we are ok. If not break installation.
			if l_ninja_npg.npg_runtime.requirement_failed < 0 then
				-- Something failed in the unpacking of the NPG binary. Rollback.
				ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Failure in binary unpack.');
				ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package ' || package_name || ' installation failed. Rolling back install.', cli_generated_id);
				ninja_compile.rollback_npg(l_ninja_npg);
				if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
					raise_application_error(-20001, 'Installation failed. Rollback initiated.');
				end if;
			else
				-- Now the spec file is unpackd, and we have the basic npg structure.
				-- Let us validate requirements
				ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Validating NPG requirements.', cli_generated_id);
				ninja_parse.validate_package(l_ninja_npg);
				-- Here we to check if all requirements are validated and if not we break the installation.
				if l_ninja_npg.npg_runtime.requirement_failed < 0 then
					-- Requirements validation failed. We are rolling back.
					ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Requirement validation failed.', cli_generated_id);
					if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
						raise_application_error(-20001, 'Installation failed. Rollback initiated.');
					end if;
				else
					-- Requirements are validated. Now check if we need to install extra packages.
					ninja_npg.recursive_iu(l_ninja_npg, repository, cli_generated_id);
					ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'All NPG requirements validated.', cli_generated_id);
					-- All requirements are validated or fixed. Let us install the package
					ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Compiling sources.', cli_generated_id);
					ninja_compile.compile_npg(l_ninja_npg);
					-- Let us check if the compilation was successfull. If not rollback.
					if l_ninja_npg.package_meta.pg_install_status < 0 then
						-- We failed in the install. Let us rollback the installation.
						ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package ' || package_name || ' installation failed. Rolling back install.', cli_generated_id);
						ninja_compile.rollback_npg(l_ninja_npg);
						-- We have rolled back. Raise exception to inform about failure.
						if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
							raise_application_error(-20001, 'Installation failed. Rollback initiated.');
						end if;
					else
						-- Sources are installed successfully. Register installed package
						ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Sources compiled without errors.', cli_generated_id);
						ninja_register.register_install(l_ninja_npg);
						-- Notify of success.
						ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, '1 NPG installed successfully.', cli_generated_id);
					end if;
				end if;
			end if;
		else
			-- Already installed. Use update instead
			ninja_npg_utils.log_entry(l_ninja_npg.ninja_id, 'Package ' || package_name || ' already installed. Please use update instead.', cli_generated_id);
			if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
				raise_application_error(-20001, 'Already installed. Use update_p.');
			end if;
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
		, cli_generated_id				in				varchar2 default null
	)

	as

		l_ninja_id								varchar2(1024) := sys_guid();

	begin

		dbms_application_info.set_action('delete_p');

		ninja_npg_utils.log_entry(l_ninja_id, 'Deleting: ' || package_name, cli_generated_id);

		if ninja_npg_utils.check_install_status(package_name) then
			-- Package is installed.
			ninja_npg_utils.log_entry(l_ninja_id, 'Package is owned by schema, and can be removed.', cli_generated_id);
			ninja_delete.delete_package(package_name, force_delete);
			ninja_npg_utils.log_entry(l_ninja_id, '1 NPG package successfully deleted.', cli_generated_id);
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
