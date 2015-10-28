create or replace package ninja_validate

as

	/** This package is used to validate specific aspects of the npg file
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** Check if an object name already exist in this scope
	* @author Morten Egan
	* @param object_name The name of the object to check if it exists
	*/
	function obj_already_exist (
		object_name						in				varchar2
	)
	return boolean;

	/** Check if the required database version is met
	* @author Morten Egan
	* @param db_version_met Is the required database version met?
	*/
	function db_version_check (
		db_version_met						in				varchar2
	)
	return boolean;

end ninja_validate;
/