create or replace package ninja_compile

as

	/** Compilation of individual npg files and compilation of a package
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** Function to compile/run an npg source file by ID
	* @author Morten Egan
	* @param npg The ninja package record
	* @param file_id The index id of the file to install
	* @return boolean True if installation is successfull, False if not
	*/
	function compile_file_id (
		npg							in out				ninja_parse.ninja_package
		, file_id				in						number
	)
	return boolean;

	/** Function to compile/run an npg source file by name
	* @author Morten Egan
	* @param npg The ninja package record
	* @param file_name The name of the file to install
	* @return boolean True if installation is successfull, False if not
	*/
	function compile_file_name (
		npg							in out				ninja_parse.ninja_package
		, file_name			in						varchar2
	)
	return boolean;

	/** Compile a full npg package
	* @author Morten Egan
	* @param npg The npg record
	*/
	procedure compile_npg (
		npg										in out				ninja_parse.ninja_package
		, cli_generated_id		in						varchar2 default null
	);

	/** Rollback a full npg package.
	* @author Morten Egan
	* @param npg The NPG package to rollback.
	*/
	procedure rollback_npg (
	  npg             in out       	ninja_parse.ninja_package
	);

end ninja_compile;
/
