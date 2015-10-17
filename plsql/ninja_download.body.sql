create or replace package body ninja_download

as

	function binary_from_url_to_temp (
		url						in				varchar2
	)
	return varchar2
	
	as

		l_http_request			utl_http.req;
		l_http_response			utl_http.resp;
		l_blob					blob;
		l_raw					raw(32767);
		l_temp_id				ninja_package_temp.temp_id%type;
	
	begin
	
		dbms_application_info.set_action('binary_from_url');

		dbms_lob.createtemporary(l_blob, false);

		-- make a http request and get the response.
		l_http_request  := utl_http.begin_request(url);
		l_http_response := utl_http.get_response(l_http_request);
		
		-- copy the response into the blob.
		begin
			loop
				utl_http.read_raw(l_http_response, l_raw, 32766);
				dbms_lob.writeappend (l_blob, utl_raw.length(l_raw), l_raw);
			end loop;
		
			exception
				when utl_http.end_of_body then
					utl_http.end_response(l_http_response);
		end;

		-- Get the temp id for this file
		l_temp_id := sys_guid();
		
		-- insert the data into the table.
		insert into ninja_package_temp (
			temp_id
			, temp_type
			, temp_b_content
		) values (
			l_temp_id
			, 'NPG'
			, l_blob
		);

		commit;
		
		-- relase the resources associated with the temporary lob.
  		dbms_lob.freetemporary(l_blob);

  		return l_temp_id;
	
		dbms_application_info.set_action(null);
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end binary_from_url_to_temp;

	function get_npg (
		package_name						in				varchar2
		, package_version					in				varchar2 default null
		, repository						in				varchar2
	)
	return varchar2
	
	as
	
		l_ret_val					ninja_package_temp.temp_id%type;
		l_url						varchar2(4000);
		l_url_checksum				varchar2(4000);
		l_returned_checksum			varchar2(100);
	
	begin
	
		dbms_application_info.set_action('get_npg');

		-- First check if we have set the version and repository.
		-- If not, we use the latest version and use the default repository
		if repository is null then
			l_url := 'http://npg.plsql.ninja/bin/npg?m=';
		else
			l_url := repository;
		end if;

		l_url_checksum := l_url || 'c' || '&n=' || utl_url.escape(package_name);
		l_url := l_url || 'd' || '&n=' || utl_url.escape(package_name);

		if package_version is not null then
			l_url := l_url || '&v=' || utl_url.escape(package_version);
		end if;

		-- Now we query the repository for the package
		-- We get the checksum as return if it exists.
		l_returned_checksum := utl_http.request(l_url_checksum);

		if l_returned_checksum is not null then
			-- Finally we download the binary npg to the temp area
			-- Maybe do this instead: l_blob := HTTPURITYPE.createuri(p_url).getblob();
			l_ret_val := binary_from_url_to_temp(l_url);
		end if;
	
		dbms_application_info.set_action(null);
	
		return l_ret_val;
	
		exception
			when others then
				dbms_application_info.set_action(null);
				raise;
	
	end get_npg;

begin

	dbms_application_info.set_client_info('ninja_download');
	dbms_session.set_identifier('ninja_download');

end ninja_download;
/