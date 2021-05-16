# Log_Set
<img src="mountains.png">
Oracle logging module.

:memo:

The module is a framework for logging, consisting of 3 tables, 6 object types and 3 PL/SQL packages that support the writing of messages to log tables (and/or the Application Info views), along with various optional data items that may be specified as parameters or read at runtime via system calls.

The module is designed to be as simple as possible to use in default mode, while allowing for a high degree of configuration. A client program first constructs a log pointing to a configuration key, then puts lines to the log conditionally depending on the line minimum put level being at least equal to the configuration put level. By creating new versions of the keyed configuration the amount and type of information put can be varied without code changes, to support production debugging and analysis.

Multiple logs can be processed simultaneously within and across sessions without interference.

In order to maximise performance, puts may be buffered, and only the log header uses an Oracle sequence for its unique identifier, with lines being numbered sequentially in PL/SQL.

The package is tested using the Math Function Unit Testing design pattern, with test results in HTML and text format included. See test_data\test_output for the unit test results folder.

## In this README...
- [Usage (extract from main_col_group.sql)](https://github.com/BrenPatF/log_set_oracle#usage-extract-from-main_col_groupsql)
- [API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)
- [API - Log_Config](https://github.com/BrenPatF/log_set_oracle#api---log_config)
- [Installation](https://github.com/BrenPatF/log_set_oracle#installation)
- [Unit Testing](https://github.com/BrenPatF/log_set_oracle#unit-testing)
- [Operating System/Oracle Versions](https://github.com/BrenPatF/log_set_oracle#operating-systemoracle-versions)

## Usage (extract from main_col_group.sql)
- [&uarr; In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)

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
- [&uarr; In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)
- [Con_Construct_Rec(optional parameters)](https://github.com/BrenPatF/log_set_oracle#l_con_rec-log_setcon_rec--log_setcon_construct_recoptional-parameters)
- [Con_Line_Rec(optional parameters)](https://github.com/BrenPatF/log_set_oracle#l_line_rec-log_setline_rec--log_setcon_line_recoptional-parameters)
- [Construct(optional parameters)](https://github.com/BrenPatF/log_set_oracle#l_log_id---pls_integer--log_setconstructoptional-parameters)
- [Construct(p_line_text, optional parameters)](https://github.com/BrenPatF/log_set_oracle#l_log_id---pls_integer--log_setconstructp_line_text-optional-parameters)
- [Construct(p_line_lis, optional parameters)](https://github.com/BrenPatF/log_set_oracle#l_log_id---pls_integer--log_setconstructp_line_lis-optional-parameters)
- [Put_Line(p_line_text, optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_setput_linep_line_text-optional-parameters)
- [Put_List(p_line_lis, optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_setput_listp_line_lis-optional-parameters)
- [Close_Log(optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_setclose_logoptional-parameters)
- [Raise_Error(p_err_msg, optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_setraise_errorp_err_msg-optional-parameters)
- [Write_Other_Error(optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_setwrite_other_erroroptional-parameters)
- [Delete_Log(p_log_id, p_session_id](https://github.com/BrenPatF/log_set_oracle#log_setdelete_logp_log_id-p_session_id)

There are several versions of the log constructor function, and of the log put methods, and calls are simplified by the use of two record types to group parameters, for which constructor functions are included. The parameters of these types have default records and so can be omitted, as in the example calls above. Field defaults are mentioned below where not null.

All commits are through autonomous transactions.

### l_con_rec Log_Set.con_rec := Log_Set.Con_Construct_Rec(`optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Returns a record to be passed to a Construct function, with parameters as follows (all optional):

* `p_config_key`: references configuration in log_configs table, of which there should be one active version
* `p_description`: log description
* `p_put_lev_min`: minimum put level: Log not put if the put_lev in log_configs is lower; defaults to 0
* `p_do_close`: boolean, True if the log is to be closed immediately; defaults to False

### l_line_rec Log_Set.line_rec := Log_Set.Con_Line_Rec(`optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

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
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Constructs a new log with integer handle `l_log_id`.

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.line_rec, as defined above, default CONSTRUCT_DEF

### l_log_id   PLS_INTEGER := Log_Set.Construct(p_line_text, `optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Constructs a new log with integer handle `l_log_id`, passing line of text to be put to the new log.

* `p_line_text`: line of text to put

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.line_rec, as defined above, default CONSTRUCT_DEF
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### l_log_id   PLS_INTEGER := Log_Set.Construct(p_line_lis, `optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Constructs a new log with integer handle `l_log_id`, passing a list of lines of text to be put to the new log.

* `p_line_lis`: list of lines of text to put, of type L1_chr_arr

Optional parameters:
* `p_construct_rec`: construct parameters record of type Log_Set.con_rec, as defined above, default CONSTRUCT_DEF
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Put_Line(p_line_text, `optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Writes a line of text to the new log.

* `p_line_text`: line of text to put

Optional parameters:
* `p_log_id`: id of log to put to; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Put_List(p_line_lis, `optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Writes a list of lines of text to the new log.

* `p_line_lis`: list of lines of text to put, of type L1_chr_arr

Optional parameters:
* `p_log_id`: id of log to put to; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF

### Log_Set.Close_Log(`optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Closes a log, after saving any unsaved buffer lines.

Optional parameters:
* `p_log_id`: id of log to close; if omitted, a single log with config value of singleton_yn = 'Y' must have been constructed, and that log will be used

### Log_Set.Raise_Error(p_err_msg, `optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Raises an error via Oracle procedure RAISE_APPLICATION_ERROR, first writing the message to a log, if the log id is passed.

* `p_err_msg`: error message

Optional parameters:
* `p_log_id`: id of log to put to
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF
* `p_do_close`: boolean, True if the log is to be closed after writing error details; default  True

### Log_Set.Write_Other_Error(`optional parameters`)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Raises an error via Oracle procedure RAISE_APPLICATION_ERROR, first writing the message to a log, if the log id is passed, and using p_line_rec.err_msg as the message.

Optional parameters:
* `p_log_id`: id of log to put to
* `p_line_text`: line of text to put, default null
* `p_line_rec`: line parameters record of type Log_Set.line_rec, as defined above, default LINE_DEF
* `p_do_close`: boolean, True if the log is to be closed after writing error details; defaults to True

### Log_Set.Delete_Log(p_log_id, p_session_id)
- [&uarr; API - Log_Set](https://github.com/BrenPatF/log_set_oracle#api---log_set)

Deletes all logs matching either a single log id or a session id which may have multiple logs. Exactly one parameter must be passed. This uses an autonomous transaction.

* `p_log_id`: id of log to delete
* `p_session_id`: session id of logs to delete

## API - Log_Config
- [&uarr; In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)
- [Set_Default_Config(p_config_key)](https://github.com/BrenPatF/log_set_oracle#log_configset_default_configp_config_key)
- [Get_Default_Config](https://github.com/BrenPatF/log_set_oracle#l_config_key-log_configsconfig_keytype--log_configget_default_config)
- [Get_Config(p_config_key)](https://github.com/BrenPatF/log_set_oracle#l_config-log_configsrowtype--log_configget_configp_config_key)
- [Del_Config(p_config_key)](https://github.com/BrenPatF/log_set_oracle#log_configdel_configp_config_key)
- [Ins_Config(optional parameters)](https://github.com/BrenPatF/log_set_oracle#log_configins_configoptional-parameters)

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
- [&uarr; API - Log_Config](https://github.com/BrenPatF/log_set_oracle#api---log_config)

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
- [&uarr; In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)
- [Install 1: Install pre-requisite modules](https://github.com/BrenPatF/log_set_oracle#install-1-install-pre-requisite-modules)
- [Install 2: Create Log_Set components](https://github.com/BrenPatF/log_set_oracle#install-2-create-log_set-components)
- [Install 3: Create synonyms to lib](https://github.com/BrenPatF/log_set_oracle#install-3-create-synonyms-to-lib)
- [Install 4: Install unit test code](https://github.com/BrenPatF/log_set_oracle#install-4-install-unit-test-code)

The install depends on the pre-requisite modules Utils and Trapit (unit testing only) and `lib` and `app` schemas refer to the schemas in which Utils and examples are installed, respectively.

### Install 1: Install pre-requisite modules
- [&uarr; Installation](https://github.com/BrenPatF/log_set_oracle#installation)

The pre-requisite modules can be installed by following the instructions at [Utils on GitHub](https://github.com/BrenPatF/oracle_plsql_utils). This allows inclusion of the examples and unit tests for the modules. Alternatively, the next section shows how to install the modules directly without their examples or unit tests here (but with the Trapit module required for unit testing the Log_Set module).

#### [Schema: sys; Folder: install_prereq] Create lib and app schemas and Oracle directory
- install_sys.sql creates an Oracle directory, `input_dir`, pointing to 'c:\input'. Update this if necessary to a folder on the database server with read/write access for the Oracle OS user
- Run script from slqplus:

```sql
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

```sql
SQL> @install_lib_all
```
#### [Schema: app; Folder: install_prereq\app] Create app synonyms and install example package
- Run script from slqplus:

```sql
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
- [&uarr; Installation](https://github.com/BrenPatF/log_set_oracle#installation)
#### [Schema: lib; Folder: lib]
- Run script from slqplus:

```sql
SQL> @install_log_set app
```
This creates the required components for the base install along with grants for them to the app schema (passing none instead of app will bypass the grants). This install is all that is required to use the package within the lib schema and app (if passed, and then Install 3 is required). To grant privileges to another `schema`, run the grants script directly, passing `schema`:

```sql
SQL> @grant_log_set_to_app schema
```

### Install 3: Create synonyms to lib
- [&uarr; Installation](https://github.com/BrenPatF/log_set_oracle#installation)

#### [Schema: app; Folder: app]
- Run script from slqplus:

```sql
SQL> @c_log_set_syns lib
```
This install creates private synonyms to the lib schema. To create synonyms within another schema, run the synonyms script directly from that schema, passing lib schema.

### Install 4: Install unit test code
- [&uarr; Installation](https://github.com/BrenPatF/log_set_oracle#installation)

This step requires the Trapit module option to have been installed as part of Install 1.

#### [Folder: (module root)] Copy unit test JSON file to input folder
- Copy the following file from the root folder to the server folder pointed to by the Oracle directory INPUT_DIR:
  - tt_log_set.purely_wrap_log_set_inp.json

- There is also a bash script to do this, assuming C:\input as INPUT_DIR:

```
$ ./cp_json_to_input.ksh
```

#### [Schema: lib; Folder: lib] Install unit test code
- Run script from slqplus:

```sql
SQL> @install_log_set_tt
```

## Unit Testing
- [&uarr; In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)
- [Unit Testing Process](https://github.com/BrenPatF/log_set_oracle#unit-testing-process)
- [Wrapper Function Signature Diagram](https://github.com/BrenPatF/log_set_oracle#wrapper-function-signature-diagram)
- [Unit Test Scenarios](https://github.com/BrenPatF/log_set_oracle#unit-test-scenarios)

### Unit Testing Process
- &uarr; [Unit Testing](https://github.com/BrenPatF/log_set_oracle#unit-testing)

The package is tested using the Math Function Unit Testing design pattern, described here: [The Math Function Unit Testing design pattern, implemented in nodejs](https://github.com/BrenPatF/trapit_nodejs_tester#trapit). In this approach, a 'pure' wrapper function is constructed that takes input parameters and returns a value, and is tested within a loop over scenario records read from a JSON file.

The wrapper function represents a generalised transactional use of the package in which multiple logs may be constructed, and written to independently. 

This is a good example of the power of the design pattern, and is a second example, after [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle), of unit testing where the 'unit' is taken to be a full generalised transaction, from start to finish of a logging (or timing) session.

The program is data-driven from the input file tt_log_set.purely_wrap_log_set_inp.json and produces an output file, tt_log_set.purely_wrap_log_set_out.json (in the Oracle directory `INPUT_DIR`), that contains arrays of expected and actual records by group and scenario.

The unit test program may be run from the Oracle lib subfolder:

```
SQL> @r_tests
```

The output file is processed by a nodejs program that has to be installed separately from the `npm` nodejs repository, as described in the Trapit install in `Install 1` above. The nodejs program produces listings of the results in HTML and/or text format, and a sample set of listings is included in the subfolder test_output. To run the processor, open a powershell window in the npm trapit package folder after placing the output JSON file, tt_log_set.purely_wrap_log_set_out.json, in the subfolder ./examples/externals and run:

```
$ node ./examples/externals/test-externals
```

This creates, or updates, a subfolder, oracle-pl_sql-log-set, with the formatted results output files. The three testing steps can easily be automated in Powershell (or Unix bash).

[An easy way to generate a starting point for the input JSON file is to use a powershell utility [Powershell Utilites module](https://github.com/BrenPatF/powershell_utils) to generate a template file with a single scenario with placeholder records from simple .csv files. See the script purely_wrap_log_set.ps1 in the `test_data` subfolder for an example]


### Wrapper Function Signature Diagram
- [&uarr; Unit Testing](https://github.com/BrenPatF/log_set_oracle#unit-testing)

<img src="test_data\log_set_oracle.png">

### Unit Test Scenarios
- [&uarr; Unit Testing](https://github.com/BrenPatF/log_set_oracle#unit-testing)
- [Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-input-data-category-sets)
- [Scenario Results](https://github.com/BrenPatF/log_set_oracle#scenario-results)

The art of unit testing lies in choosing a set of scenarios that will produce a high degree of confidence in the functioning of the unit under test across the often very large range of possible inputs.

A useful approach to this can be to think in terms of categories of inputs, where we reduce large ranges to representative categories. In our case we might consider the following category sets, and create scenarios accordingly:

#### Input Data Category Sets
- [&uarr; Scenarios](https://github.com/BrenPatF/log_set_oracle#scenarios)
- [Value Size](https://github.com/BrenPatF/log_set_oracle#value-size)
- [Multiplicity](https://github.com/BrenPatF/log_set_oracle#multiplicity)
- [Concurrency](https://github.com/BrenPatF/log_set_oracle#concurrency)
- [Parameter Defaults (each parameter)](https://github.com/BrenPatF/log_set_oracle#parameter-defaults--each-parameter-)
- [Log Config](https://github.com/BrenPatF/log_set_oracle#log-config)
- [Put Levels](https://github.com/BrenPatF/log_set_oracle#put-levels)
- [App Info Only](https://github.com/BrenPatF/log_set_oracle#app-info-only)
- [Contexts](https://github.com/BrenPatF/log_set_oracle#contexts)
- [Singleton](https://github.com/BrenPatF/log_set_oracle#singleton)
- [Array Length Parameters (buffer and extend sizes)](https://github.com/BrenPatF/log_set_oracle#array-length-parameters--buffer-and-extend-sizes-)
- [Exceptions](https://github.com/BrenPatF/log_set_oracle#exceptions)
- [OTHERS Error Handler](https://github.com/BrenPatF/log_set_oracle#others-error-handler)
- [Log Closure](https://github.com/BrenPatF/log_set_oracle#log-closure)
- [API Calls](https://github.com/BrenPatF/log_set_oracle#api-calls)

##### Value Size
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check very small numbers or strings and very large ones do not cause value or display errors
- Small
- Large

##### Multiplicity
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that logging works with 1 and multiple loggers active (except multiple singletons not allowed)
- 1
- Multiple

##### Concurrency
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that log sets with overlapping scope do not interfere with each other
- Concurrent log sets
- No concurrent log sets

##### Parameter Defaults (each parameter)
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that parameters default as expected, and also are overridden by values passed
- Defaulted
- Non-defaulted

##### Log Config
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Each log references a log config that includes put level and various config settings. We test usage of existing configs, and creation of new config records
- Existing config
- New config

##### Put Levels
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Put level is specified in the config record and applies to multiple types of information. The put procedures take a Put Level Min parameter, with an overall minimum specified in the log constructor, and put the information out only if the relevant level is at or above the minimum. The categories to check are therefore:
- Put Level <  Put Level Min
- Put Level &ge; Put Level Min

There is an overall level:
<ul>
<ul>
<li>Put Level</li>
</ul>
</ul>
and field level values:
<ul>
<ul>
<li>Put Level Stack</li>
<li>Put Level CPU</li>
<li>Put Level Module</li>
<li>Put Level Action</li>
<li>Put Level Client Info</li>
</ul>
</ul>

##### App Info Only
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

App Info is written using DBMS_Application_Info procedures Set_Module (at log level) and Set_Action and Set_Client_Info (at line level). If this config field is set to "Yes" lines are not put, but App Info is put if the put level allows
- Yes
- No

##### Contexts
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

System contexts may be captured using SYS_CONTEXT('USERENV', `context name`) at header or line level or both, depending on the config setting
- Header
- Line
- Both

##### Singleton
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that only one log of type singleton (dsefined in the log config) can be active at a time
- Singleton plus non-singleton - ok
- Singleton plus singleton - fails

##### Array Length Parameters (buffer and extend sizes)
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Log lines may be buffered before writing to table for potential performance reasons, and the buffer length and extend lengths can be set in the log config. Check that closing the log does not cause unsaved lines to be lost, using sizes of 1 and more than 1
- 1
- &gt; 1

##### Exceptions
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that validations return exceptions correctly
- None
- Closed log id
- Invalid log id
- Invalid log config

##### OTHERS Error Handler
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

General Oracle errors can be written using the error handler within an exception block, either to a new log or to an existing log
- Existing log
- New log

##### Log Closure
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Logs may be closed explicitly, with a closure timestamp being written, and any buffered lines written, or not closed in which case these actions do not ocuur. Check both work as expected
- Close explicitly
- Do not close explicitly

##### API Calls
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/log_set_oracle#input-data-category-sets)

Check that all entry points work. Note that these are represented by different values for the event type wrapper function input parameter
- Con_Construct_Rec
- Con_Line_Rec
- Construct (simple)
- Construct (with line)
- Construct (with list)
- Put_Line
- Put_List
- Close_Log
- Raise_Error
- Write_Other_Error
- Delete_Log
- Entry_Point
- Exit_Point

#### Scenario Results
- [&uarr; Scenarios](https://github.com/BrenPatF/log_set_oracle#scenarios)
- [Results Summary](https://github.com/BrenPatF/log_set_oracle#results-summary)
- [Results for Scenario 1](https://github.com/BrenPatF/log_set_oracle#results-for-scenario-1)

##### Results Summary
- [&uarr; Scenario Results](https://github.com/BrenPatF/log_set_oracle#scenario-results)

The summary report in text format shows the scenarios tested:

      #    Scenario                                                                                                                                                                    Fails (of 5)  Status 
      ---  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------  ------------  -------
      1    Simple defaulted                                                                                                                                                            0             SUCCESS
      2    Simple defaulted, don't close - still saved with default buffer size = 1                                                                                                    0             SUCCESS
      3    Set all parameters                                                                                                                                                          0             SUCCESS
      4    Set all parameters with long values                                                                                                                                         0             SUCCESS
      5    New config, with H/B/L contexts and parameters all passed; module app info                                                                                                  0             SUCCESS
      6    New config, with H/B/L contexts; put level prints only some lines; field min put levels below line min - should print; line close                                           0             SUCCESS
      7    New config; field min put levels above line min - should not print; header min level above module level, module/action to put (but not client info); contexts not to print  0             SUCCESS
      8    MULTIBUF: Three logs printing 2 lines interleaved, plus header only; also log that shouldn't print                                                                          0             SUCCESS
      9    Construct and put lists                                                                                                                                                     0             SUCCESS
      10   Closed log id                                                                                                                                                               0             SUCCESS
      11   Invalid log id                                                                                                                                                              0             SUCCESS
      12   Invalid log config                                                                                                                                                          0             SUCCESS
      13   App info only                                                                                                                                                               0             SUCCESS
      14   App info without module, and writing to table                                                                                                                               0             SUCCESS
      15   OTHERS error handler, existing log                                                                                                                                          0             SUCCESS
      16   OTHERS error handler, new log                                                                                                                                               0             SUCCESS
      17   Custom error handler, existing log                                                                                                                                          0             SUCCESS
      18   Singleton (pass null log id) plus non-singleton                                                                                                                             0             SUCCESS
      19   Singleton (pass null log id) plus singleton - fails                                                                                                                         0             SUCCESS
      20   Array length parameters (check no lines unsaved)                                                                                                                            0             SUCCESS
      21   Entry/Exit Point                                                                                                                                                            0             SUCCESS

##### Results for Scenario 1: Simple defaulted
- [&uarr; Scenario Results](https://github.com/BrenPatF/log_set_oracle#scenario-results)

<pre>
SCENARIO 1: Simple defaulted {
==============================

   INPUTS
   ======

      GROUP 1: Log Config: Empty
      ==========================

      GROUP 2: Context: Empty
      =======================

      GROUP 3: Event Sequence {
      =========================

            #  Event No  Event Type  Log Id Offset
            -  --------  ----------  -------------
            1  1         CON         1            
            2  2         PUT_LINE    1            
            3  3         CLO         1            

      }
      =

      GROUP 4: Construct Param {
      ==========================

            #  Event No  Config Key  Description  PLSQL Unit  API Name  Put Level Min  Do Close Y/N
            -  --------  ----------  -----------  ----------  --------  -------------  ------------
            1  1                                                                                   

      }
      =

      GROUP 5: Log Parameter {
      ========================

            #  Event No  Line Type  PLSQL Unit  PLSQL Line  Group Text  Action  Put Level Min  Error No  Error Message  Do Close Y/N
            -  --------  ---------  ----------  ----------  ----------  ------  -------------  --------  -------------  ------------
            1  2                                                                                                                    

      }
      =

      GROUP 6: Line Text {
      ====================

            #  Event No  Text     
            -  --------  ---------
            1  2         Some text

      }
      =

   OUTPUTS
   =======

      GROUP 1: Log Header {
      =====================

            #  Log Id Offset  Config Id Offset  Config Key  Session Id Offset  Session User  Description  PLSQL Unit  API Name  Put Level Min  Creation Time      Closure Time      
            -  -------------  ----------------  ----------  -----------------  ------------  -----------  ----------  --------  -------------  -----------------  ------------------
            1  1              0                 SINGLETON   0                  LIB                                              0              IN [0.0,0.2]: .01  IN [0.0,0.2]: .027

      } 0 failed of 1: SUCCESS
      ========================

      GROUP 2: Context: Empty as expected: SUCCESS
      ============================================

      GROUP 3: Log Line {
      ===================

            #  Log Id Offset  Line No  Session Line No  Line Type  PLSQL Unit  PLSQL Line  Group Text  Action  Line Text  Call Stack  Error Backtrace  Put Level Min  Error No  Error Message  Creation Time           Creation CPU Time
            -  -------------  -------  ---------------  ---------  ----------  ----------  ----------  ------  ---------  ----------  ---------------  -------------  --------  -------------  ------------------      -----------------
            1  1              1        1                                                                       Some text                               0                                       IN [0.0,0.1]:     .026                   

      } 0 failed of 1: SUCCESS
      ========================

      GROUP 4: Exception: Empty as expected: SUCCESS
      ==============================================

      GROUP 5: Application Info {
      ===========================

            #  Module  Action  Client Info
            -  ------  ------  -----------
            1                             

      } 0 failed of 1: SUCCESS
      ========================

} 0 failed of 5: SUCCESS
========================
</pre>

You can review the formatted unit test results here, [Unit Test Report: Oracle PL/SQL Log Set](http://htmlpreview.github.io/?https://github.com/BrenPatF/timer_set_oracle/blob/master/test_data/test_output/oracle-pl_sql-log-set/oracle-pl_sql-log-set.html), and the files are available in the `test_data\test_output\oracle-pl_sql-log-set` subfolder [oracle-pl_sql-log-set.html is the root page for the HTML version and oracle-pl_sql-log-set.txt has the results in text format].

## Operating System/Oracle Versions
- [In this README...](https://github.com/BrenPatF/log_set_oracle#in-this-readme)

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