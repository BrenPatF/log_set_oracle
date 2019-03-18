CREATE OR REPLACE PACKAGE Col_Group AS
/***************************************************************************************************
Name: col_group.pks                    Author: Brendan Furey                       Date: 17-Mar-2019

Package spec component in the Oracle log_set_oracle module. This is a logging framework that 
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
|  main_col_group  | *Col_Group*    |  Example showing how to use the Log_Set package              |
----------------------------------------------------------------------------------------------------
|  r_tests         |  TT_Log_Set    |  Unit testing the Log_Set package                            |
|                  |  Utils_TT      |                                                              |
====================================================================================================

This file has the example Col_Group package spec (app schema). The package reads delimited lines 
from file, and counts values in a given column, with methods to return the counts in various 
orderings. It is used here as a simple example of how to use the logging package.

***************************************************************************************************/

PROCEDURE AIP_Load_File (p_file VARCHAR2, p_delim VARCHAR2, p_colnum PLS_INTEGER);
FUNCTION AIP_List_Asis RETURN chr_int_arr;
FUNCTION AIP_Sort_By_Key RETURN chr_int_arr;
FUNCTION AIP_Sort_By_Value RETURN chr_int_arr;

END Col_Group;
/
SHO ERR



