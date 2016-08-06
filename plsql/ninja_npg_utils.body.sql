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
		, schema_name						in				varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
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

	function cli_log (
		cli_generated_id				in				varchar2
	)
	return cli_tab
	pipelined

	as

	  l_ret_var               cli_rec;
		l_generated							varchar2(30);
		l_entry									varchar2(1024);
		l_pipe_status						number;

	begin

	  dbms_application_info.set_action('cli_log');

		loop
			l_pipe_status := dbms_pipe.receive_message(cli_generated_id);
			if l_pipe_status = 0 then
				dbms_pipe.unpack_message(l_generated);
				dbms_pipe.unpack_message(l_entry);
				l_ret_var.cli_mesg_date := sysdate;
				l_ret_var.cli_generated_id := l_generated;
				l_ret_var.mesg := l_entry;
				pipe row(l_ret_var);
			else
				exit;
			end if;
		end loop;

	  dbms_application_info.set_action(null);

	  return;

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end cli_log;

	procedure log_cli_pipe_create (
	  log_name             	in        varchar2
	)

	as

		l_create_result				number;

	begin

	  dbms_application_info.set_action('log_cli_pipe_create');

		l_create_result := dbms_pipe.create_pipe(
			pipename		=>		log_name
			, private		=>		false
		);

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end log_cli_pipe_create;

	procedure log_cli_pipe_stop (
	  log_name             		in        varchar2
	)

	as

		l_create_result				number;

	begin

	  dbms_application_info.set_action('log_cli_pipe_stop');

		l_create_result := dbms_pipe.remove_pipe(
			pipename		=>		log_name
		);

	  dbms_application_info.set_action(null);

	  exception
	    when others then
	      dbms_application_info.set_action(null);
	      raise;

	end log_cli_pipe_stop;

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
			insert into ninja_install_log (ninja_id, entry_time, entry) values (cli_generated_id, sysdate, entry);
		else
			insert into ninja_install_log (ninja_id, entry_time, entry) values (package_id, sysdate, entry);
		end if;

		/* if cli_generated_id is not null then
			dbms_pipe.pack_message(cli_generated_id);
			dbms_pipe.pack_message(entry);
			l_send_status := dbms_pipe.send_message(cli_generated_id);
		end if; */

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

begin

	dbms_application_info.set_client_info('ninja_npg_utils');
	dbms_session.set_identifier('ninja_npg_utils');

end ninja_npg_utils;
/
