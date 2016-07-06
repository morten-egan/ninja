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
	*/
	function check_install_status (
		package_name						in				varchar2
		, schema_name						in				varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
	)
	return boolean;

	/** Convert a blob to clob
	* @author Morten Egan
	* @param bin_blob The blob to conver to a clob
	*/
	function blob_to_clob (
		bin_blob								in				blob
	)
	return clob;

	/** Table function to return a delimited string as individual rows
	* @author Morten Egan
	* @param string_to_split The string to split
	*/
	function split_string (
		string_to_split					in				varchar2
		, delimiter							in				varchar2 default ','
	)
	return tab_strings
	pipelined;

end ninja_npg_utils;
/
