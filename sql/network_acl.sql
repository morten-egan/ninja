begin
	dbms_network_acl_admin.create_acl (
		acl => 'ninja_acl.xml',
		description => 'ACL definition for plsql.ninja access',
		principal => upper('&1'),
		is_grant => true,
		privilege => 'connect',
		start_date => systimestamp,
		end_date => null
	);

	commit;

	dbms_network_acl_admin.add_privilege (
		acl => 'ninja_acl.xml',
		principal => upper('&1'),
		is_grant => true,
		privilege => 'resolve'
	);

	commit;

	dbms_network_acl_admin.assign_acl (
		acl => 'ninja_acl.xml',
		host => 'plsql.ninja',
		lower_port => null,
		upper_port => null
	);

	commit;

end;
/
