CREATE OR REPLACE PACKAGE BODY TT_Log_Set AS
/***************************************************************************************************
Name: tt_log_set.pkb                   Author: Brendan Furey                       Date: 17-Mar-2019

Package body component in the Oracle log_set_oracle module. This is a logging framework that 
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

This file has the unit test TT_Log_Set package body (lib schema). Note that the test package is
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

CON                            CONSTANT VARCHAR2(30) := 'CON';
CON_LINE                       CONSTANT VARCHAR2(30) := 'CON_LINE';
CON_LIST                       CONSTANT VARCHAR2(30) := 'CON_LIST';
PUT_LINE                       CONSTANT VARCHAR2(30) := 'PUT_LINE';
PUT_LIST                       CONSTANT VARCHAR2(30) := 'PUT_LIST';
OTHER_ERR                      CONSTANT VARCHAR2(30) := 'OTHER_ERR';
CLO                            CONSTANT VARCHAR2(30) := 'CLO';
SESSION_ID                     CONSTANT VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSIONID');
TYPE hash_int_arr IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(100);

/***************************************************************************************************

Do_Con: Construct log, returning log id. Calls relevant constructor based on 'nullity' of input
        record

***************************************************************************************************/
FUNCTION Do_Con(
            p_con_rec                      Log_Set.construct_rec) -- construct record
            RETURN                         PLS_INTEGER IS         -- log id
BEGIN

  IF p_con_rec.null_yn = 'Y' THEN
    RETURN Log_Set.Construct;
  ELSE
    RETURN Log_Set.Construct(p_con_rec);
  END IF;

END Do_Con;

/***************************************************************************************************

Do_Con_Line: Construct log with line, returning log id. Calls relevant constructor based on 
             'nullity' of input records

***************************************************************************************************/
FUNCTION Do_Con_Line(
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

END Do_Con_Line;

/***************************************************************************************************

Do_Con_List: Construct log with list of lines, returning log id. Calls relevant constructor based on
             'nullity' of input records

***************************************************************************************************/
FUNCTION Do_Con_List(
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

 END Do_Con_List;

/***************************************************************************************************

Do_Put_Line: Put line to log. Calls relevant method based on 'nullity' of input record and log id

***************************************************************************************************/
PROCEDURE Do_Put_Line(
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

END Do_Put_Line;

/***************************************************************************************************

Do_Put_List: Put list of lines to log. Calls relevant method based on 'nullity' of input record and
             log id

***************************************************************************************************/
PROCEDURE Do_Put_List(
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
END Do_Put_List;

/***************************************************************************************************

Add_Log_Configs: Insert log config records, constructing context list where applicable, and calling 
                 the log config API. Returns list of the config keys created

***************************************************************************************************/
FUNCTION Add_Log_Configs(
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

END Add_Log_Configs;

/***************************************************************************************************

Get_Event_Prm_Lis: Search rows of 2-d list for one row with event number in first element, and if
                   found return the matching row as 1-d list. This is for Construct and Log 
                   Parameter lists

***************************************************************************************************/
FUNCTION Get_Event_Prm_Lis(
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

END Get_Event_Prm_Lis;

/***************************************************************************************************

Get_Event_Prm_Txt_Lis: Search rows of 2-d list for all rows with event number in first element, and
                       return all the second elements foundas 1-d list. This is for the Line Text
                       list

***************************************************************************************************/
FUNCTION Get_Event_Prm_Txt_Lis(
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

END Get_Event_Prm_Txt_Lis;

/***************************************************************************************************

Get_Lgh_Lis: Return a list of delimited records from log headers for current session. Ids are
             returned as offsets from last ids, and timestamps also offset

***************************************************************************************************/
FUNCTION Get_Lgh_Lis(
            p_last_seq_lgh                 PLS_INTEGER,  -- last sequence number for logs
            p_last_seq_lcf                 PLS_INTEGER,  -- last sequence number for log configs
            p_start_tmstp                  TIMESTAMP)    -- timestamp at start of scenario
            RETURN                         L1_chr_arr IS -- list of delimited log records
  l_lgh_lis       L1_chr_arr;
BEGIN

  SELECT Utils.List_Delim(
          lgh.id - p_last_seq_lgh,
          CASE WHEN lgh.config_id <= p_last_seq_lcf THEN 0 ELSE lgh.config_id - p_last_seq_lcf END,
          lgh.session_id - TT_Log_Set.SESSION_ID,
          lgh.session_user,
          lgh.put_lev_min,
          lgh.description,
          Utils.Get_Seconds(lgh.creation_tmstp - p_start_tmstp),
          Utils.Get_Seconds(lgh.closure_tmstp - p_start_tmstp))
    BULK COLLECT INTO l_lgh_lis
    FROM log_headers lgh
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID
   ORDER BY lgh.id;

  RETURN l_lgh_lis;

EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END Get_Lgh_Lis;

/***************************************************************************************************

Get_Ctx_Lis: Return a list of contexts at header or line level for current session

***************************************************************************************************/
FUNCTION Get_Ctx_Lis(
            p_last_seq_lgh                 PLS_INTEGER)  -- last sequence number for logs
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
   WHERE lgh.session_id = SESSION_ID
   UNION ALL
    SELECT lgh.id,
           lgl.line_num,
           ctx.ctx_nm,
           ctx.ctx_vl
    FROM log_headers lgh
    JOIN log_lines lgl
      ON lgl.log_id = lgh.id
   CROSS APPLY (SELECT * FROM TABLE(lgl.ctx_out_lis)) ctx
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID
  )
  SELECT Utils.List_Delim(
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
END Get_Ctx_Lis;

/***************************************************************************************************

Get_Lgl_Lis: Return a list of delimited records from log lines for current session. Replaces chr(10)
             with <EOL>. Log id is offset from last id, and times also offset

***************************************************************************************************/
FUNCTION Get_Lgl_Lis(
            p_last_seq_lgh                 PLS_INTEGER,  -- last sequence number for logs
            p_start_tmstp                  TIMESTAMP,    -- timestamp at start of scenario
            p_start_cpu_cs                 PLS_INTEGER)  -- CPU at start of scenario
            RETURN                         L1_chr_arr IS -- list of delimited log records
  l_lgl_lis       L1_chr_arr;
BEGIN

  SELECT Utils.List_Delim(
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
          Utils.Get_Seconds(lgl.creation_tmstp - p_start_tmstp),
          lgl.creation_cpu_cs - p_start_cpu_cs)
    BULK COLLECT INTO l_lgl_lis
    FROM log_headers lgh
    JOIN log_lines lgl
      ON lgl.log_id = lgh.id
   WHERE lgh.session_id = TT_Log_Set.SESSION_ID
   ORDER BY lgh.id, lgl.line_num;

  RETURN l_lgl_lis;

EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN NULL;
END Get_Lgl_Lis;

/***************************************************************************************************

Get_App_Info: Return delimited list of the DBMS_Application_Info fields

***************************************************************************************************/
FUNCTION Get_App_Info RETURN VARCHAR2 IS
  l_module_name     VARCHAR2(100);
  l_action_name     VARCHAR2(100);
  l_client_info     VARCHAR2(100);
BEGIN

  DBMS_Application_Info.Read_Module(module_name => l_module_name, action_name => l_action_name);
  DBMS_Application_Info.Read_Client_Info(client_info  => l_client_info);
  RETURN Utils.List_Delim(l_module_name, l_action_name, l_client_info);

END Get_App_Info;

/***************************************************************************************************

Get_Con_Rec: Return construct record by mmapping from list to the constructor function parameters

***************************************************************************************************/
FUNCTION Get_Con_Rec(
            p_con_prms_lis                 L1_chr_arr)              -- construct parameters list
            RETURN                         Log_Set.construct_rec IS -- construct record
BEGIN

  RETURN Log_Set.Con_Construct_Rec(    
                   p_config_key            => p_con_prms_lis(2),
                   p_description           => p_con_prms_lis(3),
                   p_put_lev_min           => p_con_prms_lis(4),
                   p_do_close              => p_con_prms_lis(5) = 'Y');

END Get_Con_Rec;

/***************************************************************************************************

Get_Line_Rec: Return line record by mmapping from list to the constructor function parameters

***************************************************************************************************/
FUNCTION Get_Line_Rec(
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

END Get_Line_Rec;

/***************************************************************************************************

Do_Event_Con: Handle CON* events, returning new log set hash with any new log ids added

***************************************************************************************************/
FUNCTION Do_Event_Con(
            p_event_type                   VARCHAR2,         -- event type
            p_line_rec                     Log_Set.line_rec, -- line record
            p_con_prms_lis                 L1_chr_arr,       -- construct parameter list
            p_line_text_lis                L1_chr_arr)       -- line text list
            RETURN                         PLS_INTEGER IS
  l_con_rec                      Log_Set.construct_rec;
  l_con_log_id                   PLS_INTEGER;
BEGIN

  l_con_rec := Get_Con_Rec(p_con_prms_lis => p_con_prms_lis);
  CASE p_event_type

    WHEN CON THEN
      l_con_log_id := Do_Con(p_con_rec => l_con_rec);
  
    WHEN CON_LINE THEN
      l_con_log_id := Do_Con_Line(
                        p_con_rec         => l_con_rec,
                        p_line_rec        => p_line_rec,
                        p_line_text_lis   => p_line_text_lis);

    WHEN CON_LIST THEN
      l_con_log_id := Do_Con_List(
                        p_con_rec         => l_con_rec,
                        p_line_rec        => p_line_rec,
                        p_line_text_lis   => p_line_text_lis);

  END CASE;

  RETURN l_con_log_id;

END Do_Event_Con;

/***************************************************************************************************

Do_Event_Put: Handle PUT* events

***************************************************************************************************/
PROCEDURE Do_Event_Put(
            p_event_type                   VARCHAR2,         -- event type
            p_log_id                       PLS_INTEGER,      -- log id
            p_line_rec                     Log_Set.line_rec, -- line record
            p_line_text_lis                L1_chr_arr) IS    -- line text list
BEGIN

  CASE p_event_type

    WHEN PUT_LINE THEN
      Do_Put_Line(
        p_log_id                => p_log_id,
        p_line_text_lis         => p_line_text_lis,
        p_line_rec              => p_line_rec);
  
    WHEN PUT_LIST THEN
      Do_Put_List(
        p_log_id                => p_log_id,
        p_line_text_lis         => p_line_text_lis,
        p_line_rec              => p_line_rec);

  END CASE;
  
END Do_Event_Put;

/***************************************************************************************************

Do_Event_Others: Handle non-CON*,PUT* events

***************************************************************************************************/
PROCEDURE Do_Event_Others(
            p_event_type                   VARCHAR2,       -- event type
            p_log_id                       PLS_INTEGER) IS -- log id
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

    ELSE 
      Utils.Raise_Error('Error: ' || p_event_type || ' event not found');

  END CASE;
  
END Do_Event_Others;

/***************************************************************************************************

Handle_Event: Handle event, returning new log set hash with any new log ids added

***************************************************************************************************/
FUNCTION Handle_Event(
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

  IF l_event_type IN (CON_LINE, CON_LIST, PUT_LINE, PUT_LIST) THEN
  
    l_line_rec := Get_Line_Rec(p_put_prms_lis => p_put_prms_lis);

  END IF;

  IF l_event_type IN (CON, CON_LINE, CON_LIST) THEN
    l_con_log_id := Do_Event_Con(
                       p_event_type     => l_event_type,
                       p_line_rec       => l_line_rec,
                       p_con_prms_lis   => p_con_prms_lis,
                       p_line_text_lis  => p_line_text_lis);

      IF l_log_id_offset IS NOT NULL THEN
        l_new_log_set_hsh(l_log_id_offset) := l_con_log_id;
      END IF;

  ELSIF l_event_type IN (PUT_LINE, PUT_LIST) THEN
    Do_Event_Put(
       p_event_type    => l_event_type,
       p_log_id        => l_log_id,
       p_line_rec      => l_line_rec,
       p_line_text_lis => p_line_text_lis);

  ELSIF l_event_type IN (OTHER_ERR, CLO) THEN
    Do_Event_Others(
            p_event_type => l_event_type,
            p_log_id     => l_log_id);
  END IF;

  RETURN l_new_log_set_hsh;
END Handle_Event;

/***************************************************************************************************

Do_Event_List: Process the list of events, returning the exception list if any

***************************************************************************************************/
FUNCTION Do_Event_List(
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
    l_log_set_hsh := Handle_Event(           
                        p_event_lis       => p_events_2lis(i),
                        p_con_prms_lis    => Get_Event_Prm_Lis(    p_event_no => l_event_no, 
                                                                   p_prm_2lis => p_con_prms_2lis),
                        p_put_prms_lis    => Get_Event_Prm_Lis(    p_event_no => l_event_no, 
                                                                   p_prm_2lis => p_put_prms_2lis),
                        p_line_text_lis   => Get_Event_Prm_Txt_Lis(p_event_no => l_event_no,  
                                                                   p_prm_2lis => p_txt_prms_2lis),
                        p_log_set_hsh     => l_log_set_hsh);
  END LOOP;
  RETURN NULL;

EXCEPTION

  WHEN CUSTOM_ERR_EX THEN
    RETURN L1_chr_arr(SQLERRM, DBMS_Utility.Format_Error_Backtrace);

END Do_Event_List;
  
/***************************************************************************************************

Purely_Wrap_API: Design pattern has the API call wrapped in a 'pure' procedure, called once per 
                 scenario, with the output 'actuals' array including everything affected by the API,
                 whether as output parameters, or on database tables, etc. The inputs are also
                 extended from the API parameters to include any other effective inputs. Assertion 
                 takes place after all scenarios and is against the extended outputs, with extended
                 inputs also listed. The API call is timed

***************************************************************************************************/
FUNCTION Purely_Wrap_API(p_last_seq_lgh         PLS_INTEGER,  -- last sequence value for log headers
                         p_last_seq_lcf         PLS_INTEGER,  -- last sequence value for log configs
                         p_inp_3lis             L3_chr_arr)   -- input list of lists (record, field)
                         RETURN                 L2_chr_arr IS -- output list of lists (group, record)

  l_log_config_lis               L1_chr_arr;
  l_act_2lis                     L2_chr_arr := L2_chr_arr();
  l_start_tmstp                  TIMESTAMP := SYSTIMESTAMP;
  l_start_cpu_cs                 PLS_INTEGER := DBMS_Utility.Get_CPU_Time;

BEGIN

  Log_Set.Init;
  l_log_config_lis := Add_Log_Configs(p_inp_3lis(1), p_inp_3lis(2)); -- lcf, ctx
  l_act_2lis.EXTEND(5);
  l_act_2lis(4) :=  Do_Event_List(
                      p_events_2lis     => p_inp_3lis(3),
                      p_con_prms_2lis   => p_inp_3lis(4),
                      p_put_prms_2lis   => p_inp_3lis(5),
                      p_txt_prms_2lis   => p_inp_3lis(6));

  l_act_2lis(1) := Get_Lgh_Lis(p_last_seq_lgh   => p_last_seq_lgh,
                               p_last_seq_lcf   => p_last_seq_lcf,
                               p_start_tmstp    => l_start_tmstp);
  l_act_2lis(2) := Get_Ctx_Lis(p_last_seq_lgh   => p_last_seq_lgh);
  l_act_2lis(3) := Get_Lgl_Lis(p_last_seq_lgh   => p_last_seq_lgh,
                               p_start_tmstp    => l_start_tmstp,
                               p_start_cpu_cs   => l_start_cpu_cs);
  l_act_2lis(5) := L1_chr_arr(Get_App_Info);
  ROLLBACK;
  Log_Set.Delete_Log(p_session_id => TT_Log_Set.SESSION_ID);
  
  IF l_log_config_lis IS NOT NULL THEN
  FOR i IN 1..l_log_config_lis.COUNT LOOP
      Log_Config.Del_Config(l_log_config_lis(i));
    END LOOP;
  END IF;
  COMMIT;

  RETURN l_act_2lis;
END Purely_Wrap_API;

/***************************************************************************************************

tt_Main: Entry point method for the unit test. Uses Utils_TT to read the test data from JSON clob
         into a 4-d list of (scenario, group, record, field), then calls a 'pure' wrapper function
         within a loop over the scenarios to get the actuals. A final call to Utils_TT.Set_Outputs
         creates the output JSON in tt_units as well as on file to be processed by trapit_nodejs

***************************************************************************************************/
PROCEDURE tt_Main IS

  PROC_NM                        CONSTANT VARCHAR2(30) := 'tt_Main';
  TIMER_SET_NM                   CONSTANT VARCHAR2(61) := $$PLSQL_UNIT || '.' || PROC_NM;

  l_act_3lis                     L3_chr_arr := L3_chr_arr();
  l_sces_4lis                    L4_chr_arr;
  l_timer_set                    VARCHAR2(100);
  l_last_seq_lgh                 PLS_INTEGER;
  l_last_seq_lcf                 PLS_INTEGER;
  l_def_config_id                PLS_INTEGER;

BEGIN

  l_timer_set := Utils_TT.Init(TIMER_SET_NM);
  l_sces_4lis := Utils_TT.Get_Inputs(p_package_nm    => $$PLSQL_UNIT,
                                     p_procedure_nm  => PROC_NM,
                                     p_timer_set     => l_timer_set);

  l_act_3lis.EXTEND(l_sces_4lis.COUNT);

  FOR i IN 1..l_sces_4lis.COUNT LOOP

    l_last_seq_lgh := log_headers_s.NEXTVAL;
    l_last_seq_lcf := log_configs_s.NEXTVAL;

    DBMS_Application_Info.Set_Module('', '');
    DBMS_Application_Info.Set_Client_Info('');
    l_act_3lis(i) := Purely_Wrap_API(l_last_seq_lgh, l_last_seq_lcf, l_sces_4lis(i));

  END LOOP;

  Utils_TT.Set_Outputs(p_package_nm    => $$PLSQL_UNIT,
                       p_procedure_nm  => PROC_NM,
                       p_act_3lis      => l_act_3lis,
                       p_timer_set     => l_timer_set);

END tt_Main;

END TT_Log_Set;
/
SHO ERR