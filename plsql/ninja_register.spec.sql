create or replace package ninja_register

as

	/** Registration of installed, updated or deleted packages
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** Register a package as installed
	* @author Morten Egan
	* @param npg The package that was installed successfully
	*/
	procedure register_install (
		npg						in out				ninja_parse.ninja_package
	);

	/** Register an installed object. This is for update/delete purposes.
	* @author Morten Egan
	* @param obj_name_in The name of the object to register.
	* @param obj_type_in The object type
	* @param npg_name The name of the package that it was installed under.
	* @param npg_pkg_version The version of the package that was installed.
	* @param npg_installed_schema The schema this was installed under.
	*/
	procedure register_installed_obj (
	  obj_name_in             in        varchar2
		, obj_type_in						in				varchar2
		, npg_name_in						in				varchar2
		, npg_pkg_version				in				varchar2
		, npg_installed_schema	in				varchar2 default sys_context('USERENV', 'SESSION_USER')
	);

end ninja_register;
/
