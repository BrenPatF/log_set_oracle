CREATE OR REPLACE PACKAGE TT_Log_Set AS
/***************************************************************************************************
Name: tt_log_set.pks                   Author: Brendan Furey                       Date: 17-Mar-2019

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
|  main_col_group  |  Col_Group     |  Example showing how to use the Log_Set package              |
----------------------------------------------------------------------------------------------------
|  r_tests         | *TT_Log_Set*   |  Unit testing the Log_Set package                            |
|                  |  Utils_TT      |                                                              |
====================================================================================================

This file has the unit test TT_Log_Set package spec (lib schema). Note that the test package is
called by the unit test utility package Utils_TT, which reads the unit test details from a table,
tt_units, populated by the install scripts.

The test program follows 'The Math Function Unit Testing design pattern':

GitHub: https://github.com/BrenPatF/trapit_nodejs_tester

Note that the unit test program generates an output tt_log_set.tt_main_out.json file that is 
processed by a separate nodejs program, npm package trapit. This can be installed via npm (npm and
nodejs required):

$ npm install trapit

The output json file contains arrays of expected and actual records by group and scenario, in the
format expected by the Javascript program. The Javascript program produces listings of the results
in html and/or text format, and a sample set of listings is included in the folder test.

See also the app schema main_col_group script which gives a simple example use-case for the
Log_Set package.

***************************************************************************************************/

PROCEDURE Test_API;

END TT_Log_Set;
/
