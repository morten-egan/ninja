create or replace package body ninja_npg_utils

as

	function blob_to_clob (
		bin_blob						in				blob
	)
	return clob

	as

		l_ret_val						clob;
		l_char							varchar2(32767);
		l_start							pls_integer := 1;
		l_buf							pls_integer := 32767;

	begin

		dbms_application_info.set_action('blob_to_clob');

		dbms_lob.createtemporary(l_ret_val, true);

		for i in 1..ceil(dbms_lob.getlength(bin_blob) / l_buf) loop
			l_char := utl_raw.cast_to_varchar2(dbms_lob.substr(bin_blob, l_buf, l_start));
			dbms_lob.writeappend(l_ret_val, length(l_char), l_char);
			l_start := l_start + l_buf;
		end loop;

		dbms_application_info.set_action(null);

		return l_ret_val;

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end blob_to_clob;

	function check_install_status (
		package_name						in				varchar2
		, schema_name						in				varchar2 default sys_context('USERENV', 'SESSION_USER')
	)
	return boolean

	as

		l_ret_val							boolean := false;
		l_count								number;

	begin

		dbms_application_info.set_action('check_install_status');

		select count(nip.npg_name)
		into l_count
		from ninja_installed_packages nip
		where nip.npg_name = package_name
		and nip.installed_schema = schema_name;

		if l_count > 0 then
			l_ret_val := true;
		end if;

		dbms_application_info.set_action(null);

		return l_ret_val;

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end check_install_status;

	function split_string (
		string_to_split						in				varchar2
		, delimiter							in				varchar2 default ','
	)
	return tab_strings
	pipelined

	as

		cursor c_tokenizer(ci_string in varchar2, ci_delimiter in varchar2) is
			select
				regexp_substr(str, '[^' || ci_delimiter || ']+', 1, level) as splitted_element,
				level as element_no
			from
				(select rownum as id, ci_string str from dual)
			connect by instr(str, ci_delimiter, 1, level - 1) > 0
			and id = prior id
			and prior dbms_random.value is not null;

	begin

		dbms_application_info.set_action('split_string');

		for c1 in c_tokenizer(string_to_split, delimiter) loop
			pipe row(c1.splitted_element);
		end loop;

		dbms_application_info.set_action(null);

		return;

		exception
			when others then
				dbms_application_info.set_action(null);
				raise;

	end split_string;

	function npg_source_hash (
		npg											in out		ninja_parse.ninja_package
	)
	return varchar2

	as

	  l_ret_var               varchar2(128);
		l_combined_source				clob := '';

	begin

	  dbms_application_info.set_action('ninja_source_hash');

		for i in 1..npg.npg_files.count() loop
			l_combined_source := l_combined_source || npg.npg_files(i).file_content;
		end loop;

		-- Once we are done collating the source, we can calculate the hash value.
		l_ret_var := rawtohex(dbms_crypto.hash(
			src				=>		utl_raw.cast_to_raw(l_combined_source)
			, typ			=>		dbms_crypto.hash_sh1
		));

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end npg_source_hash;

	procedure log_entry (
		package_id            	in        	varchar2
		, entry									in					varchar2
		, cli_generated_id			in					varchar2 default null
	)

	as

		pragma									autonomous_transaction;
		l_send_status						number;

	begin

	  dbms_application_info.set_action('log_entry');

		if cli_generated_id is not null then
			insert into ninja_install_log (ninja_id, entry_time, entry) values (cli_generated_id, systimestamp, entry);
		else
			insert into ninja_install_log (ninja_id, entry_time, entry) values (package_id, systimestamp, entry);
		end if;

		commit;

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end log_entry;

	function ninja_setting (
		setting_name_in					in					varchar2
	)
	return varchar2

	as

	  l_ret_var               ninja_settings.setting_value%type;
		l_check_exist						number := 0;

	begin

	  dbms_application_info.set_action('ninja_setting');

		select count(*)
		into l_check_exist
		from ninja_settings
		where setting_name = setting_name_in;

		if l_check_exist > 0 then
			select setting_value
			into l_ret_var
			from ninja_settings
			where setting_name = setting_name_in;
		else
			l_ret_var := null;
		end if;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end ninja_setting;

	function create_execute_object (
		n_id										in					varchar2
		, c_cont								in					varchar2
	)
	return varchar2

	as

	  l_ret_var               varchar2(100) := 'NPG' || substr(sys_guid(), 1, 24);

	begin

	  dbms_application_info.set_action('create_execute_object');

		insert into ninja_compile_temp (
			npg_id
			, compile_id
			, compile_source
			, compiled
		) values (
			n_id
			, l_ret_var
			, c_cont
			, 0
		);

		commit;

	  dbms_application_info.set_action(null);

	  return l_ret_var;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end create_execute_object;

	procedure remove_execute_object (
	  c_id             in        varchar2
	)

	as

	begin

	  dbms_application_info.set_action('remove_execute_object');

		delete from ninja_compile_temp where compile_id = c_id;
		commit;

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end remove_execute_object;

	procedure run_execute_object (
	  c_id             				in        	varchar2
		, n_id									in					varchar2
		, u_id									in					varchar2
		, eo_result							out					number
		, eo_message						out					varchar2
	)

	as

		l_job_name							varchar2(60) := u_id || '.' || c_id;
		l_message								varchar2(4000);
		l_result								integer;

	begin

	  dbms_application_info.set_action('run_execute_object');

		-- Express our interest in the return message from the execution object.
		dbms_alert.register(
			name				=>		c_id
		);
		ninja_npg_utils.log_entry(n_id, 'Registered for signal on: ' || c_id);

		-- Create the job in target schema for the execute object.
		dbms_scheduler.create_job(
			job_name						=>		l_job_name
			, job_type					=>		'PLSQL_BLOCK'
			, job_action				=>		'declare c_src clob; c_id varchar2(1024) := '''|| c_id || ''';
			                          begin
			                            c_src := ninja_npg.gs(c_id);
			                            execute immediate c_src;
			                            ninja_npg.sc(c_id, ''1'');
			                            exception
			                              when others then
			                                ninja_npg.sc(c_id, ''-1'');
			                          end;'
			, enabled						=>		true
		);
		ninja_npg_utils.log_entry(n_id, 'Executed target job for ' || c_id);

		-- Now we wait for the result of the job.
		-- Timeout defaults to 20 seconds.
		dbms_alert.waitone(
			name					=>		c_id
			, message			=>		l_message
			, status			=>		l_result
			, timeout			=>		to_number(ninja_npg_utils.ninja_setting('execute_object_timeout'))
		);

		-- Set the results of the signals.
		eo_result := l_result;
		eo_message := l_message;

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end run_execute_object;

	procedure clear_completed_execute_object (
	  c_id             				in        	varchar2
	)

	as

	begin

	  dbms_application_info.set_action('clear_completed_execute_object');

		dbms_alert.remove(
			name				=>			c_id
		);
		remove_execute_object(c_id);

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end clear_completed_execute_object;

begin

	dbms_application_info.set_client_info('ninja_npg_utils');
	dbms_session.set_identifier('ninja_npg_utils');

end ninja_npg_utils;
/
