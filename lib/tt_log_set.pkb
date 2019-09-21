CREATE OR REPLACE PACKAGE BODY TT_Log_Set AS
/***************************************************************************************************
Name: tt_log_set.pkb                   Author: Brendan Furey                       Date: 17-Mar-2019

Package body component in the Oracle log_set_oracle module. 

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

There is an example main program and package showing how to use the Log_Set package, and a unit test
program. Unit testing is optional and depends on the module trapit_oracle_tester.
====================================================================================================
|  Main/Test .sql  |  Package     |  Notes                                                         |
|===================================================================================================
|  main_col_group  |  Col_Group   |  Example showing how to use the Log_Set package. Col_Group is  |
|                  |              |  a simple file-reading and group-counting package              |
|                  |              |  installed via the oracle_plsql_utils module                   |
----------------------------------------------------------------------------------------------------
|  r_tests         | *TT_Log_Set* |  Unit testing the Log_Set package. Trapit is installed as a    |
|                  |  Trapit      |  separate module                                               |
====================================================================================================

This file has the TT_Log_Set unit test package body. Note that the test package is called by the
unit test utility package Trapit, which reads the unit test details from a table, tt_units,
populated by the install scripts.

The test program follows 'The Math Function Unit Testing design pattern':

    GitHub: https://github.com/BrenPatF/trapit_nodejs_tester

Note that the unit test program generates an output file, tt_log_set.tt_main_out.json, that is 
processed by a separate nodejs program, npm package trapit (see README for further details).

The output JSON file contains arrays of expected and actual records by group and scenario, in the
format expected by the nodejs program. This program produces listings of the results in HTML and/or
text format, and a sample set of listings is included in the folder test_output.

***************************************************************************************************/

CON                            CONSTANT VARCHAR2(30) := 'CON';
CON_LINE                       CONSTANT VARCHAR2(30) := 'CON_LINE';
CON_LIST                       CONSTANT VARCHAR2(30) := 'CON_LIST';
ENTRY                          CONSTANT VARCHAR2(30) := 'ENTRY';
PUT_LINE                       CONSTANT VARCHAR2(30) := 'PUT_LINE';
PUT_LIST                       CONSTANT VARCHAR2(30) := 'PUT_LIST';
OTHER_ERR                      CONSTANT VARCHAR2(30) := 'OTHER_ERR';
CUSTOM_ERR                     CONSTANT VARCHAR2(30) := 'CUSTOM_ERR';
CLO                            CONSTANT VARCHAR2(30) := 'CLO';
EXITP                          CONSTANT VARCHAR2(30) := 'EXIT';
SESSION_ID                     CONSTANT VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSIONID');
TYPE hash_int_arr IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(100);

/***************************************************************************************************

Do_Con: Construct log, returning log id. Calls relevant constructor based on 'nullity' of input
        record

***************************************************************************************************/
FUNCTION do_Con(
            p_con_rec                      Log_Set.construct_rec) -- construct record
            RETURN                         PLS_INTEGER IS         -- log id
BEGIN

  IF p_con_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct;
  ELSE
    RETURN Log_Set.Construct(p_con_rec);
  END IF;

END do_Con;

/***************************************************************************************************

Do_Con_Line: Construct log with line, returning log id. Calls relevant constructor based on 
             'nullity' of input records

***************************************************************************************************/
FUNCTION do_Con_Line(
            p_con_rec                      Log_Set.construct_rec, -- construct record
            p_line_rec                     Log_Set.line_rec,      -- line record
            p_line_text_lis                L1_chr_arr)            -- line text to put
            RETURN                         PLS_INTEGER IS         -- log id
BEGIN

  IF p_con_rec.null_yn = 'Y' AND p_line_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_text             => p_line_text_lis(1));
  ELSIF p_line_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_text             => p_line_text_lis(1),
             p_construct_rec         => p_con_rec);
  ELSIF p_con_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_text             => p_line_text_lis(1),
             p_line_rec              => p_line_rec);
  ELSE
    RETURN Log_Set.Construct(
             p_line_text             => p_line_text_lis(1),
             p_construct_rec         => p_con_rec,
             p_line_rec              => p_line_rec);
  END IF;

END do_Con_Line;

/***************************************************************************************************

Do_Entry: Construct log with line text via Entry_Point, returning log id

***************************************************************************************************/
FUNCTION do_Entry(
            p_con_rec                      Log_Set.construct_rec, -- construct record
            p_line_text_lis                L1_chr_arr)            -- line text to put
            RETURN                         PLS_INTEGER IS         -- log id
BEGIN

  RETURN Log_Set.Entry_Point(
            p_plsql_unit             => p_con_rec.header.plsql_unit,
            p_api_nm                 => p_con_rec.header.api_nm,
            p_config_key             => p_con_rec.config_key,
            p_text                   => p_line_text_lis(1));

END do_Entry;

/***************************************************************************************************

Do_Con_List: Construct log with list of lines, returning log id. Calls relevant constructor based on
             'nullity' of input records

***************************************************************************************************/
FUNCTION do_Con_List(
            p_con_rec                      Log_Set.construct_rec, -- construct record
            p_line_rec                     Log_Set.line_rec,      -- line record
            p_line_text_lis                L1_chr_arr)            -- list of lines to put
            RETURN                         PLS_INTEGER IS         -- log id
BEGIN

  IF p_con_rec.null_yn = 'Y' AND p_line_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_lis              => p_line_text_lis);
  ELSIF p_line_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_lis              => p_line_text_lis,
             p_construct_rec         => p_con_rec);
  ELSIF p_con_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct(
             p_line_lis              => p_line_text_lis,
             p_line_rec              => p_line_rec);
  ELSE
    RETURN Log_Set.Construct(
             p_line_lis              => p_line_text_lis,
             p_construct_rec         => p_con_rec,
             p_line_rec              => p_line_rec);
  END IF;

 END do_Con_List;

/***************************************************************************************************

Do_Put_Line: Put line to log. Calls relevant method based on 'nullity' of input record and log id

***************************************************************************************************/
PROCEDURE do_Put_Line(
            p_log_id                       PLS_INTEGER,      -- log id
            p_line_rec                     Log_Set.line_rec, -- line record
            p_line_text_lis                L1_chr_arr) IS    -- line text list
BEGIN

  IF p_log_id IS NULL THEN

    IF p_line_rec.null_yn = 'Y' THEN
      Log_Set.Put_Line(p_line_text             => p_line_text_lis(1));
    ELSE
      Log_Set.Put_Line(p_line_text             => p_line_text_lis(1),
                       p_line_rec              => p_line_rec);
    END IF;

  ELSIF p_line_rec.null_yn = 'Y' THEN
    Log_Set.Put_Line(p_log_id                => p_log_id,
                     p_line_text             => p_line_text_lis(1));

  ELSE
    Log_Set.Put_Line(p_log_id                => p_log_id,
                     p_line_text             => p_line_text_lis(1),
                     p_line_rec              => p_line_rec);
  END IF;

END do_Put_Line;

/***************************************************************************************************

Do_Put_List: Put list of lines to log. Calls relevant method based on 'nullity' of input record and
             log id

***************************************************************************************************/
PROCEDURE do_Put_List(
             p_log_id                      PLS_INTEGER,      -- log id
             p_line_rec                    Log_Set.line_rec, -- line record
             p_line_text_lis               L1_chr_arr) IS    -- line text list
BEGIN

  IF p_log_id IS NULL THEN

    IF p_line_rec.null_yn = 'Y' THEN
      Log_Set.Put_List(p_line_lis             => p_line_text_lis);
    ELSE
      Log_Set.Put_List(p_line_lis             => p_line_text_lis,
                       p_line_rec             => p_line_rec);
    END IF;

  ELSIF p_line_rec.null_yn = 'Y' THEN
    Log_Set.Put_List(p_log_id               => p_log_id,
                     p_line_lis             => p_line_text_lis);

  ELSE
    Log_Set.Put_List(p_log_id               => p_log_id,
                     p_line_lis             => p_line_text_lis,
                     p_line_rec             => p_line_rec);
  END IF;
END do_Put_List;

/***************************************************************************************************

Add_Log_Configs: Insert log config records, constructing context list where applicable, and calling 
                 the log config API. Returns list of the config keys created

***************************************************************************************************/
FUNCTION add_Log_Configs(
            p_log_config_2lis              L2_chr_arr,   -- log config 2-list
            p_context_2lis                 L2_chr_arr)   -- context 2-list
            RETURN                         L1_chr_arr IS -- log config key list
  l_log_config_lis          L1_chr_arr;
  l_log_config_key_lis      L1_chr_arr;
  l_context_lis             L1_chr_arr;
  l_ctx_inps                ctx_inp_obj;
  l_ctx_inp_lis             ctx_inp_arr;
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  IF p_log_config_2lis IS NULL THEN RETURN NULL; END IF;

  l_log_config_key_lis := L1_chr_arr();
  l_log_config_key_lis.EXTEND(p_log_config_2lis.COUNT);
  FOR i IN 1..p_log_config_2lis.COUNT LOOP

    l_log_config_lis := p_log_config_2lis(i);
    l_log_config_key_lis(i) := l_log_config_lis(1);
    IF p_context_2lis IS NOT NULL THEN

      FOR j IN 1..p_context_2lis.COUNT LOOP

        l_context_lis := p_context_2lis(j);
        IF l_context_lis(1) = l_log_config_lis(1) THEN
          l_ctx_inps := ctx_inp_obj(l_context_lis(2), l_context_lis(3), l_context_lis(4));

          IF l_ctx_inp_lis IS NULL THEN
            l_ctx_inp_lis := ctx_inp_arr(l_ctx_inps);
          ELSE
            l_ctx_inp_lis.EXTEND();
            l_ctx_inp_lis(l_ctx_inp_lis.COUNT) := l_ctx_inps;
          END IF;

        END IF;

      END LOOP;

    END IF;

    Log_Config.Ins_Config(
      p_config_key              => l_log_config_lis(1),
      p_put_lev                 => l_log_config_lis(2),
      p_put_lev_stack           => l_log_config_lis(3),
      p_put_lev_cpu             => l_log_config_lis(4),
      p_ctx_inp_lis             => l_ctx_inp_lis,
      p_put_lev_module          => l_log_config_lis(5),
      p_put_lev_action          => l_log_config_lis(6),
      p_put_lev_client_info     => l_log_config_lis(7),
      p_app_info_only_yn        => l_log_config_lis(8),
      p_singleton_yn            => l_log_config_lis(9),
      p_buff_len                => l_log_config_lis(10),
      p_extend_len              => l_log_config_lis(11));

  END LOOP;
  COMMIT;
  RETURN l_log_config_key_lis;

END add_Log_Configs;

/***************************************************************************************************

Get_Event_Prm_Lis: Search rows of 2-d list for one row with event number in first element, and if
                   found return the matching row as 1-d list. This is for Construct and Log 
                   Parameter lists

***************************************************************************************************/
FUNCTION get_Event_Prm_Lis(
            p_event_no                     PLS_INTEGER,  -- event number
            p_prm_2lis                     L2_chr_arr)   -- parameters 2-list
            RETURN                         L1_chr_arr IS -- 1-list of construct or log parameter values
BEGIN

  FOR i IN 1..p_prm_2lis.COUNT LOOP

    IF p_prm_2lis(i)(1) = p_event_no THEN
      RETURN p_prm_2lis(i);
    END IF;

  END LOOP;
  RETURN NULL;

END get_Event_Prm_Lis;

/***************************************************************************************************

Get_Event_Prm_Txt_Lis: Search rows of 2-d list for all rows with event number in first element, and
                       return all the second elements foundas 1-d list. This is for the Line Text
                       list

***************************************************************************************************/
FUNCTION get_Event_Prm_Txt_Lis(
            p_event_no                     PLS_INTEGER,  -- event number
            p_prm_2lis                     L2_chr_arr)   -- parameters 2-list
            RETURN                         L1_chr_arr IS -- 1-list of line text values
  l_txt_lis               L1_chr_arr;
BEGIN

  FOR i IN 1..p_prm_2lis.COUNT LOOP

    IF p_prm_2lis(i)(1) = p_event_no THEN

      IF l_txt_lis IS NULL THEN
        l_txt_lis := L1_chr_arr(p_prm_2lis(i)(2));
      ELSE
        l_txt_lis.EXTEND;
        l_txt_lis(l_txt_lis.COUNT) := p_prm_2lis(i)(2);
      END IF;

    END IF;

  END LOOP;

  RETURN l_txt_lis;

END get_Event_Prm_Txt_Lis;

/***************************************************************************************************

Get_Lgh_Lis: Return a list of delimited records from log headers for current session. Ids are
             returned as offsets from last ids, and timestamps also offset

***************************************************************************************************/
FUNCTION get_Lgh_Lis(
            p_last_seq_lgh                 PLS_INTEGER,  -- last sequence number for logs
            p_last_seq_lcf                 PLS_INTEGER,  -- last sequence number for log configs
            p_max_log_id                   PLS_INTEGER,  -- max log id at start
            p_start_tmstp                  TIMESTAMP)    -- timestamp at start of scenario
            RETURN                         L1_chr_arr IS -- list of delimited log records
  l_lgh_lis       L1_chr_arr;
BEGIN

  SELECT Utils.Join_Values(
          lgh.id - p_last_seq_lgh,
          CASE WHEN lgh.config_id <= p_last_seq_lcf THEN 0 ELSE lgh.config_id - p_last_seq_lcf END,
          lcf.config_key,
          lgh.session_id - TT_Log_Set.SESSION_ID,
          lgh.session_user,
          lgh.description,
          lgh.plsql_unit,
          lgh.api_nm,
          lgh.put_lev_min,
          Utils.IntervalDS_To_Seconds(lgh.creation_tmstp - p_start_tmstp),
          Utils.IntervalDS_To_Seconds(lgh.closure_tmstp - p_start_tmstp))
    BULK COLLECT INTO l_lgh_lis
    FROM log_headers lgh
    JOIN log_configs lcf
      ON lcf.id = lgh.config_id
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID AND lgh.id > p_max_log_id
   ORDER BY lgh.id;

  RETURN l_lgh_lis;

EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END get_Lgh_Lis;

/***************************************************************************************************

Get_Ctx_Lis: Return a list of contexts at header or line level for current session

***************************************************************************************************/
FUNCTION get_Ctx_Lis(
            p_last_seq_lgh                 PLS_INTEGER,  -- last sequence number for logs
            p_max_log_id                   PLS_INTEGER)  -- max log id at start
            RETURN                         L1_chr_arr IS -- list of delimited contexts
  l_ctx_lis       L1_chr_arr;
BEGIN

  WITH source_union AS (
    SELECT lgh.id,
           To_Number(NULL) line_num,
           ctx.ctx_nm,
           ctx.ctx_vl
    FROM log_headers lgh
   CROSS APPLY (SELECT * FROM TABLE(lgh.ctx_out_lis)) ctx
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID AND lgh.id > p_max_log_id
   UNION ALL
    SELECT lgh.id,
           lgl.line_num,
           ctx.ctx_nm,
           ctx.ctx_vl
    FROM log_headers lgh
    JOIN log_lines lgl
      ON lgl.log_id = lgh.id
   CROSS APPLY (SELECT * FROM TABLE(lgl.ctx_out_lis)) ctx
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID AND lgh.id > p_max_log_id
  )
  SELECT Utils.Join_Values(
          To_Char(id - p_last_seq_lgh),
          line_num,
          ctx_nm,
          CASE ctx_nm 
            WHEN 'sessionid' THEN To_Char(To_Number(ctx_vl) - TT_Log_Set.SESSION_ID)
            ELSE ctx_vl
          END)
    BULK COLLECT INTO l_ctx_lis
    FROM source_union
   ORDER BY id, line_num, ctx_nm;

  RETURN l_ctx_lis;

EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END get_Ctx_Lis;

/***************************************************************************************************

get_Lgl_Lis: Return a list of delimited records from log lines for current session. Replaces chr(10)
             with <EOL>. Log id is offset from last id, and times also offset

***************************************************************************************************/
FUNCTION get_Lgl_Lis(
            p_last_seq_lgh                 PLS_INTEGER,  -- last sequence number for logs
            p_max_log_id                   PLS_INTEGER,  -- max log id at start
            p_start_tmstp                  TIMESTAMP,    -- timestamp at start of scenario
            p_start_cpu_cs                 PLS_INTEGER)  -- CPU at start of scenario
            RETURN                         L1_chr_arr IS -- list of delimited log records
  l_lgl_lis       L1_chr_arr;
BEGIN

  SELECT Utils.Join_Values(
          To_Char(lgh.id - p_last_seq_lgh),
          lgl.line_num,
          lgl.session_line_num,
          lgl.line_type,
          lgl.plsql_unit,
          lgl.plsql_line,
          lgl.group_text,
          lgl.action,
          lgl.line_text,
          Replace(lgl.call_stack, Chr(10), '<EOL>'),
          Replace(lgl.error_backtrace, Chr(10), '<EOL>'),
          lgl.put_lev_min,
          lgl.err_num,
          lgl.err_msg,
          Utils.IntervalDS_To_Seconds(lgl.creation_tmstp - p_start_tmstp),
          lgl.creation_cpu_cs - p_start_cpu_cs)
    BULK COLLECT INTO l_lgl_lis
    FROM log_headers lgh
    JOIN log_lines lgl
      ON lgl.log_id = lgh.id
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID AND lgh.id > p_max_log_id
   ORDER BY lgh.id, lgl.line_num;

  RETURN l_lgl_lis;

EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END get_Lgl_Lis;

/***************************************************************************************************

Get_App_Info: Return delimited list of the DBMS_Application_Info fields

***************************************************************************************************/
FUNCTION get_App_Info RETURN VARCHAR2 IS
  l_module_name     VARCHAR2(100);
  l_action_name     VARCHAR2(100);
  l_client_info     VARCHAR2(100);
BEGIN

  DBMS_Application_Info.Read_Module(module_name => l_module_name, action_name => l_action_name);
  DBMS_Application_Info.Read_Client_Info(client_info  => l_client_info);
  RETURN Utils.Join_Values(l_module_name, l_action_name, l_client_info);

END get_App_Info;

/***************************************************************************************************

Get_Con_Rec: Return construct record by mmapping from list to the constructor function parameters

***************************************************************************************************/
FUNCTION get_Con_Rec(
            p_con_prms_lis                 L1_chr_arr)              -- construct parameters list
            RETURN                         Log_Set.construct_rec IS -- construct record
BEGIN

  RETURN Log_Set.Con_Construct_Rec(    
                   p_config_key            => p_con_prms_lis(2),
                   p_description           => p_con_prms_lis(3),
                   p_plsql_unit            => p_con_prms_lis(4),
                   p_api_nm                => p_con_prms_lis(5),
                   p_put_lev_min           => p_con_prms_lis(6),
                   p_do_close              => p_con_prms_lis(7) = 'Y');

END get_Con_Rec;

/***************************************************************************************************

Get_Line_Rec: Return line record by mmapping from list to the constructor function parameters

***************************************************************************************************/
FUNCTION get_Line_Rec(
            p_put_prms_lis                 L1_chr_arr)         -- put parameters list
            RETURN                         Log_Set.line_rec IS -- line record
BEGIN

  RETURN Log_Set.Con_Line_Rec(
                   p_line_type             => p_put_prms_lis(2),
                   p_plsql_unit            => p_put_prms_lis(3),
                   p_plsql_line            => p_put_prms_lis(4),
                   p_group_text            => p_put_prms_lis(5),
                   p_action                => p_put_prms_lis(6),
                   p_put_lev_min           => p_put_prms_lis(7),
                   p_err_num               => p_put_prms_lis(8),
                   p_err_msg               => p_put_prms_lis(9),
                   p_do_close              => p_put_prms_lis(10) = 'Y');

END get_Line_Rec;

/***************************************************************************************************

Do_Event_Con: Handle CON* events, returning new log set hash with any new log ids added

***************************************************************************************************/
FUNCTION do_Event_Con(
            p_event_type                   VARCHAR2,         -- event type
            p_line_rec                     Log_Set.line_rec, -- line record
            p_con_prms_lis                 L1_chr_arr,       -- construct parameter list
            p_line_text_lis                L1_chr_arr)       -- line text list
            RETURN                         PLS_INTEGER IS
  l_con_rec                      Log_Set.construct_rec;
  l_con_log_id                   PLS_INTEGER;
BEGIN

  l_con_rec := get_Con_Rec(p_con_prms_lis => p_con_prms_lis);
  CASE p_event_type

    WHEN CON THEN
      l_con_log_id := do_Con(p_con_rec => l_con_rec);
  
    WHEN CON_LINE THEN
      l_con_log_id := do_Con_Line(
                        p_con_rec         => l_con_rec,
                        p_line_rec        => p_line_rec,
                        p_line_text_lis   => p_line_text_lis);

    WHEN ENTRY THEN
      l_con_log_id := do_Entry(
                        p_con_rec         => l_con_rec,
                        p_line_text_lis   => p_line_text_lis);

    WHEN CON_LIST THEN
      l_con_log_id := do_Con_List(
                        p_con_rec         => l_con_rec,
                        p_line_rec        => p_line_rec,
                        p_line_text_lis   => p_line_text_lis);

  END CASE;

  RETURN l_con_log_id;

END do_Event_Con;

/***************************************************************************************************

Do_Event_Put: Handle PUT* events

***************************************************************************************************/
PROCEDURE do_Event_Put(
            p_event_type                   VARCHAR2,         -- event type
            p_log_id                       PLS_INTEGER,      -- log id
            p_line_rec                     Log_Set.line_rec, -- line record
            p_line_text_lis                L1_chr_arr) IS    -- line text list
BEGIN

  CASE p_event_type

    WHEN PUT_LINE THEN
      do_Put_Line(
        p_log_id                => p_log_id,
        p_line_text_lis         => p_line_text_lis,
        p_line_rec              => p_line_rec);
  
    WHEN PUT_LIST THEN
      do_Put_List(
        p_log_id                => p_log_id,
        p_line_text_lis         => p_line_text_lis,
        p_line_rec              => p_line_rec);

  END CASE;
  
END do_Event_Put;

/***************************************************************************************************

Do_Event_Others: Handle non-CON*,PUT* events

***************************************************************************************************/
PROCEDURE do_Event_Others(
            p_event_type                   VARCHAR2,      -- event type
            p_log_id                       PLS_INTEGER,   -- log id
            p_line_text_lis                L1_chr_arr) IS -- text lines, first is custom error message
BEGIN

  CASE p_event_type

    WHEN OTHER_ERR THEN
      BEGIN
        RAISE NO_DATA_FOUND;
      EXCEPTION
        WHEN OTHERS THEN
          Log_Set.Write_Other_Error(p_log_id => p_log_id);
      END;
  
    WHEN CLO THEN
      IF p_log_id IS NULL THEN
        Log_Set.Close_Log;
      ELSE
        Log_Set.Close_Log(p_log_id => p_log_id);
      END IF;

    WHEN EXITP THEN
      Log_Set.Exit_Point(
            p_log_id                 => p_log_id,
            p_text                   => p_line_text_lis(1));

    WHEN CUSTOM_ERR THEN
      IF p_log_id IS NULL THEN
        Log_Set.Raise_Error(p_err_msg => p_line_text_lis(1));
      ELSE
        Log_Set.Raise_Error(p_err_msg => p_line_text_lis(1), p_log_id => p_log_id);
      END IF;

    ELSE 
      Utils.Raise_Error('Error: ' || p_event_type || ' event not found');

  END CASE;
  
END do_Event_Others;

/***************************************************************************************************

Handle_Event: Handle event, returning new log set hash with any new log ids added

***************************************************************************************************/
FUNCTION handle_Event(
           p_event_lis                    L1_chr_arr,     -- event fields list for an event
           p_con_prms_lis                 L1_chr_arr,     -- construct parameter list
           p_put_prms_lis                 L1_chr_arr,     -- put parameter list
           p_line_text_lis                L1_chr_arr,     -- line text list
           p_log_set_hsh                  hash_int_arr)   -- existing log set hash
           RETURN                         hash_int_arr IS -- new log set hash

  l_line_rec                     Log_Set.line_rec;
  l_event_type                   VARCHAR2(30) := p_event_lis(2);
  l_log_id_offset                PLS_INTEGER := p_event_lis(3);

  l_log_id                       PLS_INTEGER := CASE WHEN l_log_id_offset IS NULL THEN
                                                       NULL
                                                     WHEN p_log_set_hsh.EXISTS(l_log_id_offset) THEN
                                                       p_log_set_hsh(l_log_id_offset)
                                                     ELSE 0
                                                END;
  l_con_log_id                   PLS_INTEGER;
  l_new_log_set_hsh              hash_int_arr := p_log_set_hsh;
BEGIN

  IF l_event_type IN (CON_LINE, CON_LIST, PUT_LINE, PUT_LIST, ENTRY) THEN
  
    l_line_rec := get_Line_Rec(p_put_prms_lis => p_put_prms_lis);

  END IF;

  IF l_event_type IN (CON, CON_LINE, CON_LIST, ENTRY) THEN
    l_con_log_id := do_Event_Con(
                       p_event_type     => l_event_type,
                       p_line_rec       => l_line_rec,
                       p_con_prms_lis   => p_con_prms_lis,
                       p_line_text_lis  => p_line_text_lis);

      IF l_log_id_offset IS NOT NULL THEN
        l_new_log_set_hsh(l_log_id_offset) := l_con_log_id;
      END IF;

  ELSIF l_event_type IN (PUT_LINE, PUT_LIST) THEN
    do_Event_Put(
       p_event_type    => l_event_type,
       p_log_id        => l_log_id,
       p_line_rec      => l_line_rec,
       p_line_text_lis => p_line_text_lis);

  ELSIF l_event_type IN (OTHER_ERR, CUSTOM_ERR, CLO, EXITP) THEN
    do_Event_Others(
            p_event_type    => l_event_type,
            p_log_id        => l_log_id,
            p_line_text_lis => p_line_text_lis);
  END IF;

  RETURN l_new_log_set_hsh;
END handle_Event;

/***************************************************************************************************

Do_Event_List: Process the list of events, returning the exception list if any

***************************************************************************************************/
FUNCTION do_Event_List(
           p_events_2lis                  L2_chr_arr,   -- events list of lists
           p_con_prms_2lis                L2_chr_arr,   -- construct parameters list of lists
           p_put_prms_2lis                L2_chr_arr,   -- put parameters list of lists
           p_txt_prms_2lis                L2_chr_arr)   -- line text parameters list of lists
           RETURN                         L1_chr_arr IS -- output list of exception

  CUSTOM_ERR_EX                  EXCEPTION;
  PRAGMA EXCEPTION_INIT(CUSTOM_ERR_EX, -20000);
  l_event_no                     PLS_INTEGER;
  l_log_set_hsh                  hash_int_arr;
BEGIN

  FOR i IN 1..p_events_2lis.COUNT LOOP

    l_event_no := p_events_2lis(i)(1);
    l_log_set_hsh := handle_Event(           
                        p_event_lis       => p_events_2lis(i),
                        p_con_prms_lis    => get_Event_Prm_Lis(    p_event_no => l_event_no, 
                                                                   p_prm_2lis => p_con_prms_2lis),
                        p_put_prms_lis    => get_Event_Prm_Lis(    p_event_no => l_event_no, 
                                                                   p_prm_2lis => p_put_prms_2lis),
                        p_line_text_lis   => get_Event_Prm_Txt_Lis(p_event_no => l_event_no,  
                                                                   p_prm_2lis => p_txt_prms_2lis),
                        p_log_set_hsh     => l_log_set_hsh);
  END LOOP;
  RETURN NULL;

EXCEPTION

  WHEN CUSTOM_ERR_EX THEN
    RETURN L1_chr_arr(SQLERRM, DBMS_Utility.Format_Error_Backtrace);

END do_Event_List;
  
/***************************************************************************************************

purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' function, called once per 
                 scenario, with the output 'actuals' array including everything affected by the API,
                 whether as output parameters, or on database tables, etc. The inputs are also
                 extended from the API parameters to include any other effective inputs

***************************************************************************************************/
FUNCTION purely_Wrap_API(p_last_seq_lgh         PLS_INTEGER,  -- last sequence value for log headers
                         p_last_seq_lcf         PLS_INTEGER,  -- last sequence value for log configs
                         p_max_log_id           PLS_INTEGER,  -- max log id for session at start
                         p_inp_3lis             L3_chr_arr)   -- input list of lists (record, field)
                         RETURN                 L2_chr_arr IS -- output list of lists (group, record)

  l_log_config_lis               L1_chr_arr;
  l_act_2lis                     L2_chr_arr := L2_chr_arr();
  l_start_tmstp                  TIMESTAMP := SYSTIMESTAMP;
  l_start_cpu_cs                 PLS_INTEGER := DBMS_Utility.Get_CPU_Time;

BEGIN

  Log_Set.Init;
  l_log_config_lis := add_Log_Configs(p_inp_3lis(1), p_inp_3lis(2)); -- lcf, ctx
  l_act_2lis.EXTEND(5);
  l_act_2lis(4) :=  do_Event_List(
                      p_events_2lis     => p_inp_3lis(3),
                      p_con_prms_2lis   => p_inp_3lis(4),
                      p_put_prms_2lis   => p_inp_3lis(5),
                      p_txt_prms_2lis   => p_inp_3lis(6));

  l_act_2lis(1) := get_Lgh_Lis(p_last_seq_lgh   => p_last_seq_lgh,
                               p_last_seq_lcf   => p_last_seq_lcf,
                               p_max_log_id     => p_max_log_id,
                               p_start_tmstp    => l_start_tmstp);
  l_act_2lis(2) := get_Ctx_Lis(p_last_seq_lgh   => p_last_seq_lgh,
                               p_max_log_id     => p_max_log_id);
  l_act_2lis(3) := get_Lgl_Lis(p_last_seq_lgh   => p_last_seq_lgh,
                               p_max_log_id     => p_max_log_id,
                               p_start_tmstp    => l_start_tmstp,
                               p_start_cpu_cs   => l_start_cpu_cs);
  l_act_2lis(5) := L1_chr_arr(Get_App_Info);
  ROLLBACK;

  Log_Set.Delete_Log(p_session_id => TT_Log_Set.SESSION_ID, 
                     p_min_log_id => p_max_log_id);
  
  IF l_log_config_lis IS NOT NULL THEN
    FOR i IN 1..l_log_config_lis.COUNT LOOP
      Log_Config.Del_Config(l_log_config_lis(i));
    END LOOP;
  END IF;
  COMMIT;

  RETURN l_act_2lis;
END purely_Wrap_API;

/***************************************************************************************************

Test_API: Entry point method for the unit test. Uses Trapit to read the test data from JSON clob
          into a 4-d list of (scenario, group, record, field), then calls a 'pure' wrapper function
          within a loop over the scenarios to get the actuals. A final call to Trapit.Set_Outputs
          creates the output JSON in tt_units as well as on file to be processed by trapit_nodejs

***************************************************************************************************/
PROCEDURE Test_API IS

  PROC_NM                        CONSTANT VARCHAR2(30) := 'Test_API';

  l_act_3lis                     L3_chr_arr := L3_chr_arr();
  l_sces_4lis                    L4_chr_arr;
  l_scenarios                    Trapit.scenarios_rec;
  l_last_seq_lgh                 PLS_INTEGER;
  l_last_seq_lcf                 PLS_INTEGER;
  l_def_config_id                PLS_INTEGER;
  l_max_log_id                   PLS_INTEGER;

BEGIN

--  l_timer_set := Trapit.Init(TIMER_SET_NM);
  l_scenarios := Trapit.Get_Inputs(p_package_nm    => $$PLSQL_UNIT,
                                   p_procedure_nm  => PROC_NM);
  l_sces_4lis := l_scenarios.scenarios_4lis;
  l_act_3lis.EXTEND(l_sces_4lis.COUNT);
  SELECT Nvl(Max(id),0) INTO l_max_log_id FROM log_headers WHERE session_id = TT_Log_Set.SESSION_ID;

  FOR i IN 1..l_sces_4lis.COUNT LOOP

    l_last_seq_lgh := log_headers_s.NEXTVAL;
    l_last_seq_lcf := log_configs_s.NEXTVAL;

    DBMS_Application_Info.Set_Module('', '');
    DBMS_Application_Info.Set_Client_Info('');
    l_act_3lis(i) := purely_Wrap_API(p_last_seq_lgh => l_last_seq_lgh, 
                                     p_last_seq_lcf => l_last_seq_lcf,
                                     p_max_log_id   => l_max_log_id,
                                     p_inp_3lis     => l_sces_4lis(i));

  END LOOP;

  Trapit.Set_Outputs(p_package_nm    => $$PLSQL_UNIT,
                     p_procedure_nm  => PROC_NM,
                     p_act_3lis      => l_act_3lis);

END Test_API;

END TT_Log_Set;
/
SHO ERR