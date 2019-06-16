@..\initspool main_col_group
/***************************************************************************************************
Name: main_col_group.sql               Author: Brendan Furey                       Date: 17-Mar-2019

Driver script component in the Oracle log_set_oracle module. This is a logging framework that 
supports the writing of messages to log tables, along with various optional data items that may be
specified as parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

There is an example main program and package showing how to use the Log_Set package, and a unit test
program. Unit testing is optional and depends on the module trapit_oracle_tester.
====================================================================================================
|  Main/Test .sql  |  Package     |  Notes                                                         |
|===================================================================================================
| *main_col_group* |  Col_Group   |  Example showing how to use the Log_Set package. Col_Group is  |
|                  |              |  a simple file-reading and group-counting package installed    |
|                  |              |  via the oracle_plsql_utils module                             |
----------------------------------------------------------------------------------------------------
|  r_tests         |  TT_Log_Set  |  Unit testing the Log_Set package. Trapit is installed as a    |
|                  |  Trapit      |  separate module                                               |
====================================================================================================

This file has the driver script for the example code calling the Log_Set methods.

***************************************************************************************************/
DECLARE
  l_log_id               PLS_INTEGER := Log_Set.Construct;
  l_res_arr              chr_int_arr;

BEGIN

  Col_Group.Load_File(p_file   => 'fantasy_premier_league_player_stats.csv', 
                          p_delim  => ',',
                          p_colnum => 7);
  l_res_arr := Col_Group.List_Asis;
  Log_Set.Put_List(p_line_lis => Utils.Heading('As Is'));
  Log_Set.Put_List(p_line_lis => Utils.Col_Headers(p_value_lis => chr_int_arr(chr_int_rec('Team', 30),
                                                                              chr_int_rec('Apps', -5)
  )));
  FOR i IN 1..l_res_arr.COUNT LOOP
    Log_Set.Put_Line(p_line_text => Utils.List_To_Line(
                     p_value_lis => chr_int_arr(chr_int_rec(l_res_arr(i).chr_value, 30), 
                                                chr_int_rec(l_res_arr(i).int_value, -5)
    )));
  END LOOP;
--  Log_Set.Raise_Error(p_log_id => l_log_id, p_err_msg => 'Example custom error raising');
  Log_Set.Close_Log;
  RAISE NO_DATA_FOUND; -- Example of unexpected error handling in others

EXCEPTION
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error;
    RAISE;

END;
/
SET HEAD OFF
COLUMN lno FORMAT 990
COLUMN text FORMAT A100
COLUMN err_msg FORMAT A30
COLUMN error_backtrace FORMAT A100
SET LINES 150
PROMPT Normal lines
PROMPT Lines
SELECT hdr.id, lin.line_num lno, To_Char(lin.creation_tmstp, 'hh24:mi:ss.ff3') "At", line_text text
  FROM log_lines lin
  JOIN log_headers hdr ON hdr.id = lin.log_id
 WHERE hdr.session_id = SYS_CONTEXT('USERENV', 'SESSIONID')
   AND lin.line_type IS NULL
 ORDER BY lin.session_line_num
/
PROMPT Errors
SELECT line_num lno, err_msg, error_backtrace
  FROM log_lines lin
  JOIN log_headers hdr ON hdr.id = lin.log_id
 WHERE hdr.session_id = SYS_CONTEXT('USERENV', 'SESSIONID')
   AND lin.line_type = 'ERROR'
 ORDER BY lin.session_line_num
/
EXEC Log_Set.Delete_Log(p_session_id => SYS_CONTEXT('USERENV', 'SESSIONID'));
ROLLBACK;

@..\endspool