CREATE OR REPLACE PACKAGE BODY Utils AS
/***************************************************************************************************
Name: utils.pkb                        Author: Brendan Furey                       Date: 17-Mar-2019

Package body component in the Oracle timer_set_oracle module. This is a logging framework that 
supports the writing of messages to log tables, along with various optional data items that may be
specified as parameters or read at runtime via system calls.

The framework is designed to be as simple as possible to use in := mode, while allowing for a
high degree of configuration. A client program first constructs a log pointing to a configuration 
key, then puts lines to the log conditionally depending on the line minimum put level being at least
equal to the configuration put level. By creating new versions of the keyed configuration the amount
and type of information put can be varied without code changes to support production debugging and
analysis.

Multiple logs can be processed simultaneously within and across sessions without interference.

In order to maximise performance, puts may be buffered, and only the log header uses an Oracle
sequence for its unique identifier, with lines being numbered sequentially in PL/SQL.

GitHub: https://github.com/BrenPatF/log_set_oracle

As well as the entry point Log_Set package there is a DML API package for the log configs table, and
a helper package, Utils, of utility functions
====================================================================================================
|  Package     |  Notes                                                                            |
|===================================================================================================
|  Log_Set     |  Logging package                                                                  |
----------------------------------------------------------------------------------------------------
|  Log_Config  |  DML API package for log configs table                                            |
----------------------------------------------------------------------------------------------------
| *Utils*      |  General utility functions                                                        |
====================================================================================================

This file has the general utility functions package body.

***************************************************************************************************/
LINES                         CONSTANT VARCHAR2(1000) := '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
EQUALS                        CONSTANT VARCHAR2(1000) := '=======================================================================================================================================================================================================';
INPUT_DIR                     CONSTANT VARCHAR2(30) := 'INPUT_DIR';
FLD_DELIM                     CONSTANT VARCHAR2(30) := '  ';

/***************************************************************************************************

Get_Seconds: Simple function to get the seconds as a number from an interval

***************************************************************************************************/
FUNCTION Get_Seconds(p_interval INTERVAL DAY TO SECOND) -- time intervale
                        RETURN NUMBER IS                 -- time in seconds
BEGIN

  RETURN EXTRACT(SECOND FROM p_interval) + 60 * EXTRACT (MINUTE FROM p_interval) + 3600 * EXTRACT (HOUR FROM p_interval);

END Get_Seconds;

/***************************************************************************************************

Raise_Error: Centralise RAISE_APPLICATION_ERROR, using just one error number

***************************************************************************************************/
PROCEDURE Raise_Error(p_message VARCHAR2) IS
BEGIN

  RAISE_APPLICATION_ERROR(CUSTOM_ERRNO, p_message);

END Raise_Error;
/***************************************************************************************************

Heading: Return a 2-element list of strings as a heading with double underlining

***************************************************************************************************/
FUNCTION Heading(p_head       VARCHAR2) -- heading string
                 RETURN       L1_chr_arr IS

  l_under       VARCHAR2(500) := Substr (EQUALS, 1, Length(p_head));
  l_ret_lis     L1_chr_arr := L1_chr_arr();

BEGIN

  l_ret_lis.EXTEND(2);
  l_ret_lis(1) := p_head;
  l_ret_lis(2) := l_under;
  RETURN l_ret_lis;

END Heading;

/***************************************************************************************************

List_To_Line: Return a list of strings as one line, saving for reprinting later if desired,
                 separating fields by a 2-space delimiter; second list is numbers for lengths, with
                 -ve/+ve sign denoting right/left-justify

***************************************************************************************************/
FUNCTION List_To_Line(p_val_lis   L1_chr_arr, -- values list
                      p_len_lis   L1_num_arr) -- lengths list, with minus sigm meaning right-justify
                      RETURN      VARCHAR2 IS -- line
  l_line        VARCHAR2(32767);
  l_fld         VARCHAR2(32767);
  l_val         VARCHAR2(32767);
BEGIN

  FOR i IN 1..p_val_lis.COUNT LOOP
    l_val := Nvl(p_val_lis(i), ' ');
    IF p_len_lis(i) < 0 THEN
      l_fld := LPad(l_val, -p_len_lis(i));
    ELSE
      l_fld := RPad(l_val, p_len_lis(i));
    END IF;
    IF i = 1 THEN
      l_line := l_fld;
    ELSE
      l_line := l_line || FLD_DELIM || l_fld;
    END IF;

  END LOOP;
  RETURN l_line;

END List_To_Line;

/***************************************************************************************************

Col_Headers: Return a set of column headers, input as lists of values and length/justification's

***************************************************************************************************/
FUNCTION Col_Headers(p_val_lis    L1_chr_arr, -- values list
                     p_len_lis    L1_num_arr) -- lengths list, with minus sigm meaning right-justify
                     RETURN       L1_chr_arr IS
  l_line_lis    L1_chr_arr := L1_chr_arr();
  l_ret_lis     L1_chr_arr := L1_chr_arr();
BEGIN
  l_ret_lis.EXTEND(2);
  l_ret_lis(1) := List_To_Line(p_val_lis, p_len_lis);

  l_line_lis.EXTEND (p_val_lis.COUNT);
  FOR i IN 1..p_val_lis.COUNT LOOP

    l_line_lis(i) := LINES;

  END LOOP;
  l_ret_lis(2) := List_To_Line(l_line_lis, p_len_lis);
  RETURN l_ret_lis;

END Col_Headers;

PROCEDURE Delete_File (p_file_name VARCHAR2) IS -- OS file name
BEGIN

  UTL_File.FRemove (INPUT_DIR, p_file_name);

EXCEPTION
  WHEN UTL_File.invalid_operation THEN
    NULL;--Write_Log (p_file_name || ' was not present to delete!');

END Delete_File;

/***************************************************************************************************

Write_File: Open an OS file and write an input list of lines to it, then close it (used in ut)

***************************************************************************************************/
PROCEDURE Write_File (p_file_name       VARCHAR2, -- file name
                      p_lines           L1_chr_arr) IS -- list of lines to write
  l_file_ptr         		UTL_FILE.File_Type;
BEGIN

  l_file_ptr := UTL_File.FOpen (INPUT_DIR, p_file_name, 'W', 32767);
  IF p_lines IS NOT NULL THEN

    FOR i IN 1..p_lines.COUNT LOOP

      UTL_File.Put_Line (l_file_ptr, p_lines(i));

    END LOOP;

  END IF;
  UTL_File.FClose (l_file_ptr);

END Write_File;

/***************************************************************************************************

List_Delim: Return a delimited string for an input set of from 1 to 15 strings

***************************************************************************************************/
FUNCTION List_Delim(
        p_field1 VARCHAR2,        -- input string, first is required, others passed as needed
        p_field2 VARCHAR2 := LIST_END_MARKER, p_field3 VARCHAR2 := LIST_END_MARKER,
        p_field4 VARCHAR2 := LIST_END_MARKER, p_field5 VARCHAR2 := LIST_END_MARKER,
        p_field6 VARCHAR2 := LIST_END_MARKER, p_field7 VARCHAR2 := LIST_END_MARKER,
        p_field8 VARCHAR2 := LIST_END_MARKER, p_field9 VARCHAR2 := LIST_END_MARKER,
        p_field10 VARCHAR2 := LIST_END_MARKER, p_field11 VARCHAR2 := LIST_END_MARKER,
        p_field12 VARCHAR2 := LIST_END_MARKER, p_field13 VARCHAR2 := LIST_END_MARKER,
        p_field14 VARCHAR2 := LIST_END_MARKER, p_field15 VARCHAR2 := LIST_END_MARKER,
        p_field16 VARCHAR2 := LIST_END_MARKER, p_field17 VARCHAR2 := LIST_END_MARKER)
        RETURN VARCHAR2 IS        -- delimited string

  l_list   L1_chr_arr := L1_chr_arr (p_field2, p_field3, p_field4, p_field5, p_field6, p_field7,
              p_field8, p_field9, p_field10, p_field11, p_field12, p_field13, p_field14, p_field15,
              p_field16, p_field17);
  l_str    VARCHAR2(32767) := p_field1;

BEGIN

  FOR i IN 1..l_list.COUNT LOOP

    IF l_list(i) = LIST_END_MARKER THEN
      EXIT;
    END IF;
    l_str := l_str || g_list_delimiter || l_list(i);

  END LOOP;
  RETURN l_str;

END List_Delim;

/***************************************************************************************************

List_Delim: Return a delimited string for an input list of strings

***************************************************************************************************/
FUNCTION List_Delim (p_field_lis        L1_chr_arr,                        -- list of strings
                     p_delim            VARCHAR2 := g_list_delimiter) -- delimiter
                     RETURN VARCHAR2 IS                                    -- delimited string

  l_str         VARCHAR2(32767) := p_field_lis(1);

BEGIN

  FOR i IN 2..p_field_lis.COUNT LOOP

    l_str := l_str || p_delim || p_field_lis(i);

  END LOOP;
  RETURN l_str;

END List_Delim;
/***************************************************************************************************

Csv_To_Lis: Returns a list of tokens from a delimited string

***************************************************************************************************/
FUNCTION Csv_To_Lis(p_csv VARCHAR2)         -- delimited string
                    RETURN    L1_chr_arr IS -- list of tokens
  l_start_pos   PLS_INTEGER := 1;
  l_end_pos     PLS_INTEGER;
  l_arr_index   PLS_INTEGER := 1;
  l_arr         L1_chr_arr := L1_chr_arr();
  l_row         VARCHAR2(32767) := p_csv || g_list_delimiter;
BEGIN

  WHILE l_start_pos <= Length (l_row) LOOP

    l_end_pos := Instr (l_row, g_list_delimiter, 1, l_arr_index) - 1;
    IF l_end_pos < 0 THEN
      l_end_pos := Length (l_row);
    END IF;
    l_arr.EXTEND;
    l_arr (l_arr.COUNT) := Substr (l_row, l_start_pos, l_end_pos - l_start_pos + 1);
    l_start_pos := l_end_pos + 2;
    l_arr_index := l_arr_index + 1;
  END LOOP;

  RETURN l_arr;

END Csv_To_Lis;

END Utils;
/
SHOW ERROR
