@..\initspool install_log_set_tt
/***************************************************************************************************
Name: install_log_set_tt.sql           Author: Brendan Furey                       Date: 17-Mar-2019

Installation script for the unit test components in the log_set_oracle module. It requires a
minimum Oracle database version of 12.2.

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

	  GitHub: https://github.com/BrenPatF/log_set_oracle

Pre-requisite: Installation of the oracle_plsql_utils module:

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are two install scripts, of which the second is optional: 
- install_log_set.sql:    base code; requires base install of oracle_plsql_utils
- install_log_set_tt.sql: unit test code; requires unit test install section of oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed.
====================================================================================================
|  Script                  |  Notes                                                                |
|===================================================================================================
|  install_log_set.sql     |  Creates base components, including Log_Set package, in lib schema    |
----------------------------------------------------------------------------------------------------
| *install_log_set_tt.sql* |  Creates unit test components that require a minimum Oracle database  |
|                          |  version of 12.2 in lib schema                                        |
====================================================================================================

This file has the install script for the unit test components in the lib schema. It requires a
minimum Oracle database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

Components created, with NO synonyms or grants - only accessible within lib schema:

    Packages      Description
    ============  ==================================================================================
    TT_Log_Set    Unit test package for Log_Set. Uses Oracle v12.2 JSON features

    Metadata      Description
    ============  ==================================================================================
    tt_units      Record for package, procedure ('TT_LOG_SET', 'Test_API'). The input JSON file
                  must first be placed in the OS folder pointed to by INPUT_DIR directory

***************************************************************************************************/
PROMPT Packages creation
PROMPT =================

PROMPT Create package tt_log_set
@tt_log_set.pks
@tt_log_set.pkb

PROMPT Add the tt_units record, reading in JSON file from INPUT_DIR
BEGIN

  Trapit.Add_Ttu ('TT_LOG_SET', 'Test_API', 'Y', 'tt_log_set.test_api_inp.json');

END;
/
@..\endspool