create or replace package body ninja_compile

as

	procedure initiate_compilation (
	  npg             	in out       	ninja_parse.ninja_package
		, file_id					in						number
		, compile_user		in						varchar2
	)

	as

		l_compile_id					varchar2(1024);

		l_message							varchar2(4000);
		l_result							integer;

	begin

	  dbms_application_info.set_action('initiate_compilation');

		-- Create temporary content holder
		l_compile_id := ninja_npg_utils.create_execute_object(npg.ninja_id, npg.npg_files(file_id).file_content);

		-- Run the execute object
		ninja_npg_utils.run_execute_object(l_compile_id, npg.ninja_id, compile_user, l_result, l_message);

		ninja_npg_utils.log_entry(npg.ninja_id, l_compile_id || ' signalled: ' || l_message);

		if l_result = 1 then
			-- Timeout happened. Consider failed and set to rollback;
			npg.npg_files(file_id).compile_success := -1;
			npg.npg_files(file_id).compile_error := -1;
			npg.package_meta.pg_install_status := -1;
		elsif l_result = 0 then
			-- We got the message back. Check the status.
			if l_message = '1' then
				-- Success.
				npg.npg_files(file_id).compile_success := 1;
			else
				npg.npg_files(file_id).compile_success := -1;
				npg.npg_files(file_id).compile_error := -1;
				npg.package_meta.pg_install_status := -1;
			end if;
		end if;

		-- Cleanup
		ninja_npg_utils.clear_completed_execute_object(l_compile_id);

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
				npg.npg_files(file_id).compile_success := -1;
				npg.npg_files(file_id).compile_error := -1;
				npg.package_meta.pg_install_status := -1;
				ninja_npg_utils.clear_completed_execute_object(l_compile_id);

	end initiate_compilation;

	function compile_file_id (
		npg							in out				ninja_parse.ninja_package
		, file_id				in						number
	)
	return boolean

	as

		l_ret_val				boolean := false;
		l_object_name		varchar2(128);
		l_errnum				number;
		l_errmsg				varchar2(200);

		-- Session settings
		l_npg_user							varchar2(1024) := sys_context('USERENV', 'CURRENT_SCHEMA');
		l_npg_install						varchar2(1024) := sys_context('USERENV', 'SESSION_USER');

	begin

		dbms_application_info.set_action('compile_file_id');

		if instr(npg.npg_files(file_id).file_name, '.') > 0 then
			l_object_name := substr(npg.npg_files(file_id).file_name, 1, instr(npg.npg_files(file_id).file_name, '.') - 1);
		else
			l_object_name := npg.npg_files(file_id).file_name;
		end if;

		-- We need to check that the file we are compiling is not the install.order or the readme.md
		if upper(trim(npg.npg_files(file_id).file_name)) in ('README.MD', 'INSTALL.ORDER') then
			ninja_npg_utils.log_entry(npg.ninja_id, 'File: ' || npg.npg_files(file_id).file_name || ' is meta file and should not be compiled.');
		else
			ninja_npg_utils.log_entry(npg.ninja_id, 'Before compilation of: ' || l_object_name);
			-- execute immediate npg.npg_files(file_id).file_content;
			initiate_compilation(npg, file_id, l_npg_install);
			ninja_npg_utils.log_entry(npg.ninja_id, 'After compilation of: ' || l_object_name);
		end if;

		--if ninja_validate.object_is_valid(l_object_name, npg.npg_files(file_id).file_type) then
		--	l_ret_val := true;
		--end if;
		if npg.npg_files(file_id).compile_success = 1 then
			l_ret_val := true;
		end if;

		dbms_application_info.set_action(null);

		return l_ret_val;

		exception
			when others then
				l_errnum := SQLCODE;
				l_errmsg := substr(sqlerrm, 1, 200);
				dbms_application_info.set_action(null);
				npg.npg_files(file_id).compile_success := -1;
				npg.npg_files(file_id).compile_error := l_errnum;
				npg.package_meta.pg_install_status := -1;
				ninja_npg_utils.log_entry(npg.ninja_id, 'Installation of ' || l_object_name || ' with error: ' || l_errmsg);
				return l_ret_val;

	end compile_file_id;

	function compile_file_name (
		npg								in out			ninja_parse.ninja_package
		, file_name				in					varchar2
	)
	return boolean

	as

		l_ret_val			boolean := false;

	begin

		dbms_application_info.set_action('compile_file_name');

		ninja_npg_utils.log_entry(npg.ninja_id, 'Compiling ' || file_name);

		for i in 1..npg.npg_files.count() loop
			if npg.npg_files(i).file_name = file_name then
				l_ret_val := ninja_compile.compile_file_id(
					npg 		=> npg
					, file_id	=> i
				);
			end if;
		end loop;

		dbms_application_info.set_action(null);

		return l_ret_val;

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end compile_file_name;

	procedure compile_npg (
		npg										in out				ninja_parse.ninja_package
		, cli_generated_id		in						varchar2 default null
	)

	as

		type ordered_install is table of varchar2(512) index by pls_integer;
		l_ret_val					boolean;
		l_file_name				varchar2(256);
		l_file_type				varchar2(256);

		-- For looping lines
		l_offset					number := 1;
		l_amount					number;
		l_len							number;
		buf								varchar2(32767);

	begin

		dbms_application_info.set_action('compile_npg');

		-- Check if the npg package contains the install.order file
		if npg.package_meta.pg_order_file = 1 then
			-- We should read the contents of this file to get install order
			for i in 1..npg.npg_files.count() loop
				if npg.npg_files(i).file_name = 'install.order' then
					-- Let us parse the installation order from this file.
					-- Please note, at current no check will done to see if install.order file
					-- list all files contained in the package.
					-- Loop over every line in the file
					l_len := dbms_lob.getlength(npg.npg_files(i).file_content);
					while l_offset < l_len loop
						l_amount := least(dbms_lob.instr(npg.npg_files(i).file_content, chr(10), l_offset) - l_offset, 32767);
						if l_amount > 0 then
							dbms_lob.read(npg.npg_files(i).file_content, l_amount, l_offset, buf);
							l_offset := l_offset + l_amount + 1;
						else
							buf := null;
							l_offset := l_offset + 1;
						end if;
						if buf is not null then
							l_file_name := substr(buf, 1, instr(buf,':') - 1);
							l_file_type := ltrim(substr(buf, instr(buf,':') + 1));
							ninja_npg_utils.log_entry(npg.ninja_id, 'From install.order: ' || l_file_name || ' - ' || l_file_type);
							if l_file_name is null or l_file_type is null then
								npg.npg_files(i).compile_success := -1;
								npg.npg_files(i).compile_error := -1;
								npg.package_meta.pg_install_status := -1;
							else
								-- Now we have the required info to compile the file.
								ninja_npg_utils.log_entry(npg.ninja_id, 'Compiling source: ' || l_file_name, cli_generated_id);
								l_ret_val := ninja_compile.compile_file_name (
									npg						=>		npg
									, file_name		=>		l_file_name
								);
								-- If installation is a success then register the object.
								if l_ret_val then
									ninja_register.register_installed_obj(
										obj_name_in					=> l_file_name
										, obj_type_in				=> l_file_type
										, npg_name_in				=> npg.package_meta.pg_name
										, npg_pkg_version		=> npg.package_meta.pg_version_major || '.' || npg.package_meta.pg_version_minor || '.' || npg.package_meta.pg_version_fix
									);
								end if;
							end if;
						end if;
					end loop;
				end if;
			end loop;
		else
			-- No install order file, install in array order
			for i in 1..npg.npg_files.count() loop
				l_ret_val := ninja_compile.compile_file_id (
					npg			=>	npg
					, file_id	=>	i
				);
			end loop;
		end if;

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end compile_npg;

	procedure rollback_npg (
	  npg						in out				ninja_parse.ninja_package
	)

	as

			l_object_name						varchar2(128);
			l_d_cmd									varchar2(4000);
			l_object_not_found			exception;
			pragma									exception_init(l_object_not_found, -4043);
			l_compile_id						varchar2(1024);
			l_npg_user							varchar2(1024) := sys_context('USERENV', 'CURRENT_SCHEMA');
			l_npg_install						varchar2(1024) := sys_context('USERENV', 'SESSION_USER');
			l_message								varchar2(4000);
			l_result								integer;

	begin

	  dbms_application_info.set_action('rollback_npg');

		ninja_npg_utils.log_entry(npg.ninja_id, 'Rolling back sources.');

		for i in 1..npg.npg_files.count() loop
			if instr(npg.npg_files(i).file_name, '.') > 0 then
				l_object_name := substr(npg.npg_files(i).file_name, 1, instr(npg.npg_files(i).file_name, '.') - 1);
			else
				l_object_name := npg.npg_files(i).file_name;
			end if;
			ninja_npg_utils.log_entry(npg.ninja_id, 'Rolling back: ' || l_object_name);
			if npg.npg_files(i).file_name != 'order.install' then
				if npg.npg_files(i).file_type not in ('package body', 'order file') then
					l_d_cmd := 'drop ' || npg.npg_files(i).file_type || ' ' || l_object_name;

					-- Create the temporary execution object.
					l_compile_id := ninja_npg_utils.create_execute_object(npg.ninja_id, l_d_cmd);

					-- Run the execute object.
					ninja_npg_utils.run_execute_object(l_compile_id, npg.ninja_id, l_npg_install, l_result, l_message);

					ninja_npg_utils.log_entry(npg.ninja_id, l_compile_id || ' signalled: ' || l_message);

					if l_result = 1 then
						-- Timeout happened. Consider failed. Alert about rollback failure.
						null;
					elsif l_result = 0 then
						-- We got the message back. Check the status.
						if l_message = '1' then
							-- Success.
							ninja_npg_utils.log_entry(npg.ninja_id, npg.npg_files(i).file_type || ' ' || l_object_name || ' rolled back successfully.');
						else
							-- Something went wrong with rollback.
							ninja_npg_utils.log_entry(npg.ninja_id, npg.npg_files(i).file_type || ' ' || l_object_name || ' rollback failed.');
						end if;
					end if;

					-- Cleanup
					ninja_npg_utils.clear_completed_execute_object(l_compile_id);
				end if;
			end if;
		end loop;

	  dbms_application_info.set_action(null);

	  exception
			when l_object_not_found then
				dbms_application_info.set_action(null);
				null;
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end rollback_npg;

begin

	dbms_application_info.set_client_info('ninja_compile');
	dbms_session.set_identifier('ninja_compile');

end ninja_compile;
/
