@..\initspool main_col_group
/***************************************************************************************************
Name: main_col_group.sql               Author: Brendan Furey                       Date: 17-Mar-2019

Driver script component in the Oracle log_set_oracle module. This is a logging framework that 
supports the writing of messages to log tables, along with various optional data items that may be
specified as parameters or read at runtime via system calls.

The framework is designed to be as simple as possible to use in default mode, while allowing for a
high degree of configuration. A client program first constructs a log pointing to a configuration 
key, then puts lines to the log conditionally depending on the line minimum put level being at least
equal to the configuration put level. By creating new versions of the keyed configuration the amount
and type of information put can be varied without code changes to support production debugging and
analysis.

Multiple logs can be processed simultaneously within and across sessions without interference.

In order to maximise performance, puts may be  buffered, and only the log header uses an Oracle
sequence for its unique identifier, with lines being numbered sequentially in PL/SQL.

GitHub: https://github.com/BrenPatF/log_set_oracle

There is an example main program and package showing how to use the Log_Set package, and a unit test
program.
====================================================================================================
|  Main/Test .sql  |  Package       |  Notes                                                       |
|===================================================================================================
| *main_col_group* |  Col_Group     |  Example showing how to use the Log_Set package              |
----------------------------------------------------------------------------------------------------
|  r_tests         |  TT_Log_Set    |  Unit testing the Log_Set package                            |
|                  |  Utils_TT      |                                                              |
====================================================================================================


This file has the driver script for the example Col_Group package body (app schema). The package 
reads delimited lines from file, and counts values in a given column, with methods to return the
counts in various orderings. 

It is used here as a simple example of how to use the logging package.

***************************************************************************************************/
DECLARE
  l_log_id               PLS_INTEGER := Log_Set.Construct;
  l_len_lis              L1_num_arr := L1_num_arr(30, -5);
  l_res_arr              chr_int_arr;

BEGIN

  Col_Group.AIP_Load_File(p_file => 'fantasy_premier_league_player_stats.csv', p_delim => ',',
   p_colnum => 7);
  l_res_arr := Col_Group.AIP_List_Asis;
  Log_Set.Put_List(p_line_lis => Utils.Heading('As Is'));
  Log_Set.Put_List(p_line_lis => Utils.Col_Headers(L1_chr_arr('Team', 'Apps'), l_len_lis));
  FOR i IN 1..l_res_arr.COUNT LOOP
    Log_Set.Put_Line(p_line_text  => Utils.List_To_Line(
                        L1_chr_arr(l_res_arr(i).chr_field, l_res_arr(i).int_field), l_len_lis));
                        
    
  END LOOP;
--  Log_Set.Raise_Error(p_err_msg => 'Example custom error raising');
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
SELECT line_num lno, line_text text
  FROM log_lines
 WHERE log_id = (SELECT MAX(h.id) FROM log_headers h)
   AND line_type IS NULL
 ORDER BY line_num
/
PROMPT Errors
SELECT line_num lno, err_msg, error_backtrace
  FROM log_lines
 WHERE log_id = (SELECT MAX(h.id) FROM log_headers h)
   AND line_type = 'ERROR'
 ORDER BY line_num
/
@..\endspool