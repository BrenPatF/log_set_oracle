CREATE OR REPLACE PACKAGE BODY Utils_TT AS
/***************************************************************************************************
Name: Utils_TT.pkb                     Author: Brendan Furey                       Date: 29-Jan-2019

Package body component in the Oracle timer_set_oracle module. This module facilitates code timing
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

This file has the unit test utility, Utils_TT, package body (lib schema). Note that the test package
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

g_input_data            CLOB;
g_json                  JSON_Object_T;

g_log_sequence_id       PLS_INTEGER;

/***************************************************************************************************

Init: TRAPIT initialise for a procedure by constructing timer set, then writing heading,
      and returning the timer set id

***************************************************************************************************/
FUNCTION Init (p_proc_name      VARCHAR2)      -- calling procedure name
               RETURN           PLS_INTEGER IS -- timer set id

  l_timer_set   PLS_INTEGER := Timer_Set.Construct(p_proc_name);

BEGIN

--  Utils.Write_Log(Utils.Heading('TRAPIT TEST: ' || p_proc_name));
  RETURN l_timer_set;

END Init;

/***************************************************************************************************

Get_View: TRAPIT utility to run a query dynamically on a view and return result set as array of strings

***************************************************************************************************/
FUNCTION Get_View (p_view_name         VARCHAR2,               -- name of view
                   p_sel_field_lis     L1_chr_arr,             -- list of fields to select
                   p_where             VARCHAR2 DEFAULT NULL,  -- optional where clause
                   p_timer_set         PLS_INTEGER)            -- timer set handle
                   RETURN              L1_chr_arr IS           -- list of delimited result records

  l_cur            SYS_REFCURSOR;
  l_sql_txt        VARCHAR2(32767) := 'SELECT Utils.List_Delim (L1_chr_arr (';
  l_result_lis     L1_chr_arr;
  l_len            PLS_INTEGER;

BEGIN

  FOR i IN 1..p_sel_field_lis.COUNT LOOP

    l_sql_txt := l_sql_txt || p_sel_field_lis(i) || ',';

  END LOOP;

  l_sql_txt := RTrim (l_sql_txt, ',') || ')) FROM ' || p_view_name || ' WHERE ' || Nvl (p_where, '1=1 ') || 'ORDER BY 1';

  OPEN l_cur FOR l_sql_txt;

  FETCH l_cur BULK COLLECT -- ut, small result set, hence no need for limit clause
   INTO l_result_lis;

  CLOSE l_cur;

  Timer_Set.Increment_Time (p_timer_set, c_call_timer);
  ROLLBACK;
  RETURN l_result_lis;

END Get_View;

/***************************************************************************************************

Run_Suite: Run a TRAPIT suite

***************************************************************************************************/
PROCEDURE Run_Suite IS

  TYPE tt_units_arr IS VARRAY(1000) OF tt_units%ROWTYPE;
  l_tt_units_lis    tt_units_arr;
  PROCEDURE Run_TT_Package (p_package_proc_nm VARCHAR2) IS
  BEGIN

    EXECUTE IMMEDIATE 'BEGIN ' || p_package_proc_nm || '; END;';

  END Run_TT_Package;

BEGIN

  SELECT *
    BULK COLLECT INTO l_tt_units_lis
    FROM tt_units
  WHERE active_yn = 'Y';
  FOR i IN 1..l_tt_units_lis.COUNT LOOP

    Run_TT_Package (l_tt_units_lis(i).package_nm || '.' ||  l_tt_units_lis(i).procedure_nm);
    COMMIT;

  END LOOP;

END Run_Suite;

/***************************************************************************************************

Cursor_to_Array: Takes an open ref cursor, reads from it and returns the output records as a list of
                 delimited strings. If a filter is passed, then only strings matching it (with
                 enclosing wildcards) are returned. Cursor is closed at the end

***************************************************************************************************/
FUNCTION Cursor_to_Array (x_csr         IN OUT SYS_REFCURSOR,         -- (open) ref cursor
                          p_filter             VARCHAR2 DEFAULT NULL) -- filter string
                          RETURN               L1_chr_arr IS          -- list of delimited strings

  c_chr_type    CONSTANT PLS_INTEGER := 1; --DBMS_Types.TYPECODE_* do not seem to quite work
  c_num_type    CONSTANT PLS_INTEGER := 2;
  c_dat_type    CONSTANT PLS_INTEGER := 12;
  c_stp_type    CONSTANT PLS_INTEGER := 180;
  l_csr_id      PLS_INTEGER;
  l_n_cols      PLS_INTEGER;
  l_desctab     DBMS_SQL.DESC_TAB;
  l_chr_val     VARCHAR2(4000);
  l_num_val     NUMBER;
  l_dat_val     DATE;
  l_stp_val     TIMESTAMP;
  l_val_lis     L1_chr_arr;
  l_res_lis     L1_chr_arr := L1_chr_arr();
  l_rec         VARCHAR2(4000);

BEGIN

  l_csr_id := DBMS_SQL.To_Cursor_Number (x_csr);
  DBMS_SQL.Describe_Columns (l_csr_id, l_n_cols, l_desctab);

  FOR i IN 1..l_n_cols LOOP

    CASE l_desctab(i).col_type

      WHEN c_chr_type THEN
        DBMS_SQL.Define_Column (l_csr_id, i, l_chr_val, 4000);
      WHEN c_num_type THEN
        DBMS_SQL.Define_Column (l_csr_id, i, l_num_val);
      WHEN c_dat_type THEN
        DBMS_SQL.Define_Column (l_csr_id, i, l_dat_val);
      WHEN c_stp_type THEN
         DBMS_SQL.Define_Column (l_csr_id, i, l_stp_val);
     ELSE
        Utils.Raise_Error('Cursor_to_Array: Col type ' || l_desctab(i).col_type || 
          ' not accounted for!');

    END CASE;

  END LOOP;

  WHILE DBMS_SQL.Fetch_Rows (l_csr_id) > 0 LOOP

    l_val_lis := L1_chr_arr();
    l_val_lis.EXTEND (l_n_cols);
    FOR i IN 1 .. l_n_cols LOOP

      CASE l_desctab(i).col_type

        WHEN c_chr_type THEN
          DBMS_SQL.Column_Value (l_csr_id, i, l_chr_val);
          l_val_lis(i) := l_chr_val;
        WHEN c_num_type THEN
          DBMS_SQL.Column_Value (l_csr_id, i, l_num_val);
          l_val_lis(i) := l_num_val;
        WHEN c_dat_type THEN
          DBMS_SQL.Column_Value (l_csr_id, i, l_dat_val);
          l_val_lis(i) := l_dat_val;
        WHEN c_stp_type THEN
          DBMS_SQL.Column_Value (l_csr_id, i, l_stp_val);
          l_val_lis(i) := l_stp_val;

      END CASE;

    END LOOP;

    l_rec := Utils.List_Delim (l_val_lis);
    IF l_rec LIKE '%' || p_filter || '%' THEN
      l_res_lis.EXTEND;
      l_res_lis (l_res_lis.COUNT) := l_rec;
    END IF;

  END LOOP;

  DBMS_SQL.Close_Cursor (l_csr_id);
  RETURN l_res_lis;

END Cursor_to_Array;

/***************************************************************************************************

Get_Inputs: Gets the input JSON scenarios object from table, and converts it into a 4-level list of
  lists, with levels as follows:
  - Scenario
  - Group
  - Record
  - Field
Requires Oracle database 12.2 or higher

***************************************************************************************************/
FUNCTION Get_Inputs(p_package_nm     VARCHAR2,     -- package name
                    p_procedure_nm   VARCHAR2,     -- procedure name
                    p_timer_set      PLS_INTEGER)  -- timer set id
                    RETURN           L4_chr_arr IS -- scenarios as 4-level list of lists
  je                      JSON_Element_T;
  l_sce_obj               JSON_Object_T;
  l_rec_list              JSON_Array_T;
  l_keys                  JSON_Key_List;
  l_groups                JSON_Key_List;
  l_recs_2lis             L2_chr_arr := L2_chr_arr();
  l_grps_3lis             L3_chr_arr := L3_chr_arr();
  l_sces_4lis             L4_chr_arr := L4_chr_arr();
  Invalid_JSON            EXCEPTION;
BEGIN

  SELECT input_data
    INTO g_input_data
    FROM tt_units
   WHERE package_nm     = p_package_nm
     AND procedure_nm   = p_procedure_nm;

  je := JSON_Element_T.parse(g_input_data);
  IF NOT je.is_Object THEN
    Utils.Raise_Error('Invalid JSON');
  END IF;

  g_json := treat(je AS JSON_Object_T);
  l_sce_obj := g_json.get_Object('scenarios');
  l_keys := l_sce_obj.get_keys;
  l_sces_4lis.EXTEND(l_keys.COUNT);
  FOR i IN 1..l_keys.COUNT LOOP
    l_groups := l_sce_obj.get_Object(l_keys(i)).get_Object('inp').get_keys;
    l_grps_3lis := L3_chr_arr();
    l_grps_3lis.EXTEND(l_groups.COUNT);
    FOR j IN 1..l_groups.COUNT LOOP
      l_rec_list := l_sce_obj.get_Object(l_keys(i)).get_Object('inp').get_Array(l_groups(j));
      l_recs_2lis := L2_chr_arr();
      l_recs_2lis.EXTEND(l_rec_list.get_Size);
      FOR k IN 0..l_rec_list.get_Size-1 LOOP
        l_recs_2lis(k + 1) := Utils.Csv_To_Lis(l_rec_list.get_string(k));
      END LOOP;
      l_grps_3lis(j) := l_recs_2lis;
    END LOOP;
    l_sces_4lis(i) := l_grps_3lis;
  END LOOP;
  Timer_Set.Increment_Time (P_timer_set, 'Get Inputs');

  RETURN l_sces_4lis;

END Get_Inputs;

/***************************************************************************************************

Set_Outputs: Gets the input JSON scenarios object from table, and converts it into a 3-level list of
  lists, with levels as follows:
  - Scenario
  - Group
  - Record (with fields as delimited strings)
Requires Oracle database 12.2 or higher

***************************************************************************************************/
PROCEDURE Set_Outputs(p_package_nm     VARCHAR2,       -- package name
                      p_procedure_nm   VARCHAR2,       -- procedure name
                      p_act_3lis       L3_chr_arr,     -- actuals as 3-level list of lists
                      p_timer_set      PLS_INTEGER) IS -- timer set id
  l_out_obj               JSON_Object_T := JSON_Object_T();
  l_scenarios_out_obj     JSON_Object_T := JSON_Object_T();
  l_out_sce_obj           JSON_Object_T;
  l_scenario_out_obj      JSON_Object_T;
  l_sce_obj               JSON_Object_T;
  l_result_obj            JSON_Object_T;
  l_grp_out_obj           JSON_Object_T;
  l_exp_list              JSON_Array_T;
  l_act_list              JSON_Array_T;
  l_scenarios             JSON_Key_List;
  l_groups                JSON_Key_List;
  l_out_clob              CLOB;

BEGIN

  l_out_obj.put('meta', g_json.get_Object('meta'));
  l_sce_obj := g_json.get_Object('scenarios');
  l_scenarios := l_sce_obj.get_keys;
  FOR i IN 1..l_scenarios.COUNT LOOP
    l_scenario_out_obj := JSON_Object_T();
    l_scenario_out_obj.put('inp', l_sce_obj.get_Object(l_scenarios(i)).get_Object('inp'));
    l_groups := l_sce_obj.get_Object(l_scenarios(i)).get_Object('out').get_keys;
    l_grp_out_obj := JSON_Object_T();
    FOR j IN 1..l_groups.COUNT LOOP

      l_exp_list := l_sce_obj.get_Object(l_scenarios(i)).get_Object('out').get_Array(l_groups(j));
      l_act_list := JSON_Array_T();
      IF p_act_3lis(i)(j) IS NOT NULL THEN
        FOR k IN 1..p_act_3lis(i)(j).COUNT LOOP
          l_act_list.Append(p_act_3lis(i)(j)(k));
        END LOOP;
      END IF;
      l_result_obj := JSON_Object_T();
      l_result_obj.Put('exp', l_exp_list);
      l_result_obj.Put('act', l_act_list);
      l_grp_out_obj.Put(l_groups(j), l_result_obj);
    END LOOP;
    l_scenario_out_obj.put('out', l_grp_out_obj);
    l_scenarios_out_obj.put(l_scenarios(i), l_scenario_out_obj);
  END LOOP;
  l_out_obj.put('scenarios', l_scenarios_out_obj);

  Timer_Set.Increment_Time(p_timer_set, 'Set Output CLOB');
  l_out_clob := l_out_obj.to_clob();
  UPDATE tt_units
     SET output_data    = l_out_clob
   WHERE package_nm     = p_package_nm
     AND procedure_nm   = p_procedure_nm;
  DBMS_XSLPROCESSOR.clob2file(l_out_clob, 'INPUT_DIR', Lower(p_package_nm || '.' || p_procedure_nm) || '_out.json');
  Timer_Set.Increment_Time(p_timer_set, 'Output CLOB to table/file');
--  Utils.Write_Log(Timer_Set.Format_Results(p_timer_set));

END Set_Outputs;
/***************************************************************************************************

Add_Ttu: Add a record to tt_units, reading in input_data from JSON file

***************************************************************************************************/

PROCEDURE Add_Ttu(p_package_nm      VARCHAR2,    -- test package name 
                  p_procedure_nm    VARCHAR2,    -- test procedure name 
                  p_active_yn       VARCHAR2,    -- test active Y/N
                  p_input_file      VARCHAR2) IS -- input file name

  l_src_file      BFILE := BFileName('INPUT_DIR', p_input_file);
  l_dest_lob      CLOB;
  l_dest_offset   INTEGER := 1;
  l_src_offset    INTEGER := 1;
  l_lang_context  NUMBER := DBMS_LOB.Default_Lang_Ctx;
  l_warning       NUMBER;

BEGIN

  DBMS_LOB.CreateTemporary(l_dest_lob,true);

  DBMS_LOB.Open(l_src_file, DBMS_LOB.Lob_readonly);
  DBMS_LOB.LoadCLOBFromFile( 
              dest_lob     => l_dest_lob,
              src_bfile    => l_src_file,
              amount       => DBMS_LOB.LOBMAXSIZE,
              dest_offset  => l_dest_offset,
              src_offset   => l_src_offset,
              bfile_csid   => DBMS_LOB.Default_Csid,
              lang_context => l_lang_context,
              warning      => l_warning );

  INSERT INTO tt_units (package_nm, procedure_nm, active_yn, input_data)
  VALUES (p_package_nm, p_procedure_nm, p_active_yn, l_dest_lob);
  COMMIT;
  DBMS_LOB.FreeTemporary(l_dest_lob);
  DBMS_LOB.Close(l_src_file);

END Add_Ttu;

/***************************************************************************************************

Sleep: Custom sleep for testing, with CPU content, using DBMS_Lock.Sleep for the non-CPU part

***************************************************************************************************/
PROCEDURE Sleep(p_ela_seconds     NUMBER,           -- elapsed time to sleep
                p_fraction_CPU    NUMBER := 0.5) IS -- fraction of elapsed time to use CPU
  l_ela_start TIMESTAMP := SYSTIMESTAMP;
BEGIN

  WHILE SYSTIMESTAMP < l_ela_start + NumToDSInterval(p_fraction_CPU * p_ela_seconds, 'second') LOOP

    NULL;

  END LOOP;
  DBMS_Lock.Sleep((1 - p_fraction_CPU) * p_ela_seconds);

END Sleep;

BEGIN

  DBMS_Application_Info.Set_Client_Info (client_info => 'TT');
  Utils.c_session_id_if_TT := SYS_Context ('userenv', 'sessionid');
  DBMS_Session.Set_NLS('nls_date_format', '''DD-MON-YYYY''');--c_date_fmt); - constant did not work

END Utils_TT;
/
SHO ERR
