create or replace package body ninja_parse

as

	procedure parse_spec_file (
		spec_file						in					clob
		, npg								in out			ninja_package
	)

	as

		-- For looping lines
		l_offset								number := 1;
		l_amount								number;
		l_len										number := dbms_lob.getlength(spec_file);
		buf											varchar2(32767);

		-- For parse control
		l_met_start							boolean := false;
		l_met_end								boolean := false;
		l_current_block					varchar2(50);

		-- For line parsing
		l_line_name							varchar2(100);
		l_line_value						varchar2(4000);
		l_requirements					pg_requirements;
		l_requirements_idx			pls_integer := 1;
		l_files									pg_files;
		l_files_idx							pls_integer := 1;

		-- For required fields
		type l_bool_table				is table of boolean index by varchar2(50);
		l_required_parsed				l_bool_table;
		l_required_idx					varchar2(50);

		-- Exception
		missing_required				exception;
		pragma									exception_init(missing_required, -20001);

	begin

		dbms_application_info.set_action('parse_spec_file');

		-- Set required fields to false
		l_required_parsed('options') := false;
		-- Options sub fields
		l_required_parsed('ninjaversion') := false;
		l_required_parsed('ninjaformat') := false;
		l_required_parsed('metadata') := false;
		-- Metadata sub fields
		l_required_parsed('name') := false;
		l_required_parsed('version') := false;
		l_required_parsed('description') := false;
		l_required_parsed('author') := false;
		l_required_parsed('key') := false;
		l_required_parsed('require') := false;
		-- Require sub fields
		l_required_parsed('ordbms') := false;
		l_required_parsed('files') := false;

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
						l_required_parsed(l_current_block) := true;
					else
						-- Parse line based on current block
						l_line_name := substr(buf, 1, instr(buf,':') - 1);
						l_line_value := ltrim(substr(buf, instr(buf,':') + 1));
						if l_current_block = 'options' then
							if l_line_name = 'ninjaversion' then
								for vers in (select rownum, column_value from table(ninja_npg_utils.split_string(l_line_value, '.'))) loop
									if vers.rownum = 1 then
										npg.npg_meta.npg_version_major := vers.column_value;
									elsif vers.rownum = 2 then
										npg.npg_meta.npg_version_minor := vers.column_value;
									elsif vers.rownum = 3 then
										npg.npg_meta.npg_version_fix := vers.column_value;
									end if;
								end loop;
								l_required_parsed('ninjaversion') := true;
							elsif l_line_name = 'ninjaformat' then
								npg.npg_meta.npg_format := l_line_value;
								l_required_parsed('ninjaformat') := true;
							end if;
						elsif l_current_block = 'metadata' then
							if l_line_name = 'name' then
								npg.package_meta.pg_name := l_line_value;
								l_required_parsed('name') := true;
							elsif l_line_name = 'description' then
								npg.package_meta.pg_description := l_line_value;
								l_required_parsed('description') := true;
							elsif l_line_name = 'author' then
								npg.package_meta.pg_author := l_line_value;
								l_required_parsed('author') := true;
							elsif l_line_name = 'key' then
								npg.package_meta.pg_key := l_line_value;
								l_required_parsed('key') := true;
							elsif l_line_name = 'version' then
								for vers in (select rownum, column_value from table(ninja_npg_utils.split_string(l_line_value, '.'))) loop
									if vers.rownum = 1 then
										npg.package_meta.pg_version_major := vers.column_value;
									elsif vers.rownum = 2 then
										npg.package_meta.pg_version_minor := vers.column_value;
									elsif vers.rownum = 3 then
										npg.package_meta.pg_version_fix := vers.column_value;
									end if;
								end loop;
								l_required_parsed('version') := true;
							end if;
						elsif l_current_block = 'require' then
							l_requirements(l_requirements_idx).require_type := l_line_name;
							l_requirements(l_requirements_idx).require_value := l_line_value;
							l_requirements(l_requirements_idx).require_met := 0;
							if l_line_name = 'ordbms' then
								l_required_parsed('ordbms') := true;
							end if;
							l_requirements_idx := l_requirements_idx + 1;
						elsif l_current_block = 'files' then
							ninja_npg_utils.log_entry(npg.ninja_id, 'Found file ' || l_line_name || ':' || l_line_value);
							l_files(l_files_idx).file_name := l_line_name;
							l_files(l_files_idx).file_type := l_line_value;
							l_files(l_files_idx).compile_success := 0;
							l_files(l_files_idx).compile_error := 0;
							if l_line_name = 'install.order' then
								ninja_npg_utils.log_entry(npg.ninja_id, 'install.order file found.');
								npg.package_meta.pg_order_file := 1;
							end if;
							l_files_idx := l_files_idx + 1;
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

		-- Set the list of requirements and files
		npg.requirements := l_requirements;
		npg.npg_files := l_files;

		-- Set fixed attributes
		npg.package_meta.pg_install_status := 0;

		-- Check that all required fields are present in the spec file
		l_required_idx := l_required_parsed.first;
		while l_required_idx is not null loop
			if not l_required_parsed(l_required_idx) then
				ninja_npg_utils.log_entry(npg.ninja_id, 'Missing field in npg.spec: ' || l_required_idx);
				ninja_npg_utils.log_entry(npg.ninja_id, 'Aborting installation.');
				if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
					raise_application_error(-20001, 'Missing field in npg.spec: ' || l_required_idx);
				end if;
			end if;
			l_required_idx := l_required_parsed.next(l_required_idx);
		end loop;

		ninja_npg_utils.log_entry(npg.ninja_id, 'Parse done. All required fields present in spec file.');

		dbms_application_info.set_action(null);

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end parse_spec_file;

	procedure unpack_binary_npg (
		npg_binary						in					blob
		, npg									in out			ninja_package
	)

	as

		spec_file									clob;
		l_individual_file					blob;
		unpack_error							exception;
		pragma										exception_init(unpack_error, -20001);

	begin

		dbms_application_info.set_action('unpack_binary_npg');

		-- Extract the spec file from the package file, and parse that
		-- If this does not exist, we break and raise, with invalid NPG file.
		spec_file := ninja_npg_utils.blob_to_clob(zip_util_pkg.get_file(npg_binary, 'npg.spec'));
		if spec_file is null then
			dbms_application_info.set_action(null);
			ninja_npg_utils.log_entry(npg.ninja_id, 'Invalid NPG format: No npg.spec present.');
			ninja_npg_utils.log_entry(npg.ninja_id, 'Aborting installation.');
			if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
				raise_application_error(-20001, 'Invalid NPG format: No npg.spec present');
			end if;
		end if;

		-- Spec file is there, so let us parse it.
		ninja_npg_utils.log_entry(npg.ninja_id, 'Parsing spec file.');
		parse_spec_file(spec_file, npg);

		-- Now the spec file is parsed and field validated.
		-- Let us unpack all the file content
		ninja_npg_utils.log_entry(npg.ninja_id, 'Unpacking source files.');
		for i in 1..npg.npg_files.count() loop
			l_individual_file := zip_util_pkg.get_file(npg_binary, npg.npg_files(i).file_name);
			if l_individual_file is not null then
				ninja_npg_utils.log_entry(npg.ninja_id, 'Unpacking '|| npg.npg_files(i).file_name ||'.');
				npg.npg_files(i).file_content := ninja_npg_utils.blob_to_clob(l_individual_file);
			else
				ninja_npg_utils.log_entry(npg.ninja_id, 'File present in spec, but not in data: ' || npg.npg_files(i).file_name);
				if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
					raise_application_error(-20001, 'File present in spec, but not in data: ' || npg.npg_files(i).file_name);
				end if;
			end if;
		end loop;

		ninja_npg_utils.log_entry(npg.ninja_id, 'Binary NPG unpacked successfully.');

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

		validation_error				exception;
		pragma									exception_init(validation_error, -20001);

	begin

		dbms_application_info.set_action('validate_package');

		-- Check if we have the right privileges as required in the spec file.
		-- Let us go through all the requirements one-by-one
		for i in 1..npg.requirements.count() loop
			ninja_npg_utils.log_entry(npg.ninja_id, 'Validating requirement ' || npg.requirements(i).require_type || ' with value ' || npg.requirements(i).require_value);
			if npg.requirements(i).require_type = 'privilege' then
				if not ninja_validate.sys_priv_check(npg.requirements(i).require_value) then
					npg.requirements(i).require_met := -1;
					ninja_npg_utils.log_entry(npg.ninja_id, 'Privilege ' || npg.requirements(i).require_value || ' not granted.');
					if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
						raise_application_error(-20001, 'Privilege ' || npg.requirements(i).require_value || ' not granted.');
					end if;
				else
					npg.requirements(i).require_met := 1;
				end if;
			elsif npg.requirements(i).require_type = 'ordbms' then
				if ninja_validate.db_version_check(npg.requirements(i).require_value) then
					npg.requirements(i).require_met := -1;
					ninja_npg_utils.log_entry(npg.ninja_id, 'Ordbms version: ' || npg.requirements(i).require_value || ' not met.');
					if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
						raise_application_error(-20001, 'Ordbms version: ' || npg.requirements(i).require_value || ' not met.');
					end if;
				else
					npg.requirements(i).require_met := 1;
				end if;
			elsif npg.requirements(i).require_type = 'execute' then
				if not ninja_validate.can_execute(npg.requirements(i).require_value) then
					npg.requirements(i).require_met := -1;
					ninja_npg_utils.log_entry(npg.ninja_id, 'Execute privilege on: ' || npg.requirements(i).require_value ||' not met.');
					if ninja_npg_utils.ninja_setting('raise_on_install') = 'true' then
						raise_application_error(-20001, 'Execute privilege on: ' || npg.requirements(i).require_value ||' not met.');
					end if;
				else
					npg.requirements(i).require_met := 1;
				end if;
			/*elsif npg.requirements(i).require_type = 'feature' then
				if not ninja_validate.option_is_enabled(npg.requirements(i).require_value) then
					raise_application_error(-20001, 'Feature: ' || npg.requirements(i).require_value || ' not enabled.');
				end if;*/
			elsif npg.requirements(i).require_type = 'package' then
				if not ninja_validate.npg_require(npg.requirements(i).require_value) then
					-- NPG package requirement not met. Check if we can install.
					npg.requirements(i).require_met := -1;
					ninja_npg_utils.log_entry(npg.ninja_id, 'NPG package requirement for ' || npg.requirements(i).require_value ||' not met.');
					-- For packages we do not throw an error. We will first check other place if we can install those packages, and if not then
					-- we throw error.
				else
					npg.requirements(i).require_met := 1;
				end if;
			end if;
		end loop;

		-- Then we get the SHA1 of the source.
		npg.package_meta.pg_hash := ninja_npg_utils.npg_source_hash(
			npg		=>		npg
		);

		ninja_npg_utils.log_entry(npg.ninja_id, 'All requirements validated.');

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
