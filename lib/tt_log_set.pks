CREATE OR REPLACE PACKAGE TT_Log_Set AS
/***************************************************************************************************
Name: tt_log_set.pks                   Author: Brendan Furey                       Date: 17-Mar-2019

Package spec component in the Oracle log_set_oracle module. 

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

There is an example main program and package showing how to use the Log_Set package, and a unit test
program. Unit testing is optional and depends on the module trapit_oracle_tester
====================================================================================================
|  Main/Test .sql  |  Package     |  Notes                                                         |
|==================================================================================================|
|  main_col_group  |  Col_Group   |  Example showing how to use the Log_Set package. Col_Group is  |
|                  |              |  a simple file-reading and group-counting package              |
|                  |              |  installed via the oracle_plsql_utils module                   |
|------------------|--------------|----------------------------------------------------------------|
|  r_tests         | *TT_Log_Set* |  Unit testing the Log_Set package. Trapit_Run is installed     |
|                  |  Trapit_Run  |  aa part of a separate module, trapit_oracle_tester            |
====================================================================================================

This file has the TT_Log_Set unit test package spec. Note that the test package is called by the
unit test utility package Trapit_Run, which reads the unit test details from a table, tt_units,
populated by the install scripts.

The test program follows 'The Math Function Unit Testing design pattern':

    GitHub: https://github.com/BrenPatF/trapit_nodejs_tester

Note that the unit test program generates an output file, tt_log_set.purely_wrap_log_set_out.json,
that is processed by a separate nodejs program, npm package trapit (see README for further details).

The output JSON file contains arrays of expected and actual records by group and scenario, in the
format expected by the nodejs program. This program produces listings of the results in HTML and/or
text format, and a sample set of listings is included in the folder test_data\test_output

***************************************************************************************************/

FUNCTION Purely_Wrap_Log_Set(
              p_inp_3lis                     L3_chr_arr)
              RETURN                         L2_chr_arr;

END TT_Log_Set;
/
