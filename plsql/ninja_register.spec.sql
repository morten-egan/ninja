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

end ninja_register;
/