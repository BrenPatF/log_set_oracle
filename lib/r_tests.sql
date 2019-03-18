@..\InitSpool r_tests
/***************************************************************************************************
Name: tt_timer_set.pkb                 Author: Brendan Furey                       Date: 29-Jan-2019

Driver script component in the Oracle timer_set_oracle module. This module facilitates code timing
for instrumentation and other purposes, with very small footprint in both code and resource usage.

GitHub: https://github.com/BrenPatF/timer_set_oracle

See 'Code Timing and Object Orientation and Zombies' for the original idea implemented in Oracle 
   PL/SQL, Perl and Java
   http://www.scribd.com/doc/43588788/Code-Timing-and-Object-Orientation-and-Zombies
   Brendan Furey, November 2010

There is an example main program and package showing how to use the Timer_Set package, and a unit 
test program.
====================================================================================================
|  Main/Test .sql  |  Package       |  Notes                                                       |
|===================================================================================================
|  main_col_group  |  Col_Group     |  Example showing how to use the Timer_Set package            |
----------------------------------------------------------------------------------------------------
| *r_tests*        |  TT_Timer_Set  |  Unit testing the Timer_Set package                          |
====================================================================================================

This file has the driver script for the unit test TT_Timer_Set package (lib schema). Note that the
test package is called by the unit test utility package Utils_TT, which reads the unit test details 
from a table, tt_units, populated by the install scripts. 

The result of running this script is that a JSON file is created in the folder pointed to by the
INPUT_DIR Oracle directory on the database server. This file contains both expected and actual
results for the scenarios defined in an input JSON object that is read from a table. The output file
can be processed to return a set of HTML files showing the success and failure results using a
nodejs package avialable on npm.

The JSON processing requires Oracle database 12.2 or higher. If this is not available, or it is not
desired to install the npm processor package, then the unit testing code need not be installed. The 
results obtained by the author can be viewed in the files included in the root folder.

See also the app schema main_col_group script which gives a simple example use-case for the
Timer_Set package.

***************************************************************************************************/
DECLARE
BEGIN

  Utils_TT.Run_Suite;

END;
/
@..\EndSpool