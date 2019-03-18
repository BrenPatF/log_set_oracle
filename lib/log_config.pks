CREATE OR REPLACE PACKAGE Log_Config AS
/***************************************************************************************************
Name: log_config.pks                   Author: Brendan Furey                       Date: 17-Mar-2019

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
| *Log_Config* |  DML API package for log configs table                                            |
----------------------------------------------------------------------------------------------------
|  Utils       |  General utility functions                                                        |
====================================================================================================

This file has the DML API package spec for log configs table. Fields are described in the package
body.

***************************************************************************************************/

/***************************************************************************************************

Set_Default_Config: Set one of the configs to be the default, unsetting any other active default

***************************************************************************************************/

FUNCTION Get_Default_Config RETURN VARCHAR2;
FUNCTION Get_Config(
            p_config_key                   VARCHAR2)
            RETURN                         log_configs%ROWTYPE;
PROCEDURE Ins_Config(
            p_config_key                   VARCHAR2,
            p_config_type                  VARCHAR2 := NULL,
            p_default_yn                   VARCHAR2 := NULL,
            p_singleton_yn                 VARCHAR2 := NULL,
            p_description                  VARCHAR2 := NULL,
            p_put_lev                      PLS_INTEGER := 10,
            p_put_lev_stack                PLS_INTEGER := NULL,
            p_put_lev_cpu                  PLS_INTEGER := NULL,
            p_ctx_inp_lis                  ctx_inp_arr := NULL,
            p_put_lev_module               PLS_INTEGER := NULL,
            p_put_lev_action               PLS_INTEGER := NULL,
            p_put_lev_client_info          PLS_INTEGER := NULL,
            p_app_info_only_yn             VARCHAR2 := NULL,
            p_buff_len                     PLS_INTEGER := 1,
            p_extend_len                   PLS_INTEGER := 1);
PROCEDURE Del_Config(
            p_config_key                   VARCHAR2);

END Log_Config;
/
SHOW ERROR
