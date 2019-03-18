CREATE OR REPLACE PACKAGE Utils_TT AS
/***************************************************************************************************
Name: Utils_TT.pks                     Author: Brendan Furey                       Date: 29-Jan-2019

Package spec component in the Oracle timer_set_oracle module. This module facilitates code timing
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
|  r_tests         |  TT_Timer_Set  |  Unit testing the Timer_Set package                          |
|                  | *Utils_TT*     |                                                              |
====================================================================================================

This file has the unit test utility, Utils_TT, package spec (lib schema). Note that the test package
is called by the unit test utility package Utils_TT, which reads the unit test details from a table,
tt_units, populated by the install scripts.

The test program follows 'The Math Function Unit Testing design pattern':

GitHub: https://github.com/BrenPatF/trapit_nodejs_tester

Note that the unit test program generates an output timerset_out.json file that is processed by a
separate nodejs program, npm package trapit. This can be installed via npm (npm and nodejs
required):

$ npm install trapit

The output json file contains arrays of expected and actual records by group and scenario, in the
format expected by the Javascript program. The Javascript program produces listings of the results
in html and/or text format, and a sample set of listings is included in the folder test.

See also the app schema main_col_group script which gives a simple example use-case for the
Timer_Set package.

***************************************************************************************************/
c_date_fmt                  CONSTANT VARCHAR2(11) := 'DD-MON-YYYY';
c_call_timer                CONSTANT VARCHAR2(30) := 'Caller';
c_setup_timer               CONSTANT VARCHAR2(30) := 'Setup';

FUNCTION Get_Inputs (		p_package_nm                VARCHAR2,
                            p_procedure_nm              VARCHAR2,
                            p_timer_set                 PLS_INTEGER)
                            RETURN                      L4_chr_arr;
PROCEDURE Set_Outputs (     p_package_nm                VARCHAR2,
                            p_procedure_nm              VARCHAR2,
                            p_act_3lis                  L3_chr_arr,
                            p_timer_set                 PLS_INTEGER);
FUNCTION Init (             p_proc_name                 VARCHAR2)
                            RETURN                      PLS_INTEGER;
PROCEDURE Run_Suite;
FUNCTION Get_View (         p_view_name                 VARCHAR2,
                            p_sel_field_lis             L1_chr_arr,
                            p_where                     VARCHAR2 DEFAULT NULL,
                            p_timer_set                 PLS_INTEGER) 
                            RETURN                      L1_chr_arr;

FUNCTION Cursor_to_Array (  x_csr                IN OUT SYS_REFCURSOR, 
                            p_filter                    VARCHAR2 DEFAULT NULL) 
                            RETURN                      L1_chr_arr;
PROCEDURE Add_Ttu(p_package_nm      VARCHAR2,
                  p_procedure_nm    VARCHAR2, 
                  p_active_yn       VARCHAR2, 
                  p_input_file      VARCHAR2);
PROCEDURE Sleep (p_ela_seconds      NUMBER, 
                 p_fraction_CPU     NUMBER := 0.5);

END Utils_TT;
/
SHOW ERROR