create or replace package body ninja_compile

as

	function compile_file_id (
		npg							in out				ninja_parse.ninja_package
		, file_id				in						number
	)
	return boolean

	as

		l_ret_val			boolean := false;
		l_object_name		varchar2(128);

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
				dbms_application_info.set_action(null);
				raise;

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
		l_ret_val			boolean;

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
					null;
				end if;
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

begin

	dbms_application_info.set_client_info('ninja_compile');
	dbms_session.set_identifier('ninja_compile');

end ninja_compile;
/
