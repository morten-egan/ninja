create or replace package body ninja_compile

as

	function compile_file_id (
		npg							in out				ninja_parse.ninja_package
		, file_id				in						number
	)
	return boolean

	as

		l_ret_val				boolean := false;
		l_object_name		varchar2(128);
		l_errnum				number;

	begin

		dbms_application_info.set_action('compile_file_id');

		if instr(npg.npg_files(file_id).file_name, '.') > 0 then
			l_object_name := substr(npg.npg_files(file_id).file_name, 1, instr(npg.npg_files(file_id).file_name, '.') - 1);
		else
			l_object_name := npg.npg_files(file_id).file_name;
		end if;

		execute immediate npg.npg_files(file_id).file_content;

		if ninja_validate.object_is_valid(l_object_name, npg.npg_files(file_id).file_type) then
			l_ret_val := true;
		end if;

		dbms_application_info.set_action(null);

		return l_ret_val;

		exception
			when others then
				l_errnum := SQLCODE;
				dbms_application_info.set_action(null);
				npg.npg_files(file_id).compile_success := -1;
				npg.npg_files(file_id).compile_error := l_errnum;
				npg.package_meta.pg_install_status := -1;
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
		npg						in out				ninja_parse.ninja_package
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
							-- Now we have the required info to compile the file.
							l_ret_val := ninja_compile.compile_file_name (
								npg						=>		npg
								, file_name		=>		l_file_name
							);
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

		-- Now we are done with all compilations.
		-- Check if any errors and if there are, we rollback.
		if npg.package_meta.pg_install_status < 0 then
			dbms_output.put_line('Installation failed. Rollback started.');
		end if;

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end compile_npg;

begin

	dbms_application_info.set_client_info('ninja_compile');
	dbms_session.set_identifier('ninja_compile');

end ninja_compile;
/
