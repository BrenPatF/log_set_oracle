# Log_Set
Oracle logging module.

The module is a framework for logging, consisting of 3 tables, 6 object types and 3 PL/SQL packages that support the writing of messages to log tables, along with various optional data items that may be specified as parameters or read at runtime via system calls.

The module is designed to be as simple as possible to use in default mode, while allowing for a high degree of configuration. A client program first constructs a log pointing to a configuration key, then puts lines to the log conditionally depending on the line minimum put level being at least equal to the configuration put level. By creating new versions of the keyed configuration the amount and type of information put can be varied without code changes, to support production debugging and analysis.

Multiple logs can be processed simultaneously within and across sessions without interference.

In order to maximise performance, puts may be buffered, and only the log header uses an Oracle sequence for its unique identifier, with lines being numbered sequentially in PL/SQL.

The package is tested using the Math Function Unit Testing design pattern, with test results in HTML and text format included. See test_output\log_set.html for the unit test results root page.

## Usage (extract from main_col_group.sql)
```sql
DECLARE
  l_log_id               PLS_INTEGER := Log_Set.Construct;
  l_res_arr              chr_int_arr;

BEGIN

  Col_Group.Load_File(p_file   => 'fantasy_premier_league_player_stats.csv', 
                      p_delim  => ',',
                      p_colnum => 7);
  l_res_arr := Col_Group.List_Asis;
  Log_Set.Put_List(p_line_lis => Utils.Heading('As Is'));
  Log_Set.Put_List(p_line_lis => Utils.Col_Headers(p_value_lis => chr_int_arr(chr_int_rec('Team', 30), 
                                                                              chr_int_rec('Apps', -5)
  )));
  FOR i IN 1..l_res_arr.COUNT LOOP
    Log_Set.Put_Line(p_line_text => Utils.List_To_Line(
                     p_value_lis => chr_int_arr(chr_int_rec(l_res_arr(i).chr_value, 30), 
                                                chr_int_rec(l_res_arr(i).int_value, -5)
    )));
  END LOOP;
--  Log_Set.Raise_Error(p_err_msg => 'Example custom error raising');
  RAISE NO_DATA_FOUND; -- Example of unexpected error handling in others

EXCEPTION
  WHEN OTHERS THEN
    Log_Set.Write_Other_Error;
    RAISE;
END;
/
PROMPT Normal lines
SELECT line_num lno, line_text text
  FROM log_lines
 WHERE log_id = (SELECT MAX(h.id) FROM log_headers h)
   AND line_type IS NULL
 ORDER BY line_num
/
PROMPT Errors
SELECT line_num lno, err_msg, error_backtrace
  FROM log_lines
 WHERE log_id = (SELECT MAX(h.id) FROM log_headers h)
   AND line_type = 'ERROR'
 ORDER BY line_num
/

```
This will create a log of the results from the example program, with listing at the end:
```
Normal lines

   1 As Is
   2 =====
   3 Team                             Apps
   4 ------------------------------  -----
   5 team_name_2                         1
   6 Blackburn                          33
...
  29 Reading                          1167

Errors

  30 ORA-01403: no data found       ORA-06512: at line 23
```
To run the example in a slqplus session from app subfolder (after installation):

SQL> @main_col_group

There is also a separate [module](https://github.com/BrenPatF/oracle_plsql_api_demos) demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs.

## API - Log_Set
There are several versions of the log constructor function, and of the log put methods, and calls are simplified by the use of two record types to group parameters, for which constructor functions are included. The parameters of these types have default records and so can be omitted, as in the example calls above. Field defaults are mentioned below where not null.

All commits are through autonomous transactions.

### l_con_rec Log_Set.con_rec := Log_Set.Con_Construct_Rec(`optional parameters`)
Returns a record to be passed to a Construct function, with parameters as follows (all optional):

* `p_config_key`: references configuration in log_configs table, of which there should be one active version
* `p_description`: log description
* `p_put_lev_min`: minimum put level: Log not put if the put_lev in log_configs is lower; defaults to 0
* `p_do_close`: boolean, True if the log is to be closed immediately; defaults to False

### l_line_rec Log_Set.line_rec := Log_Set.Con_Line_Rec(`optional parameters`)
Returns a record to be passed to a method that puts lines, with parameters as follows (all optional):

* `p_line_type`: log line type, eg 'ERROR' etc., not validated
* `p_plsql_unit`: PL/SQL package name, as given by $$PLSQL_UNIT
* `p_plsql_line`: PL/SQL line number, as given by $$PLSQL_LINE
* `p_group_text`: free text that can be used to group lines
* `p_action`: action that can be used as the action in DBMS_Application_Info.Set_Action, and logged with a line
* `p_put_lev_min`: minimum put level: Log line not put if the put_lev in log_configs is lower; also affects individual fields that have their own level, eg put_lev_stack; defaults to 0
* `p_err_num`: error number when passed explicitly, also set to SQLCODE by Write_Other_Error
* `p_err_msg`: error message when passed explicitly, also set to SQLERRM by Write_Other_Error
* `p_call_stack`: call stack set by Write_Other_Error using DBMS_Utility.Format_Call_Stack
* `p_error_backtrace`: error backtrace set by Write_Other_Error using DBMS_Utility.Format_Error_Backtrace
* `p_do_close`: boolean, True if the log is to be closed after writing line or list of lines; defaults to False

### l_log_id   PLS_INTEGER := Log_Set.Construct(`optional parameters`)
Constructs a new log with integer handle `l_log_id`.

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.line_rec, as defined above, default CONSTRUCT_DEF

### l_log_id   PLS_INTEGER := Log_Set.Construct(p_line_text, `optional parameters`)
Constructs a new log with integer handle `l_log_id`, passing line of text to be put to the new log.

* `p_line_text`: line of text to put

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.line_rec, as defined above, default CONSTRUCT_DEF
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### l_log_id   PLS_INTEGER := Log_Set.Construct(p_line_lis, `optional parameters`)
Constructs a new log with integer handle `l_log_id`, passing a list of lines of text to be put to the new log.

* `p_line_lis`: list of lines of text to put, of type L1_chr_arr

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.con_rec, as defined above, default CONSTRUCT_DEF
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Put_Line(p_line_text, `optional parameters`)
Writes a line of text to the new log.

* `p_line_text`: line of text to put

Optional parameters:
* `p_log_id`: id of log to put to; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Put_List(p_line_lis, `optional parameters`)
Writes a list of lines of text to the new log.

* `p_line_lis`: list of lines of text to put, of type L1_chr_arr

Optional parameters:
* `p_log_id`: id of log to put to; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Close_Log(`optional parameters`)
Closes a log, after saving any unsaved buffer lines.

Optional parameters:
* `p_log_id`: id of log to close; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used

### Log_Set.Raise_Error(p_err_msg, `optional parameters`)
Raises an error via Oracle procedure RAISE_APPLICATION_ERROR, first writing the message to a log, if the log id is passed.

* `p_err_msg`: error message

Optional parameters:
* `p_log_id`: id of log to put to
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF
* `p_do_close`: boolean, True if the log is to be closed after writing error details; default  True

### Log_Set.Write_Other_Error(`optional parameters`)
Raises an error via Oracle procedure RAISE_APPLICATION_ERROR, first writing the message to a log, if the log id is passed, and using p_line_rec.err_msg as the message.

Optional parameters:
* `p_log_id`: id of log to put to
* `p_line_text`: line of text to put, default null
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF
* `p_do_close`: boolean, True if the log is to be closed after writing error details; defaults to True

### Log_Set.Delete_Log(p_log_id, p_session_id)
Deletes all logs matching either a single log id or a session id which may have multiple logs. Exactly one parameter must be passed. This uses an autonomous transaction.

* `p_log_id`: id of log to delete
* `p_session_id`: session id of logs to delete

## API - Log_Config
This package allows for select, update, insertion, and deletion of the configuration records, with no commits.

### Log_Config.Set_Default_Config(p_config_key)
Sets a record in the log_configs table to be the default config.

* `p_config_key`: references configuration in log_configs table, of which there should be one active version

### l_config_key log_configs.config_key%TYPE := Log_Config.Get_Default_Config
Gets the config key for the default config in the log_configs table.

### l_config log_configs%ROWTYPE := Log_Config.Get_Config(p_config_key)
Gets the config record in the log_configs table for the config key passed.

* `p_config_key`: references configuration in log_configs table, of which there should be one active version

### Log_Config.Del_Config(p_config_key)
Deletes the currently active record in the log_configs table for the config key passed, activating any most recent prior record.

* `p_config_key`: references configuration in log_configs table, of which there should be one active version

### Log_Config.Ins_Config(`optional parameters`)
Inserts a new record in the log_configs table. If the config_key already exists, a new active version will be inserted with the old version de-activated. 

One of the columns in the table is of a custom array type, ctx_inp_arr. This is an array of objects of type ctx_inp_obj, which contain information on possible writing of system contexts in the USERENV namespace [Oracle SYS_CONTEXT](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/sqlrf/SYS_CONTEXT.html#GUID-B9934A5D-D97B-4E51-B01B-80C76A5BD086). The object type has fields as follows:
        
 * `ctx_nm`: context name
 * `put_lev`: put level for the context; if header/line is put, the minimum header/line put level is compared to this for writing the context value
 * `head_line_fg`: put for 'H' - header only, 'L' - line only, 'B' - both header and line

An entry in the array should be added for each context desired.

All parameters are optional, with null defaults except where mentioned:

* `p_config_key`: references configuration in log_configs table, of which there should be one active version
* `p_config_type`: configuration type; if new version, takes same as previous version if not passed
* `p_default_yn`: if 'Y' config is default
* `p_singleton_yn`: if 'Y' designates a `singleton` configuration, meaning only a single log with this setting can be active at a time, and the log id is stored internally, so can be omitted from the put and close methods
* `p_description`: log description; if new version, takes same as previous version if not passed
* `p_put_lev`: put level, default 10; minimum put levels at header and line level are compared to this
* `p_put_lev_stack`: put level for call stack; if line is put, the minimum line put level is compared to this for writing the call stack field
* `p_put_lev_cpu`:  put level for CPU time; if line is put, the minimum line put level is compared to this for writing the CPU time field
* `p_ctx_inp_lis`: list of contexts to put depending on the put levels specified
* `p_put_lev_module`:  put level for module; if line is put, the minimum line put level is compared to this for writing the module field
* `p_put_lev_action`:  put level for action; if line is put, the minimum line put level is compared to this for writing the action field
* `p_put_lev_client_info`:  put level for client info; if line is put, the minimum line put level is compared to this for writing the client info field
* `p_app_info_only_yn`: if 'Y' do not put to table, but set application info only
* `p_buff_len`: number of lines that are stored before saving to table; default 100
* `p_extend_len`: number of elements to extend the buffer by when needed; default 100

## Installation
The install depends on the pre-requisite modules Utils and Trapit (unit testing only) and `lib` and `app` schemas refer to the schemas in which Utils and examples are installed, respectively.

### Install 1: Install pre-requisite modules
The pre-requisite modules can be installed by following the instructions at [Utils on GitHub](https://github.com/BrenPatF/oracle_plsql_utils). This allows inclusion of the examples and unit tests for the modules. Alternatively, the next section shows how to install the modules directly without their examples or unit tests here (but with the Trapit module required for unit testing the Log_Set module).

#### [Schema: sys; Folder: install_prereq] Create lib and app schemas and Oracle directory
- install_sys.sql creates an Oracle directory, `input_dir`, pointing to 'c:\input'. Update this if necessary to a folder on the database server with read/write access for the Oracle OS user
- Run script from slqplus:
```
SQL> @install_sys
```

#### [Folder: install_prereq] Copy example csv file to input folder
- Copy the following file from the install_prereq folder to the server folder pointed to by the Oracle directory INPUT_DIR:
    - fantasy_premier_league_player_stats.csv

- There is also a bash script to do this, assuming C:\input as INPUT_DIR:
```
$ ./cp_csv_to_input.ksh
```

#### [Schema: lib; Folder: install_prereq\lib] Create lib components
- Run script from slqplus:
```
SQL> @install_lib_all
```
#### [Schema: app; Folder: install_prereq\app] Create app synonyms and install example package
- Run script from slqplus:
```
SQL> @install_app_all
```
#### [Folder: (npm root)] Install npm trapit package
The npm trapit package is a nodejs package used to format unit test results as HTML pages.

Open a DOS or Powershell window in the folder where you want to install npm packages, and, with [nodejs](https://nodejs.org/en/download/) installed, run
```
$ npm install trapit
```
This should install the trapit nodejs package in a subfolder .\node_modules\trapit

### Install 2: Create Log_Set components
#### [Schema: lib; Folder: lib]
- Run script from slqplus:
```
SQL> @install_log_set app
```
This creates the required components for the base install along with grants for them to the app schema (passing none instead of app will bypass the grants). This install is all that is required to use the package within the lib schema and app (if passed, and then Install 3 is required). To grant privileges to another `schema`, run the grants script directly, passing `schema`:
```
SQL> @grant_log_set_to_app schema
```

### Install 3: Create synonyms to lib
#### [Schema: app; Folder: app]
- Run script from slqplus:
```
SQL> @c_log_set_syns lib
```
This install creates private synonyms to the lib schema. To create synonyms within another schema, run the synonyms script directly from that schema, passing lib schema.

### Install 4: Install unit test code
This step requires the Trapit module option to have been installed as part of Install 1.

#### [Folder: (module root)] Copy unit test JSON file to input folder
- Copy the following file from the root folder to the server folder pointed to by the Oracle directory INPUT_DIR:
  - tt_log_set.test_api_inp.json

- There is also a bash script to do this, assuming C:\input as INPUT_DIR:
```
$ ./cp_json_to_input.ksh
```

#### [Schema: lib; Folder: lib] Install unit test code
- Run script from slqplus:
```
SQL> @install_log_set_tt
```

## Unit testing
The unit test program (if installed) may be run from the lib subfolder:

SQL> @r_tests

The program is data-driven from the input file tt_log_set.test_api_inp.json and produces an output file tt_log_set.test_api_out.json, that contains arrays of expected and actual records by group and scenario.

The output file is processed by a nodejs program that has to be installed separately from the `npm` nodejs repository, as described in the Trapit install in `Install 1` above. The nodejs program produces listings of the results in HTML and/or text format, and a sample set of listings is included in the subfolder test_output. To run the processor (in Windows), open a DOS or Powershell window in the trapit package folder after placing the output JSON file, tt_log_set.test_api_out.json, in the subfolder ./examples/externals and run:
```
$ node ./examples/externals/test-externals
```
The three testing steps can easily be automated in Powershell (or Unix bash).

The package is tested using the Math Function Unit Testing design pattern (`See also - Trapit` below). In this approach, a 'pure' wrapper function is constructed that takes input parameters and returns a value, and is tested within a loop over scenario records read from a JSON file.

The wrapper function represents a generalised transactional use of the package in which multiple logs may be constructed, and put to independently. 

This is a good example of the power of the design pattern that I recently introduced, and is a second example, after `See also - Timer_Set` below, of unit testing where the 'unit' is taken to be a full generalised transaction, from start to finish of a logging (or timing) session.

You can review the  unit test formatted results obtained by the author in the `test_output` subfolder [log_set.html is the root page for the HTML version and log_set.txt has the results in text format].

## Operating System/Oracle Versions
### Windows
Windows 10, should be OS-independent
### Oracle
- Tested on Oracle Database Version 18.3.0.0.0
- Base code (and example) should work on earlier versions at least as far back as v11

## See also
- [Utils - Oracle PL/SQL general utilities module](https://github.com/BrenPatF/oracle_plsql_utils)
- [Trapit - Oracle PL/SQL unit testing module](https://github.com/BrenPatF/trapit_oracle_tester)
- [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle)
- [Trapit - nodejs unit test processing package](https://github.com/BrenPatF/trapit_nodejs_tester)
- [Oracle PL/SQL API Demos - demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs](https://github.com/BrenPatF/oracle_plsql_api_demos)

## License
MIT