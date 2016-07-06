create or replace package ninja_download

as

	/** This package handles the download functionality of ninja packages
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version		varchar2(50) := '0.0.1';

	/** This function will download a specific package based on input parameters
	* @author Morten Egan
	* @param package_name The name of the package
	* @return The npg zip binary file
	*/
	function get_npg (
		package_name						in				varchar2
		, package_version				in				varchar2 default null
		, repository						in				varchar2
	)
	return blob;

end ninja_download;
/
