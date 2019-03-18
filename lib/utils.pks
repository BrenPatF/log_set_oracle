CREATE OR REPLACE PACKAGE Utils AUTHID CURRENT_USER AS
/***************************************************************************************************
Name: utils.pks                        Author: Brendan Furey                       Date: 17-Mar-2019

Package spec component in the Oracle timer_set_oracle module. This is a logging framework that 
supports the writing of messages to log tables, along with various optional data items that may be
specified as parameters or read at runtime via system calls.

The framework is designed to be as simple as possible to use in default mode, while allowing for a
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

This file has the general utility functions package spec.

***************************************************************************************************/

LIST_END_MARKER         CONSTANT VARCHAR2(30) := 'LIST_END_MARKER';
c_session_id_if_TT               VARCHAR2(30);
g_list_delimiter                 VARCHAR2(30) := '|';
CUSTOM_ERRNO            CONSTANT PLS_INTEGER := -20000;

FUNCTION Get_Seconds(p_interval INTERVAL DAY TO SECOND) RETURN NUMBER;
PROCEDURE Raise_Error(p_message VARCHAR2);
FUNCTION List_To_Line (p_val_lis    L1_chr_arr, -- token list
                       p_len_lis    L1_num_arr) -- length list
                       RETURN       VARCHAR2;
FUNCTION Col_Headers(p_val_lis L1_chr_arr, p_len_lis L1_num_arr) RETURN L1_chr_arr;
FUNCTION Heading(p_head VARCHAR2) RETURN L1_chr_arr;
FUNCTION List_Delim (p_field_lis  L1_chr_arr, 
                     p_delim      VARCHAR2 := g_list_delimiter) 
                     RETURN       VARCHAR2;
FUNCTION List_Delim(p_field1  VARCHAR2,
                    p_field2  VARCHAR2 := LIST_END_MARKER, p_field3  VARCHAR2 := LIST_END_MARKER,
                    p_field4  VARCHAR2 := LIST_END_MARKER, p_field5  VARCHAR2 := LIST_END_MARKER,
                    p_field6  VARCHAR2 := LIST_END_MARKER, p_field7  VARCHAR2 := LIST_END_MARKER,
                    p_field8  VARCHAR2 := LIST_END_MARKER, p_field9  VARCHAR2 := LIST_END_MARKER,
                    p_field10 VARCHAR2 := LIST_END_MARKER, p_field11 VARCHAR2 := LIST_END_MARKER,
                    p_field12 VARCHAR2 := LIST_END_MARKER, p_field13 VARCHAR2 := LIST_END_MARKER,
                    p_field14 VARCHAR2 := LIST_END_MARKER, p_field15 VARCHAR2 := LIST_END_MARKER,
                    p_field16 VARCHAR2 := LIST_END_MARKER, p_field17 VARCHAR2 := LIST_END_MARKER)
                    RETURN    VARCHAR2;
FUNCTION Csv_To_Lis(p_csv VARCHAR2) RETURN L1_chr_arr;

END Utils;
/
SHOW ERROR