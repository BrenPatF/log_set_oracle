@..\initspool install_lib
/***************************************************************************************************
Name: install_lib.sql                  Author: Brendan Furey                       Date: 17-Mar-2019

Installation script for lib schema in the Oracle log_set_oracle module, excluding the unit test 
objects that require a minimum Oracle database version of 12.2. 

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
| *install_lib.sql*    |  Creates common objects, including Timer_Set package, in lib schema       |
----------------------------------------------------------------------------------------------------
|  install_lib_tt.sql  |  Creates unit test objects that require a minimum Oracle database version |
|                      |  of 12.2 in lib schema                                                    |
----------------------------------------------------------------------------------------------------
|  install_app.sql     |  Creates objects for the Col_Group example in the app schema              |
====================================================================================================

This file has the install script for the lib schema, excluding the unit test objects that require a
minimum Oracle database version of 12.2. This script should work in prior versions of Oracle,
including v10 and v11 (although it has not been tested on them).

Objects created, with public synonyms and grants to public:

    Types            Description
    ==========       ==================================================================================
    L1_chr_arr       Generic array of strings
    L1_num_arr       Generic array of NUMBER
    ctx_inp_obj      Context input object (name, put level, scope)
    ctx_inp_arr      (Varray) array of context input object
    ctx_out_obj      Context input object (name, value)
    ctx_out_arr      (Varray) array of context output object
   
    Sequences        Description
    =============    ===============================================================================
    log_configs_s    Log configurations sequence

    Tables           Description
    =============    ===============================================================================
    log_configs      Log configurations
    log_headers      Log headers
    log_lines        Log lines

    Packages         Description
    =============    ===============================================================================
    Utils            General utility functions
    Log_Set          Logging package

    Seed Data        Description
    =============    ===============================================================================
    Log Configs      4 records inserted

***************************************************************************************************/

PROMPT Common types creation
PROMPT =====================
DROP TABLE log_lines
/
DROP TABLE log_headers
/
DROP TABLE log_configs
/

PROMPT Create type L1_chr_arr
CREATE OR REPLACE TYPE L1_chr_arr IS VARRAY(32767) OF VARCHAR2(4000)
/
CREATE OR REPLACE PUBLIC SYNONYM L1_chr_arr FOR L1_chr_arr
/
GRANT EXECUTE ON L1_chr_arr TO PUBLIC
/
PROMPT Create type L1_num_arr
CREATE OR REPLACE TYPE L1_num_arr IS VARRAY(32767) OF NUMBER
/
CREATE OR REPLACE PUBLIC SYNONYM L1_num_arr FOR L1_num_arr
/
GRANT EXECUTE ON L1_num_arr TO PUBLIC
/
DROP TYPE ctx_inp_arr
/
DROP TYPE ctx_out_arr
/
CREATE OR REPLACE TYPE ctx_inp_obj IS OBJECT (
        ctx_nm                      VARCHAR2(30),
        put_lev                     INTEGER,                   -- null for print if line printed
        head_line_fg                VARCHAR2(1)
)
/
CREATE OR REPLACE TYPE ctx_inp_arr IS VARRAY(32767) OF ctx_inp_obj
/
CREATE OR REPLACE TYPE ctx_out_obj IS OBJECT (
        ctx_nm                      VARCHAR2(30),
        ctx_vl                      VARCHAR2(4000)
)
/
CREATE OR REPLACE TYPE ctx_out_arr IS VARRAY(32767) OF ctx_out_obj
/
PROMPT Common tables creation
PROMPT ======================

PROMPT Create table log_configs
CREATE TABLE log_configs(
        id                          INTEGER,
        config_key                  VARCHAR2(30),
        vsn_no                      INTEGER,
        active_yn                   VARCHAR2(1) CONSTRAINT active_ck CHECK (Nvl(active_yn, 'N') IN ('Y', 'N')),
        default_yn                  VARCHAR2(1) CONSTRAINT default_ck CHECK (Nvl(default_yn, 'N') IN ('Y', 'N')),
        singleton_yn                VARCHAR2(1) CONSTRAINT singleton_ck CHECK (Nvl(singleton_yn, 'N') IN ('Y', 'N')),
        description                 VARCHAR2(4000),
        config_type                 VARCHAR2(100),
        creation_tmstp              TIMESTAMP,
        put_lev                     INTEGER,
        put_lev_stack               INTEGER,
        put_lev_cpu                 INTEGER,
        ctx_inp_lis                 ctx_inp_arr,
        put_lev_module              INTEGER,
        put_lev_action              INTEGER,
        put_lev_client_info         INTEGER,
        app_info_only_yn            VARCHAR2(1) CONSTRAINT app_info_only_ck CHECK (Nvl(app_info_only_yn, 'N') IN ('Y', 'N')),
        buff_len                    INTEGER,
        extend_len                  INTEGER,
        CONSTRAINT lcf_pk           PRIMARY KEY(id)
)
/
CREATE UNIQUE INDEX lcf_uk ON log_configs(config_key, vsn_no)
/
CREATE OR REPLACE PUBLIC SYNONYM log_configs FOR log_configs
/
GRANT ALL ON log_configs TO PUBLIC
/
DROP SEQUENCE log_configs_s
/
CREATE SEQUENCE log_configs_s START WITH 1
/
PROMPT Create table log_headers
CREATE TABLE log_headers(
        id                          INTEGER,
        config_id                   INTEGER,
        session_id                  VARCHAR2(30),
        session_user                VARCHAR2(30),
        put_lev_min                 INTEGER,
        description                 VARCHAR2(4000),
        ctx_out_lis                 ctx_out_arr,
        creation_tmstp              TIMESTAMP,
        closure_tmstp               TIMESTAMP,
        CONSTRAINT lhd_pk           PRIMARY KEY(id),
        CONSTRAINT lhd_lcf_fk       FOREIGN KEY(config_id) REFERENCES log_configs(id)
)
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers FOR log_headers
/
GRANT ALL ON log_headers TO PUBLIC
/
DROP SEQUENCE log_headers_s
/
CREATE SEQUENCE log_headers_s START WITH 1
/
CREATE OR REPLACE PUBLIC SYNONYM log_headers_s FOR log_headers_s
/
GRANT SELECT ON log_headers_s TO PUBLIC
/
PROMPT Create table log_lines
CREATE TABLE log_lines(
        log_id                      INTEGER NOT NULL,
        line_num                    INTEGER NOT NULL,
        session_line_num            INTEGER NOT NULL,
        line_type                   VARCHAR2(30),
        plsql_unit                  VARCHAR2(30),
        plsql_line                  INTEGER,
        group_text                  VARCHAR2(4000),
        line_text                   VARCHAR2(4000),
        action                      VARCHAR2(4000),
        call_stack                  VARCHAR2(2000),
        error_backtrace             VARCHAR2(4000),
        ctx_out_lis                 ctx_out_arr,
        put_lev_min                 INTEGER,
        err_num                     INTEGER,
        err_msg                     VARCHAR2(4000),
        creation_tmstp              TIMESTAMP,
        creation_cpu_cs             INTEGER,
        CONSTRAINT lin_pk           PRIMARY KEY(log_id, line_num),
        CONSTRAINT lin_hdr_fk       FOREIGN KEY(log_id) REFERENCES log_headers (id)
)
/
CREATE OR REPLACE PUBLIC SYNONYM log_lines FOR log_lines
/
GRANT ALL ON log_lines TO PUBLIC
/

PROMPT Packages creation
PROMPT =================

PROMPT Create package Utils
@utils.pks
@utils.pkb
CREATE OR REPLACE PUBLIC SYNONYM utils FOR utils
/
GRANT EXECUTE ON utils TO PUBLIC
/
PROMPT Create package Log_Config
@log_config.pks
@log_config.pkb
CREATE OR REPLACE PUBLIC SYNONYM Log_Config FOR Log_Config
/
GRANT EXECUTE ON Log_Config TO PUBLIC
/
PROMPT Create package Log_Set
@log_set.pks
@log_set.pkb
CREATE OR REPLACE PUBLIC SYNONYM Log_Set FOR Log_Set
/
GRANT EXECUTE ON Log_Set TO PUBLIC
/
BEGIN
  Log_Config.Ins_Config(
        p_config_key            => 'SINGLETON',
        p_description           => 'Singleton, unbuffered',
        p_singleton_yn          => 'Y',
        p_default_yn            => 'Y');
  Log_Config.Ins_Config(
        p_config_key            => 'SINGLEBUF',
        p_description           => 'Singleton, buffered',
        p_singleton_yn          => 'Y',
        p_buff_len              => 100,
        p_extend_len            => 100);
  Log_Config.Ins_Config(
        p_config_key            => 'MULTILOG',
        p_description           => 'Multi-log, unbuffered');
  Log_Config.Ins_Config(
        p_config_key            => 'MULTIBUF',
        p_description           => 'Multi-log, unbuffered',
        p_buff_len              => 100,
        p_extend_len            => 100);
END;
/
COMMIT
/
@..\endspool