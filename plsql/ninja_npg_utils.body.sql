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

		select count(nip.package_name)
		into l_count
		from ninja_installed_packages nip
		where nip.package_name = package_name
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

begin

	dbms_application_info.set_client_info('ninja_npg_utils');
	dbms_session.set_identifier('ninja_npg_utils');

end ninja_npg_utils;
/