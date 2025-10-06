%% Installation Script for MTSlite Application
% This script initializes the application by:
% 1. Loading and optionally editing the parameter struct
% 2. Creating necessary database tables
% 3. Generating a Windows batch file to start the application
% 4. Creating a desktop shortcut for launching the app
%% 
thisFile = mfilename('fullpath');
[thisPath, ~, ~] = fileparts(thisFile);
cd(thisPath);
setup()

%% Setup
disp('Installation is executed');

%% Load Parameters
% Load application settings from .mat file
Parameters_struct

thisFile = mfilename('fullpath');
[thisPath, ~, ~] = fileparts(thisFile);
cd(thisPath);
load('..\data\Import\methods\Parameters.mat');  % Structure with parameters to run the application





%% Optional: Edit Parameters via GUI
editParameters = editParametersGUI(Parameters);
if numel(editParameters) > 0
    Parameters = editParameters;
end

% Save potentially updated parameters
save(fullfile(Parameters.path.program, 'data', 'Import', 'methods', 'Parameters.mat'), 'Parameters');
disp('Parameters were saved.');

%% create folder
folderPath = fullfile(Parameters.path.program, 'src', 'database', 'failed');
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

folderPath = fullfile(Parameters.path.program, 'src', 'mail', 'images');
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

folderPath = fullfile(Parameters.path.program, 'data', 'import', 'mslib');
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

folderPath = fullfile(Parameters.path.program, 'logs');
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

%% Step 1: Create Table Structure in the Database
disp("Create the data tables in the database");

% Generate SQL file path
filepath = newsqlfile(Parameters);
fileID = fopen(filepath, 'w');

% Write SQL schema declaration
fprintf(fileID, 'CREATE SCHEMA "%s"\n', Parameters.database.schema);

% Loop through each defined table and write CREATE TABLE statements
fields = fieldnames(Parameters.database.tables(1));
for i = 1:numel(fields)
    tableName = fields{i};
    tableMeta = Parameters.database.tables.(tableName);
    createTableSQL = generateSQLforTablecreation(tableMeta, tableName, Parameters.database.schema);
    fprintf(fileID, '%s\n', createTableSQL); 
end
fclose(fileID);

% Execute SQL file to create tables
runsqlfile(filepath, Parameters);

%% Step 2: Generate Batch File to Launch Application
batFile = fullfile(Parameters.path.program, 'bat', 'start_AutoQ4MS_admin.bat');
fid = fopen(batFile, 'w');
if fid == -1
    error('Could not create BAT file: %s', batFile);
end

% Prepare full path to MATLAB project file with escaped backslashes
projectPath = strrep(fullfile(string(Parameters.path.program), 'src'), '\', '\\');
matlabCmd = sprintf("cd('%s'); AutoQ4MS", projectPath);

% Write content of the batch file
fprintf(fid, '@echo off\n');
fprintf(fid, ':: Restart batch file as admin if not already elevated\n');
fprintf(fid, 'fltmc >nul 2>&1 || (\n');
fprintf(fid, '    powershell -Command "Start-Process -FilePath ''%%~f0'' -Verb RunAs"\n');
fprintf(fid, '    exit /b\n');
fprintf(fid, ')\n\n');

fprintf(fid, ':: Start MATLAB in nodesktop mode and launch app\n');
fprintf(fid, 'start "" matlab -nosplash -nodesktop -r "%s"\n', matlabCmd);
fprintf(fid, 'exit\n');
fclose(fid);

disp(['BAT file created: ', batFile]);

%% Step 3: Create Desktop Shortcut via Batch + PowerShell
desktop = Parameters.path.desktop;
shortcutName = 'AutoQ4MS.lnk';
shortcutBat = fullfile(Parameters.path.program, 'bat', 'create_shortcut.bat');

fid = fopen(shortcutBat, 'w');
if fid == -1
    error('Could not create shortcut .bat file.');
end

% Write batch file to create desktop shortcut using PowerShell
fprintf(fid, '@echo off\n');
fprintf(fid, 'set "shortcutName=%s"\n', shortcutName);
fprintf(fid, 'set "targetBat=%s"\n', batFile);
fprintf(fid, 'set "workingDir=%s"\n', thisPath);
fprintf(fid, 'set "desktop=%s"\n\n', desktop);

fprintf(fid, 'powershell -ExecutionPolicy Bypass -Command ^\n');
fprintf(fid, '"$WshShell = New-Object -ComObject WScript.Shell; ');
fprintf(fid, '$Shortcut = $WshShell.CreateShortcut(''%%desktop%%\\%%shortcutName%%''); ');
fprintf(fid, '$Shortcut.TargetPath = ''%%targetBat%%''; ');
fprintf(fid, '$Shortcut.WorkingDirectory = ''%%workingDir%%''; ');
fprintf(fid, '$Shortcut.WindowStyle = 1; ');
fprintf(fid, '$Shortcut.Save();"\n');
fclose(fid);

% Execute shortcut creation script
status = system(['cmd /c ""' char(shortcutBat) '""']);
if status == 0
    disp('✅ Shortcut was successfully created.');
else
    warning('⚠️ Error executing shortcut batch file. Exit code: %d', status);
end

