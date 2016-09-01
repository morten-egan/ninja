create or replace package ninja_npg_utils

as

	/** Utility package for all the ninja npg functions
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	-- Types and objects
	type tab_strings is table of varchar2(1000);

	/** Check if package already is installed in the schema
	* @author Morten Egan
	* @param package_name The package we are checking for
	* @return
	*/
	function check_install_status (
		package_name						in				varchar2
		, schema_name						in				varchar2 default sys_context('USERENV', 'SESSION_USER')
	)
	return boolean;

	/** Convert a blob to clob
	* @author Morten Egan
	* @param bin_blob The blob to conver to a clob
	* @return We return the blob input converted to a clob
	*/
	function blob_to_clob (
		bin_blob								in				blob
	)
	return clob;

	/** Table function to return a delimited string as individual rows
	* @author Morten Egan
	* @param string_to_split The string to split
	* @return Individual rows, each with an element of the splitted string.
	*/
	function split_string (
		string_to_split					in				varchar2
		, delimiter							in				varchar2 default ','
	)
	return tab_strings
	pipelined;

	/** Calculate the source hash for this package. Can be used to verify against official NPG repository.
	* @author Morten Egan
	* @param NPG package to calculate hash from source.
	* @return varchar2 The hash value of the source.
	*/
	function npg_source_hash (
		npg											in out		ninja_parse.ninja_package
	)
	return varchar2;

	/** Log an install entry in the log table.
	* @author Morten Egan
	* @param package_id The unique install id for the package installation/update/deletion.
	*/
	procedure log_entry (
	  package_id            	in        	varchar2
		, entry									in					varchar2
		, cli_generated_id			in					varchar2 default null
	);

	/** Check a ninja npg setting.
	* @author Morten Egan
	* @param setting_name_in The name of the setting to get value from.
	* @return varchar2 The value of the setting to check.
	*/
	function ninja_setting (
		setting_name_in					in					varchar2
	)
	return varchar2;

	/** Function to create a temporary execution object.
	* @author Morten Egan
	* @param n_id The ninja id of the NPG.
	* @param c_cont The executable content for the object.
	* @return varchar2 Returns the new ID of the compile object.
	*/
	function create_execute_object (
		n_id										in					varchar2
		, c_cont								in					clob
	)
	return varchar2;

	/** Remove a temporary execution object.
	* @author Morten Egan
	* @param c_id The id of the object to remove.
	*/
	procedure remove_execute_object (
	  c_id             				in        	varchar2
	);

	/** Run a temporary execute object, with status and message output.
	* @author Morten Egan
	* @param c_id The ID of the execute object to run.
	* @param n_id The ninja id of the NPG.
	* @param eo_result The result of the execution. 1 if timeout, 0 if success.
	* @param eo_message The message from the execution object.
	*/
	procedure run_execute_object (
	  c_id             				in        	varchar2
		, n_id									in					varchar2
		, u_id									in					varchar2
		, eo_result							out					number
		, eo_message						out					varchar2
	);

	/** Clear all information from an already run execute object.
	* @author Morten Egan
	* @param c_id The execute object id to clear.
	*/
	procedure clear_completed_execute_object (
	  c_id             				in        	varchar2
	);

end ninja_npg_utils;
/
