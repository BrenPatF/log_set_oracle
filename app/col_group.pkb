CREATE OR REPLACE PACKAGE BODY Col_Group AS
/***************************************************************************************************
Name: col_group.pkb                    Author: Brendan Furey                       Date: 29-Jan-2019

Package body component in the Oracle timer_set_oracle module. This module facilitates code timing
for instrumentation and other purposes, with very small footprint in both code and resource usage.

See 'Code Timing and Object Orientation and Zombies' for the original idea implemented in Oracle 
   PL/SQL, Perl and Java
   http://www.scribd.com/doc/43588788/Code-Timing-and-Object-Orientation-and-Zombies
   Brendan Furey, November 2010

There is an example main program and package showing how to use the Timer_Set package, and a unit 
test program.
====================================================================================================
|  Main/Test       |  Package       |  Notes                                                       |
|===================================================================================================
|  main_col_group  | *Col_Group*    |  Simple file-reading and group-counting module, with code    |
|                  |                |  timing. Example showing how to use the Timer_Set package    |
----------------------------------------------------------------------------------------------------
|  r_tests         |  TT_Timer_Set  |  Unit testing the Timer_Set package                          |
|                  |  Utils_TT      |                                                              |
====================================================================================================

This file has the example Col_Group package body (app schema). The package reads delimited lines 
from file, and counts values in a given column, with methods to return the counts in various 
orderings. It is used here as a simple example of how to use the code timing package.

***************************************************************************************************/

g_chr_int_lis           chr_int_arr;
/***************************************************************************************************

AIP_Load_File: Reads file via external table, and stores counts of string values in input column into
               package array

***************************************************************************************************/
PROCEDURE AIP_Load_File (p_file     VARCHAR2,       -- file name, including path
                         p_delim    VARCHAR2,       -- field delimiter
                         p_colnum   PLS_INTEGER) IS -- column number of values to be counted
BEGIN

  EXECUTE IMMEDIATE 'ALTER TABLE lines_et LOCATION (''' || p_file || ''')';

  WITH key_column_values AS (
    SELECT Substr (line, Instr(p_delim||line||p_delim, p_delim, 1, p_colnum),
                         Instr(p_delim||line||p_delim, p_delim, 1, p_colnum+1) - Instr(p_delim||line||p_delim, p_delim, 1, p_colnum) - Length(p_delim)) keyval
      FROM lines_et
  )
  SELECT chr_int_rec (keyval, COUNT(*))
    BULK COLLECT INTO g_chr_int_lis
    FROM key_column_values
   GROUP BY keyval;

END AIP_Load_File;

/***************************************************************************************************

AIP_List_Asis: Returns the key-value array of string, count as is, i.e. unsorted

***************************************************************************************************/
FUNCTION AIP_List_Asis RETURN chr_int_arr IS -- key-value array unsorted
BEGIN

  RETURN g_chr_int_lis;

END AIP_List_Asis;

/***************************************************************************************************

AIP_Sort_By_Key: Returns the key-value array of (string, count) sorted by key

***************************************************************************************************/
FUNCTION AIP_Sort_By_Key RETURN chr_int_arr IS -- key-value array sorted by key
  l_chr_int_lis chr_int_arr;
BEGIN

  SELECT chr_int_rec (t.chr_field, t.int_field)
    BULK COLLECT INTO l_chr_int_lis
    FROM TABLE (g_chr_int_lis) t
   ORDER BY t.chr_field;

  RETURN l_chr_int_lis;

END AIP_Sort_By_Key;

/***************************************************************************************************

AIP_Sort_By_Value: Returns the key-value array of (string, count) sorted by value

***************************************************************************************************/
FUNCTION AIP_Sort_By_Value RETURN chr_int_arr IS -- key-value array sorted by value
  l_chr_int_lis chr_int_arr;
BEGIN

  SELECT chr_int_rec (t.chr_field, t.int_field)
    BULK COLLECT INTO l_chr_int_lis
    FROM TABLE (g_chr_int_lis) t
   ORDER BY t.int_field, t.chr_field;

  RETURN l_chr_int_lis;

END AIP_Sort_By_Value;

END Col_Group;
/
SHO ERR