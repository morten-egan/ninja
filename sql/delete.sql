set termout off
WHENEVER SQLERROR EXIT SQL.SQLCODE;

REM Install package requested.
begin
  ninja_npg.delete_p(
    package_name => '&1'
  );
end;
/

exit;
