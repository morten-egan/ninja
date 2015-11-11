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

	/** Check if a required sys privilege is available
	* @author Morten Egan
	* @param sys_priv The sys privilege to check for
	* @return boolean Returns true if sys privilege is granted, False if not
	*/
	function sys_priv_check (
		sys_priv						in				varchar2
	)
	return boolean;

	/** Check if an object is valid. This is used during installation of packages
	* @author Morten Egan
	* @param obj_name The name of the object
	* @param obj_type The type of the object
	* @return boolean True if object is valid, false if not
	*/
	function object_is_valid (
		obj_name						in				varchar2
		, obj_type						in				varchar2
	)
	return boolean;

end ninja_validate;
/