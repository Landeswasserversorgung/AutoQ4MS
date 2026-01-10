classdef method
%METHOD  Class representing a data processing method configuration.
%
%   This class encapsulates method-specific Parameters, persistence to disk,
%   creation of database schema/tables, and optional scheduling via Windows
%   Task Scheduler.

    properties
        Name
        Parameters
    end

    methods
        function obj = method(Parameters, Name)
            %METHOD  Constructor: create a new method or load an existing one.
            %
            %   obj = method(Parameters)
            %   Opens a dialog to create a new method.
            %
            %   obj = method(Parameters, Name)
            %   Loads an existing method stored under the given Name.

            if nargin < 2 || isempty(Name)
                % No name provided -> create new method
                obj = obj.createnewmethod(Parameters);
            else
                % Name provided -> load existing method
                obj = obj.loadmethod(Parameters, Name);
            end
        end

        function taskmanagerupdate(obj)
            %TASKMANAGERUPDATE  Create or delete the Windows Task Scheduler entry.
            %
            %   Delete task and create if afterwarts if If Parameters.TaskManager.On is false
            %
            %   The task executes a method-specific .bat file.

            taskName = ['AutoQ4MS_' obj.Name '_Task'];
            batFilePath = fullfile(obj.Parameters.path.program, 'bat', [obj.Name '_run_Processing.bat']);

            % delete task
            system(['schtasks /Delete /TN "' taskName '" /F'], '-echo');

            % create if true 

            if obj.Parameters.TaskManager.On
              
                interval = obj.Parameters.TaskManager.Interval;

                if ~isfile(batFilePath)
                    error('BAT file not found: %s', batFilePath);
                end

                createCommand = sprintf([ ...
                    'schtasks /Create /SC MINUTE /MO %d /TN "%s" ' ...
                    '/TR "\\"%s\\"" /RL HIGHEST' ...
                    ], ...
                    interval, taskName, batFilePath);

                status = system(createCommand);

                if status == 0
                    fprintf('Task "%s" created. Interval: %d minutes\n', taskName, interval);
                else
                    warning('Task "%s" could not be created.', taskName);
                end
            end
        end

        function obj = turnTaskon(obj)
            %TURNTASKON  Enable task scheduling for this method and apply changes.
            obj.turnTaskoff()
            obj.Parameters.TaskManager.On = true;
            obj.taskmanagerupdate();
            savemethod(obj);
        end

        function obj = turnTaskoff(obj)
            %TURNTASKOFF  Disable task scheduling for this method and apply changes.
            obj.Parameters.TaskManager.On = false;
            obj.taskmanagerupdate();
            savemethod(obj);
        end

        function delmethod(obj)
            %DELMETHOD  Delete all method-related files and scheduled tasks.
            %
            %   Removes:
            %     - Task Scheduler entry
            %     - .bat launcher
            %     - .mat method file
            %   Optionally:
            %     - Drops the database schema (CASCADE)

            batFilePath = fullfile(obj.Parameters.path.program, 'bat', [obj.Name '_run_Processing.bat']);
            matFilePath = fullfile(obj.Parameters.path.program, 'data', 'import', 'methods', [obj.Name, '.mat']);

            % 1) Turn off (and delete) scheduled task
            obj.turnTaskoff();

            % 2) Delete BAT file
            if isfile(batFilePath)
                delete(batFilePath);
                fprintf('BAT file deleted: %s\n', batFilePath);
            else
                fprintf('BAT file not found (already deleted?): %s\n', batFilePath);
            end

            % 3) Delete MAT file
            if isfile(matFilePath)
                delete(matFilePath);
                fprintf('MAT file deleted: %s\n', matFilePath);
            else
                fprintf('MAT file not found (already deleted?): %s\n', matFilePath);
            end

            % 4) Optionally drop schema in the database
            choice = questdlg( ...
                sprintf('Do you also want to delete the schema "%s" from the database?', obj.Parameters.database.schema), ...
                'Delete Database Schema', ...
                'Yes', 'No', 'No');

            if strcmp(choice, 'Yes')
                schemaName = obj.Parameters.database.schema;
                dropSQL = sprintf('DROP SCHEMA IF EXISTS "%s" CASCADE;', schemaName);

                formattedDateTime = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
                sqlFilePath = fullfile(obj.Parameters.path.program, 'src', 'database', ['sql_commands_', formattedDateTime, '.sql']);

                fileID = fopen(sqlFilePath, 'w');
                fwrite(fileID, dropSQL);
                fclose(fileID);

                runsqlfile(sqlFilePath, obj.Parameters);

                fprintf('Schema "%s" deleted from database.\n', schemaName);
            else
                fprintf('Schema "%s" NOT deleted from database.\n', obj.Parameters.database.schema);
            end

            fprintf('Method "%s" cleanup complete.\n', obj.Name);
        end

        function run(obj)
            %RUN  Manually run the associated .bat file.
            system(['start "" "' char(fullfile(obj.Parameters.path.program, 'bat', [obj.Name, '_run_Processing.bat'])) '"']);
        end

        function savemethod(obj)
            %SAVEMETHOD  Save the current method Parameters to disk.
            Parameters = obj.Parameters; %#ok<PROP>
            save(fullfile(char(obj.Parameters.path.program), 'data', 'import', 'methods', [obj.Name, '.mat']), 'Parameters');
        end

        function obj = loadmethod(obj, Parameters, Name)
            %LOADMETHOD  Load a method (Parameters) from disk by name.

            matFilePath = fullfile(Parameters.path.program, 'data', 'import', 'methods', [Name, '.mat']);

            if ~isfile(matFilePath)
                error('Method file not found: %s', matFilePath);
            end

            loaded = load(matFilePath, 'Parameters');

            if ~isfield(loaded, 'Parameters')
                error('File %s does not contain a ''Parameters'' variable.', matFilePath);
            end

            obj.Parameters = loaded.Parameters;
            obj.Name = Name;

            fprintf('Method "%s" successfully loaded.\n', obj.Name);
        end

        function obj = createnewmethod(obj, Parameters)
            %CREATENEWMETHOD  Interactively create a new method and initialize its resources.
            %
            %   - Prompts for a valid method name
            %   - Opens the parameter editor GUI
            %   - Saves the method to disk
            %   - Creates database schema and tables
            %   - Generates a .bat launcher from a template
            %   - Updates Task Scheduler configuration

            while true
                userInput = inputdlg( ...
                    'Enter method name (lowercase, digits, underscore only):', ...
                    'Method Name', [1 40]);

                if isempty(userInput)
                    error('User cancelled name input.');
                end

                Name = userInput{1};

                % Only lowercase letters, digits, underscores
                isValid = ~isempty(regexp(Name, '^[a-z0-9_]+$', 'once'));

                % Path to the .mat file
                matFilePath = fullfile(Parameters.path.program, 'methods', [Name, '.mat']);

                if isValid && ~isfile(matFilePath)
                    break;
                elseif isfile(matFilePath)
                    uiwait(warndlg( ...
                        'A method with this name already exists. Please choose a different name.', ...
                        'Name already exists', 'modal'));
                else
                    uiwait(warndlg( ...
                        'Name must only contain lowercase letters, numbers, and underscores.', ...
                        'Invalid Name', 'modal'));
                end
            end

            obj.Name = Name;
            Parameters.database.schema = obj.Name;
            obj.Parameters = editParametersGUI(Parameters);

            obj.savemethod();

            %% Step 1: Create the corresponding database structure
            disp("Creating data tables in the database...");

            formattedDateTime = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
            filepath = fullfile(Parameters.path.program, 'src', 'database', ['sql_commands_', formattedDateTime, '.sql']);
            fileID = fopen(filepath, 'w');
            fprintf(fileID, 'CREATE SCHEMA "%s"\n', obj.Parameters.database.schema);

            fields = fieldnames(obj.Parameters.database.tables(1));
            for i = 1:numel(fields)
                tableName = sprintf('%s', fields{i});
                tableMeta = obj.Parameters.database.tables.(fields{i});
                createTableSQL = generateSQLforTablecreation(tableMeta, tableName, obj.Parameters.database.schema);
                fprintf(fileID, '%s\n', createTableSQL);
                clear createTableSQL;
            end
            fclose(fileID);
            runsqlfile(filepath, obj.Parameters);

            %% Step 2: Generate .bat file from template
            projectPath = obj.Parameters.path.program;
            matlabExe = obj.Parameters.path.MATLABexe;
            matFilePath = fullfile(obj.Parameters.path.program, 'data', 'import', 'methods', [obj.Name, '.mat']);

            templateFile = fullfile(projectPath, 'bat', 'template.bat');
            outputFile = fullfile(projectPath, 'bat', [obj.Name, '_run_processing.bat']);

            processingPath = fullfile(projectPath, 'src');
            templateText = fileread(templateFile);

            templateText = strrep(templateText, '%PROJECT_PATH%', processingPath);
            templateText = strrep(templateText, '%MATLAB_EXE%', matlabExe);
            templateText = strrep(templateText, '%METHOD_PATH%', matFilePath);
            templateText = strrep(templateText, '%LOGS_PATH%', projectPath);

            fid = fopen(outputFile, 'wt');
            fwrite(fid, templateText);
            fclose(fid);

            %% Step 3: Configure Task Scheduler
            obj.taskmanagerupdate();
        end
    end
end



