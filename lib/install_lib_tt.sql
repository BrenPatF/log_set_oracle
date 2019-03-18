@..\InitSpool install_lib_tt
/***************************************************************************************************
Name: install_lib_tt.sql               Author: Brendan Furey                       Date: 17-Mar-2019

Installation script for the unit test objects in the lib schema in the Oracle timer_set_oracle 
module. It requires a minimum Oracle database version of 12.2.

This module facilitates code timing for instrumentation and other purposes, with very small 
footprint in both code and resource usage.

GitHub: https://github.com/BrenPatF/timer_set_oracle

See 'Code Timing and Object Orientation and Zombies' for the original idea implemented in Oracle 
   PL/SQL, Perl and Java
   http://www.scribd.com/doc/43588788/Code-Timing-and-Object-Orientation-and-Zombies
   Brendan Furey, November 2010

There are install scripts for sys, lib and app schemas. However the base code alone can be installed
via install_lib.sql in an existing schema without executing the other scripts.
====================================================================================================
|  Script              |  Notes                                                                    |
|===================================================================================================
|  install_sys.sql     |  sys script creates lib and app schemas; input_dir directory; grants      |
----------------------------------------------------------------------------------------------------
|  install_lib.sql     |  Creates common objects, including Log_Set package, in lib schema         |
----------------------------------------------------------------------------------------------------
| *install_lib_tt.sql* |  Creates unit test objects that require a minimum Oracle database version |
|                      |  of 12.2 in lib schema                                                    |
----------------------------------------------------------------------------------------------------
|  install_app.sql     |  Creates objects for the Col_Group example in the app schema              |
====================================================================================================

This file has the install script for the unit test objects in the lib schema. It requires a
minimum Oracle database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

Objects created, with NO synonyms or grants - only accessible within lib schema:

    Types         Description
    ============  ==================================================================================
    L2_chr_arr    Generic array of L1_chr_arr
    L3_chr_arr    Generic array of L2_chr_arr
    L4_chr_arr    Generic array of L3_chr_arr

    Tables        Description
    ============  ==================================================================================
    tt_units      Stores unit test metadata, including input and output JSON CLOBs

    Packages      Description
    ============  ==================================================================================
    Utils_TT      Unit test utility functions
    TT_Log_Set    Unit test package for Log_Set. Uses Oracle v12.2 JSON features

    Metadata      Description
    ============  ==================================================================================
    tt_units      Record for package, procedure ('TT_LOG_SET', 'tt_Main'). The input JSON file
                  must first be placed in the OS folder pointed to by INPUT_DIR directory

***************************************************************************************************/
DROP TABLE tt_units
/
PROMPT Common type creation
PROMPT ====================

DROP TYPE L4_chr_arr
/
DROP TYPE L3_chr_arr
/
PROMPT Create type L2_chr_arr
CREATE OR REPLACE TYPE L2_chr_arr IS VARRAY(32767) OF L1_chr_arr
/
PROMPT Create type L3_chr_arr
CREATE OR REPLACE TYPE L3_chr_arr IS VARRAY(32767) OF L2_chr_arr
/
PROMPT Create type L4_chr_arr
CREATE OR REPLACE TYPE L4_chr_arr IS VARRAY(32767) OF L3_chr_arr
/
PROMPT Table creation
PROMPT ==============

PROMPT Create table tt_units
PROMPT tt_units
CREATE TABLE tt_units (
    package_nm                   VARCHAR2(30) NOT NULL,
    procedure_nm                 VARCHAR2(30) NOT NULL,
    description                  VARCHAR2(500),
    active_yn                    VARCHAR2(1),
    input_data                   CLOB,
    output_data                  CLOB,
    CONSTRAINT uni_pk            PRIMARY KEY (package_nm, procedure_nm),
    CONSTRAINT uni_js1           CHECK (input_data IS JSON),
    CONSTRAINT uni_js2           CHECK (output_data IS JSON))
/
COMMENT ON TABLE tt_units IS 'Unit test metadata'
/
PROMPT Packages creation
PROMPT =================

PROMPT Create package Log_Set
@timer_set.pks
@timer_set.pkb
PROMPT Create package Utils_TT
@utils_tt.pks
@utils_tt.pkb
PROMPT Create package tt_log_set
@tt_log_set.pks
@tt_log_set.pkb

PROMPT Read in json files
DECLARE
BEGIN

  Utils_TT.Add_Ttu ('TT_LOG_SET', 'tt_Main', 'Y', 'tt_log_set.json');

END;
/
@..\EndSpool