create or replace package ninja_parse

as

	type ninja_meta is record (
		npg_version_major		number
		, npg_version_minor		number
		, npg_version_fix		number
	);

	type pg_meta is record (
		pg_name					varchar2(1024)
		, pg_version_major		number
		, pg_version_minor		number
		, pg_version_fix		number
		, pg_build_date			date
		, pg_description		varchar2(4000)
		, pg_url_doc			varchar2(1024)
		, pg_key				varchar2(4000)
	);

	type pg_require is record (
		require_type			varchar2(150)
		, require_value			varchar2(4000)
	);
	type pg_requirements is table of pg_require index by pls_integer;

	type pg_file is record (
		file_name				varchar2(256)
		, file_type				varchar2(256)
		, file_content			clob
	);
	type pg_files is table of pg_file index by pls_integer;

	type ninja_package is record (
		ninja_id				varchar2(1024)
		, npg_meta				ninja_meta
		, package_meta			pg_meta
		, requirements			pg_requirements
		, npg_files				pg_files
	);

	/** Will take the binary npg file, and extract to an npg package
	* @author Morten Egan
	* @param npg_binary The binary npg file that we are installing
	*/
	procedure unpack_binary_npg (
		npg_binary						in				blob
		, npg							in out			ninja_package
	);

	/** This procedure will validate the unzipped ninja package. It will check all requirements.
	* @author Morten Egan
	* @param npg The full ninja package
	*/
	procedure validate_package (
		npg						in out				ninja_package
	);

end ninja_parse;
/