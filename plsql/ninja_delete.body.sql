create or replace package body ninja_delete

as

  procedure npg_objects_drop (
    npg_name_in             in        varchar2
    , npg_schema            in        varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
  )

  as

    cursor get_objects is
      select
        obj_type
        , obj_name
      from
        ninja_npg_objects
      where
        npg_name = npg_name_in
      and
        installed_schema = npg_schema;

    l_obj_sql_drop          varchar2(256);
    l_obj_name_cleaned      varchar2(256);
    l_object_not_found			exception;
    pragma									exception_init(l_object_not_found, -4043);

  begin

    dbms_application_info.set_action('npg_objects_drop');

    for objs in get_objects loop
      if objs.obj_type != 'package body' then
        if instr(objs.obj_name, '.') > 0 then
          l_obj_name_cleaned := substr(objs.obj_name, 1, instr(objs.obj_name, '.') - 1);
        else
          l_obj_name_cleaned := objs.obj_name;
        end if;
        l_obj_sql_drop := 'drop ' || objs.obj_type || ' ' || l_obj_name_cleaned;
        execute immediate l_obj_sql_drop;
      end if;
      -- Remove the object from object_registry.
      delete from ninja_npg_objects
      where obj_type = objs.obj_type
      and obj_name = objs.obj_name
      and npg_name = npg_name_in
      and upper(installed_schema) = upper(npg_schema);
    end loop;

    dbms_application_info.set_action(null);

    exception
      when l_object_not_found then
				dbms_application_info.set_action(null);
				null;
      when others then
        dbms_application_info.set_action(null);
        raise;

  end npg_objects_drop;

  procedure npg_registry_remove (
    npg_name_in             in        varchar2
    , npg_schema            in        varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
  )

  as

  begin

    dbms_application_info.set_action('npg_registry_remove');

    delete from ninja_installed_packages
    where npg_name = npg_name_in
    and upper(installed_schema) = upper(npg_schema);

    dbms_application_info.set_action(null);

    exception
      when others then
        dbms_application_info.set_action(null);
        raise;

  end npg_registry_remove;

  procedure delete_package (
    package_name_in             in        varchar2
    , do_force                  in        varchar2 default 'no'
    , pkg_installed_schema      in        varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA')
  )

  as

  begin

    dbms_application_info.set_action('delete_package');

    -- First we drop all objects registered with the package.
    npg_objects_drop(package_name_in, pkg_installed_schema);

    -- After that we need to remove the registry entry.
    npg_registry_remove(package_name_in, pkg_installed_schema);

    dbms_application_info.set_action(null);

    exception
      when others then
        dbms_application_info.set_action(null);
        raise;

  end delete_package;

begin

  dbms_application_info.set_client_info('ninja_delete');
  dbms_session.set_identifier('ninja_delete');

end ninja_delete;
/
