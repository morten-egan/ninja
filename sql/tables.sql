create table ninja_pgm_meta (
	ninja_pgm_major				number
	, ninja_pgm_minor			number
	, ninja_pgm_fix				number
);

create table ninja_repositories (
	repository_source					varchar2(4000)				constraint ninja_repos_pk primary key
	, repository_added				date									constraint ninja_repos_added_nn not null
	, repository_last_update	date									constraint ninja_repos_updated_nn not null
	, repository_hash					varchar2(100)					constraint ninja_repos_hash_nn not null
);

/*
create table ninja_repos_contents_cache (
	repository_source					varchar2(4000)				constraint ninja_repos_source_ref references ninja_repositories(repository_source)
	, package_name						varchar2(100)					constraint ninja_repos_pkg_name_nn not null
	, package_added						date									constraint ninja_repos_pkg_added_nn not null
	, package_updated					date									constraint ninja_repos_pkg_updated_nn not null
	, package_hash						varchar2(100)					constraint ninja_repos_pkg_hash_nn not null
	, package_version					varchar2(20)					constraint ninja_repos_pkg_version_nn not null
	, package_description			varchar2(4000)
);
*/

create table ninja_installed_packages (
	npg_name									varchar2(100)					constraint ninja_install_pkg_name_nn not null
	, installed_schema				varchar2(100)					constraint ninja_install_pkg_schema_nn not null
	, installed_hash					varchar2(100)					constraint ninja_install_pkg_hash_nn not null
	, pg_version							varchar2(20)					constraint ninja_install_pkg_version_nn not null
	, install_date						date									constraint ninja_install_pkg_date_nn not null
	, pg_author								varchar2(200)					constraint ninja_install_pkg_author_nn not null
	, upgrade_date						date
);

create table ninja_package_temp (
	temp_id										varchar2(250)					constraint ninja_tmp_id_nn not null
	, temp_type								varchar2(40)					constraint ninja_tmp_type_chk check (temp_type in ('NPG', 'SOURCE'))
	, temp_b_content					blob
	, temp_c_content					clob
);
