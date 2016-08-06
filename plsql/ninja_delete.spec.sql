create or replace package ninja_delete

as

  /** NPG delete interface.
  * @author Morten Egan
  * @version '0.0.1'
  * @project NINJA
  */
  npg_version         varchar2(250) := '0.0.1';

  /** Delete a package from the installed NPG packages.
  * @author Morten Egan
  * @param package_name_in The name of the package to delete.
  * @param do_force If set to yes, it will delete even with dependents. If no, will only delete if no dependents.
  * @param pkg_installed_schema The schema the package is installed in, default to curent schema.
  */
  procedure delete_package (
    package_name_in             in        varchar2
    , do_force                  in        varchar2 default 'no'
    , pkg_installed_schema      in        varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
    , cli_generated_id				  in				varchar2 default null
  );

end ninja_delete;
/
