create or replace package ninja_parse

as

	type ninja_meta is record (
		npg_version_major			number
		, npg_version_minor		number
		, npg_version_fix			number
		, npg_format					varchar2(150)
	);

	type pg_meta is record (
		pg_name								varchar2(1024)
		, pg_author						varchar2(1024)
		, pg_version_major		number
		, pg_version_minor		number
		, pg_version_fix			number
		, pg_build_date				date
		, pg_hash							varchar2(128)
		, pg_description			varchar2(4000)
		, pg_url_doc					varchar2(1024)
		, pg_key							varchar2(4000)
		, pg_order_file				number
		, pg_install_status		number
		, pg_readme_file			number
	);

	type pg_require is record (
		require_type					varchar2(150)
		, require_value				varchar2(4000)
		, require_met					number
	);
	type pg_requirements is table of pg_require index by pls_integer;

	type pg_file is record (
		file_name							varchar2(256)
		, file_type						varchar2(256)
		, file_content				clob
		, compile_success			number
		, compile_error				number
	);
	type pg_files is table of pg_file index by pls_integer;

	type pg_runtime is record (
		install_to						varchar2(128)
		, cli_generated_id		varchar2(128)
		, requirement_failed	number
	);

	type ninja_package is record (
		ninja_id							varchar2(1024)
		, npg_meta						ninja_meta
		, package_meta				pg_meta
		, requirements				pg_requirements
		, npg_files						pg_files
		, npg_runtime					pg_runtime
	);

	/** Will take the binary npg file, and extract to an npg package
	* @author Morten Egan
	* @param npg_binary The binary npg file that we are installing
	*/
	procedure unpack_binary_npg (
		npg_binary						in					blob
		, npg									in out			ninja_package
	);

	/** This procedure will validate the unzipped ninja package. It will check all requirements.
	* @author Morten Egan
	* @param npg The full ninja package
	*/
	procedure validate_package (
		npg										in out			ninja_package
	);

	procedure parse_spec_file (
		spec_file							in					clob
		, npg									in out			ninja_package
		, require_parms				in					boolean default true
	);

	/** Create an npg.spec file from a ninja_package record.
	* @author Morten Egan
	* @return clob The npg.spec file contents.
	*/
	function create_spec_file_from_record (
		npg										in					ninja_package
	)
	return clob;

end ninja_parse;
/
