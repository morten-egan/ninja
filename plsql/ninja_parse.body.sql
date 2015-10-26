create or replace package body ninja_parse

as
	
	procedure parse_spec_file (
		spec_file						in				clob
		, npg							in out			ninja_package
	)
	
	as

		-- For looping lines
		l_offset						number := 1;
		l_amount						number;
		l_len							number := dbms_lob.getlength(spec_file);
		buf								varchar2(32767);

		-- For parse control
		l_met_start						boolean := false;
		l_met_end						boolean := false;
		l_current_block					varchar2(50);

	begin
	
		dbms_application_info.set_action('parse_spec_file');

		-- Loop over all lines
		while l_offset < l_len loop
			l_amount := least(dbms_lob.instr(spec_file, chr(10), l_offset) - l_offset, 32767);
			if l_amount > 0 then
				dbms_lob.read(spec_file, l_amount, l_offset, buf);
				l_offset := l_offset + l_amount + 1;
			else
				buf := null;
				l_offset := l_offset + 1;
			end if;
			-- This is where we actually parse the lines
			if l_met_start and not l_met_end then
				-- We are inside the spec block
				-- First chec if we have reached the end
				if instr(buf, '[npgend]') > 0 then
					l_met_end := true;
				else
					-- We have not, so parse the line.
					-- Check if we are seeing a new block, and if so set current block
					if substr(buf,1,1) = '[' then
						-- We are in a new block, set it to current
						l_current_block := substr(buf, 2, instr(buf,']')-2);
					else
						-- Parse line based on current block
						if l_current_block = 'options' then
							null;
						elsif l_current_block = 'metadata' then
							null;
						elsif l_current_block = 'require' then
							null;
						elsif l_current_block = 'files' then
							null;
						end if;
					end if;
				end if;
			elsif l_met_start and l_met_end then
				-- We are outside the block, ignore rest and exit
				exit;
			else
				if instr(buf, '[npgstart]') > 0 then
					l_met_start := true;
				end if;
			end if;
		end loop;
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end parse_spec_file;

	procedure unpack_binary_npg (
		npg_binary						in				blob
		, npg							in out			ninja_package
	)
	
	as

		npg_file_list					zip_util_pkg.t_file_list;
		spec_file						clob;
		unpack_error					exception;
		pragma							exception_init(unpack_error, -20001);
	
	begin
	
		dbms_application_info.set_action('unpack_binary_npg');

		-- Extract the spec file from the package file, and parse that
		-- If this does not exist, we break and raise, with invalid NPG file.
		spec_file := ninja_npg_utils.blob_to_clob(zip_util_pkg.get_file(npg_binary, 'npg.spec'));
		if spec_file is null then
			dbms_application_info.set_action(null);
			raise_application_error(-20001, 'Invalid NPG format: No npg.spec present');
		end if;

		-- Spec file is there, so let us parse it.
		parse_spec_file(spec_file, npg);
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end unpack_binary_npg;

	procedure validate_package (
		npg						in out				ninja_package
	)
	
	as
	
	begin
	
		dbms_application_info.set_action('validate_package');
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end validate_package;

begin

	dbms_application_info.set_client_info('ninja_parse');
	dbms_session.set_identifier('ninja_parse');

end ninja_parse;
/