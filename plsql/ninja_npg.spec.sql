create or replace package ninja_npg

as

	/** This is the main package for the ninja package manager
	* @author Morten Egan
	* @version 0.0.1
	* @project NINJA
	*/
	p_version			varchar2(50) := '0.0.1';

	-- Version split out
	version_major		number := 0;
	version_minor		number := 0;
	version_fix			number := 1;

	type cli_rec is record (
		cli_mesg_date						date
		, cli_generated_id			varchar2(1024)
		, mesg									varchar2(1024)
	);
	type cli_tab is table of cli_rec;

	/** Streaming npg action log function for CLI interaction.
	* @author Morten Egan
	* @return cli_tab Stream of output rows from the CLI action.
	*/
	function cli_log (
		cli_generated_id				in				varchar2
	)
	return cli_tab
	pipelined;

	/** Get source for NPG package installation.
	* @author Morten Egan
	* @param sid The source id to get.
	* @return clob The source to install.
	*/
	function gs (
		sid											in				varchar2
	)
	return clob;

	/** Signal about source compilation back to installation session.
	* @author Morten Egan
	* @param sid The source id to signal about
	*/
	procedure sc (
	  sid             				in        varchar2
		, sm										in				varchar2
	);

	/** Install package using the ninja package manager.
	* @author Morten Egan
	* @param package_name The name of the package to install.
	* @param package_version The version of the package to install.
	* @param repository The repository source to use.
	*/
	procedure install_p (
		package_name						in				varchar2
		, package_version				in				varchar2 default null
		, repository						in				varchar2 default null
		, cli_generated_id			in				varchar2 default null
	);

	/** Update package using the nínja package manager.
	* @author Morten Egan
	* @param package_name The name of the package to update.
	* @param package_version The version of the package to update to.
	* @param repository The repository source to use.
	*/
	procedure update_p (
		package_name						in				varchar2
		, package_version					in				varchar2 default null
		, repository						in				varchar2 default null
	);

	/** Delete package using the ninja package manager.
	* @author Morten Egan
	* @param package_name The name of the package to delete.
	* @param force_delete Yes to force delete even though there are dependencies. Defaults to No.
	*/
	procedure delete_p (
		package_name							in				varchar2
		, force_delete						in				varchar2 default 'no'
		, cli_generated_id				in				varchar2 default null
	);

end ninja_npg;
/
