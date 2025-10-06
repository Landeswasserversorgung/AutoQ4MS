classdef method
    % METHOD Class representing a data processing method
    %   Includes setup for database structure, task scheduling, and 
    %   batch file creation
    
    properties
        Name 
        Parameters
    end

    methods
        function obj = method(Parameters, Name)
            % Constructor: creates a new method or loads an existing one
            % If Name is empty or not provided, create a new method
        
            if nargin < 2 || isempty(Name)
                % No name provided → create new method
                obj = obj.createnewmethod(Parameters);
            else
                % Name provided → load existing method
                obj = obj.loadmethod(Parameters, Name);
            end
        end

        function taskmanagerupdate(obj)
            % Updates (creates or deletes) the Windows Task Scheduler entry
            taskName = ['MTS_' obj.Name '_Task'];
            batFilePath = fullfile(obj.Parameters.path.program, 'bat', [obj.Name '_run_Processing.bat']);

            if obj.Parameters.TaskManager.On == false
                    [status, ~] = system(['schtasks /Query /TN "' taskName '"']);
                if status == 0
                    % Task exists → delete
                    system(['schtasks /Delete /TN "' taskName '" /F']);
                    fprintf('Task "%s" deleted.\n', taskName);
                else
                    % Task doesn't exist → nichts tun
                    fprintf('Task "%s" does not exist – nothing to delete.\n', taskName);
                end
            else
                % Create task
                interval = obj.Parameters.TaskManager.Interval;

                if ~isfile(batFilePath)
                    error('BAT file not found: %s', batFilePath);
                end

                createCommand = sprintf(['schtasks /Create /SC MINUTE /MO %d /TN "%s" ' ...
                    '/TR "\"%s\"" /RL HIGHEST'], ...
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
            obj.turnTaskoff()
            % Enables the Windows task and updates it
            obj.Parameters.TaskManager.On = true;
            obj.taskmanagerupdate();
            savemethod(obj);
        end

        function obj = turnTaskoff(obj)
            % Disables the Windows task and removes it
            obj.Parameters.TaskManager.On = false;
            obj.taskmanagerupdate();
            savemethod(obj);
        end

        function delmethod(obj)
            % DELMETHOD deletes all related files and tasks for the current method
        
            % Construct paths
            batFilePath = fullfile(obj.Parameters.path.program, 'bat', [obj.Name '_run_Processing.bat']);
            
            matFilePath = fullfile(obj.Parameters.path.program, 'data','import', 'methods', [obj.Name, '.mat']);
        
            % 1. Turn off (and delete) scheduled task
            obj.turnTaskoff();  % Deletes task via taskmanagerupdate()
        
            % 2. Delete BAT file
            if isfile(batFilePath)
                delete(batFilePath);
                fprintf('BAT file deleted: %s\n', batFilePath);
            else
                fprintf('BAT file not found (already deleted?): %s\n', batFilePath);
            end
        
            % 3. Delete MAT file
            if isfile(matFilePath)
                delete(matFilePath);
                fprintf('MAT file deleted: %s\n', matFilePath);
            else
                fprintf('MAT file not found (already deleted?): %s\n', matFilePath);
            end
            % 4. Optional: Schema in der Datenbank löschen
            choice = questdlg( ...
                sprintf('Do you also want to delete the schema "%s" from the database?', obj.Parameters.database.schema), ...
                'Delete Database Schema', ...
                'Yes', 'No', 'No');
            
            if strcmp(choice, 'Yes')
                schemaName = obj.Parameters.database.schema;
                dropSQL = sprintf('DROP SCHEMA IF EXISTS "%s" CASCADE;', schemaName);
                
                % SQL-Datei schreiben
                formattedDateTime = datestr(datetime('now'), 'yyyymmdd_HHMMSS');
                sqlFilePath = fullfile(obj.Parameters.path.program, 'src', 'database', ['sql_commands_',formattedDateTime,'.sql']);
                fileID = fopen(sqlFilePath, 'w');
                fwrite(fileID, dropSQL);
                fclose(fileID);
                
                % SQL-Datei ausführen
                runsqlfile(sqlFilePath, obj.Parameters);
                
                fprintf('Schema "%s" deleted from database.\n', schemaName);
            else
                fprintf('Schema "%s" NOT deleted from database.\n', obj.Parameters.database.schema);
            end
        
            % Optionally: show summary
            fprintf('Method "%s" cleanup complete.\n', obj.Name);
        end


        function run(obj)
            % Manually run the associated .bat file
            system(['start "" "' char(fullfile(obj.Parameters.path.program, 'bat', [obj.Name,'_run_Processing.bat'])) '"']);
        end

        function savemethod(obj)
            % Save the current method (Parameters) to disk
            Parameters = obj.Parameters; %#ok<PROP>
            save(fullfile(char(obj.Parameters.path.program), 'data','import', 'methods', [obj.Name, '.mat']), 'Parameters');
        end
        
        function obj = loadmethod(obj, Parameters, Name)
            % LOADMETHOD Loads a method by name and sets the corresponding Parameters
        
            % Path to the .mat file
            matFilePath = fullfile(Parameters.path.program,'data','import',  'methods', [Name, '.mat']);
        
            % Check if the file exists
            if ~isfile(matFilePath)
                error('Method file not found: %s', matFilePath);
            end
        
            % Load the .mat file (assumes it contains variable named 'Parameters')
            loaded = load(matFilePath, 'Parameters');
        
            if ~isfield(loaded, 'Parameters')
                error('File %s does not contain a ''Parameters'' variable.', matFilePath);
            end
        
            % Set internal state
            obj.Parameters = loaded.Parameters;
            obj.Name = Name;  % extract name from loaded struct
        
            fprintf('Method "%s" successfully loaded.\n', obj.Name);
        end


        function obj = createnewmethod(obj, Parameters)
            while true 
                userInput = inputdlg( ...
                    'Enter method name (lowercase, digits, underscore only):', ...
                    'Method Name', [1 40]); 
        
                % Cancel if user presses cancel or closes dialog
                if isempty(userInput)
                    error('User cancelled name input.');
                end
        
                Name = userInput{1};
        
                % Regex check: only lowercase letters, digits and underscores allowed
                isValid = ~isempty(regexp(Name, '^[a-z0-9_]+$', 'once'));
        
                % Path to .mat file
                matFilePath = fullfile(Parameters.path.program, 'methods', [Name, '.mat']);
        
                % Check if file already exists
                if isValid && ~isfile(matFilePath)
                    break;  % valid and not taken
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
            filepath = fullfile(Parameters.path.program, 'src', 'database', ['sql_commands_',formattedDateTime,'.sql']);
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
        
            %% Step 2: Generate .bat file with error logging
            projectPath  = obj.Parameters.path.program;
            matlabExe    = obj.Parameters.path.MATLABexe;
            matFilePath  = fullfile(obj.Parameters.path.program,'data','import', 'methods', [obj.Name, '.mat']);
            
            % Pfade zum Template und Output
            templateFile = fullfile(projectPath, 'bat', 'template.bat');
            outputFile   = fullfile(projectPath, 'bat', [obj.Name, '_run_processing.bat']);

            processingPath  = fullfile(projectPath, 'src');
            % Template einlesen
            templateText = fileread(templateFile);
            
            % Platzhalter ersetzen
            templateText = strrep(templateText, '%PROJECT_PATH%', processingPath);
            templateText = strrep(templateText, '%MATLAB_EXE%', matlabExe);
            templateText = strrep(templateText, '%METHOD_PATH%', matFilePath);
            
            % .bat-Datei schreiben
            fid = fopen(outputFile, 'wt');
            fwrite(fid, templateText);
            fclose(fid);
        
            %% Step 3: Configure Task Scheduler
            obj.taskmanagerupdate();
        
            
        end
    end
end


