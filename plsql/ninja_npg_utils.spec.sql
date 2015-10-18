create or replace package ninja_npg_utils

as

	/** Utility package for all the ninja npg functions
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** Check if package already is installed in the schema
	* @author Morten Egan
	* @param package_name The package we are checking for
	*/
	function check_install_status (
		package_name						in				varchar2
		, schema_name						in				varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
	)
	return boolean;

end ninja_npg_utils;
/