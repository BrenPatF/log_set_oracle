@..\InitSpool install_app
/***************************************************************************************************
Name: install_app.sql                  Author: Brendan Furey                       Date: 17-Mar-2019

Installation script for app schema in the Oracle log_set_oracle module. 

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

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

There are install scripts for sys, lib and app schemas. However the base code alone can be installed
via install_lib.sql in an existing schema without executing the other scripts.
====================================================================================================
|  Script              |  Notes                                                                    |
|===================================================================================================
|  install_sys.sql     |  sys script creates lib and app schemas; input_dir directory; grants      |
----------------------------------------------------------------------------------------------------
|  install_lib.sql     |  Creates common objects, including Timer_Set package, in lib schema       |
----------------------------------------------------------------------------------------------------
|  install_lib_tt.sql  |  Creates unit test objects that require a minimum Oracle database version |
|                      |  of 12.2 in lib schema                                                    |
----------------------------------------------------------------------------------------------------
| *install_app.sql*    |  Creates objects for the Col_Group example in the app schema              |
====================================================================================================

This file has the install script for the app schema.

Objects created, with NO synonyms or grants - only accessible within app schema:

    Types          Description
    ============== =================================================================================
    chr_int_rec    Simple (string, integer) tuple type
    chr_int_arr    Array of chr_int_rec

    External Table
    ============== =================================================================================
    lines_et       Used to read in csv records from lines.csv placed in INPUT_DIR folder

    Packages
    ============== =================================================================================
    Col_Group      Package called by main_col_group as a simple example of how to use the logging 
                   package

***************************************************************************************************/

PROMPT External table creation
PROMPT =======================
PROMPT Create lines_et
CREATE TABLE lines_et (
        line            VARCHAR2(400)
)
ORGANIZATION EXTERNAL ( 
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY input_dir
    ACCESS PARAMETERS (
            RECORDS DELIMITED BY NEWLINE
            FIELDS (
                line POSITION (1:4000) CHAR(4000)
            )
    )
    LOCATION ('lines.csv')
)
    REJECT LIMIT UNLIMITED
/
PROMPT Types creation
PROMPT ==============
CREATE OR REPLACE TYPE chr_int_rec AS 
    OBJECT (chr_field           VARCHAR2(4000), 
            int_field           INTEGER)
/
CREATE OR REPLACE TYPE chr_int_arr AS TABLE OF chr_int_rec
/
PROMPT Packages creation
PROMPT =================

PROMPT Create package Col_Group
@Col_Group.pks
@Col_Group.pkb
@..\EndSpool