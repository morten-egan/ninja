create or replace package ninja_npg

as

	/** This is the main package for the ninja package manager
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** Install package using the ninja package manager.
	* @author Morten Egan
	* @param package_name The name of the package to install.
	* @param package_version The version of the package to install.
	* @param repository The repository source to use.
	*/
	procedure install_p (
		package_name						in				varchar2
		, package_version					in				varchar2 default null
		, repository						in				varchar2 default null
	);

	/** Update package using the nínja package manager.
	* @author Morten Egan
	* @param package_name The name of the package to update.
	* @param package_version The version of the package to update to.
	* @param repository The repository source to use.
	*/
	procedure update_p (
		package_name						in				varchar2
	);

end ninja_npg;
/