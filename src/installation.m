%% Installation Script for MTSlite Application
% This script initializes the application by:
%   1) Loading and optionally editing the Parameters struct
%   2) Creating the required database schema and tables
%   3) Generating a Windows batch file to start the application
%   4) Creating a desktop shortcut for launching the app

%% --- Check for Administrator Privileges ---
if ~isUserAdmin()
    uiwait(warndlg({ ...
        '⚠️ This script requires administrator privileges.', ...
        '', ...
        'Please close MATLAB and restart it as Administrator:', ...
        '→ Right-click the MATLAB icon → "Run as administrator".', ...
        '', ...
        'Then, run this installation script again.'}, ...
        'Administrator Rights Required'));

    error('Aborted: MATLAB is not running as Administrator.');
end

fprintf('MATLAB is running with Administrator privileges.\n');

%% Setup
disp('Installation is executed');

thisFile = mfilename('fullpath');
[installationfilepath, ~, ~] = fileparts(thisFile);
cd(installationfilepath);

setup();

cd(installationfilepath);

%% Parameters file handling
% Load application settings from a generated Parameters_struct.m file.
if ~exist("struct\Parameters_struct.m", 'file')
    disp("Parameters file was created.");
    copyfile("struct\Parameters_struct_template.m", "struct\Parameters_struct.m");
    addpath("struct\Parameters_struct.m");
end

Parameters_struct;
cd(installationfilepath);

%% Create required folders
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

%% ProteoWizard / MSConvert and PostgreSQL (interactive)
Parameters.path.MATLABexe = fullfile(matlabroot, 'bin', 'matlab.exe');
Parameters.path.proteoWizard = ensure_msconvert_interactive();
Parameters.path.psqlExe = ensure_postgres_present_interactive();

%% Optional: Edit Parameters via GUI
editedParameters = editParametersGUI(Parameters);
if numel(editedParameters) > 0
    Parameters = editedParameters;
end

% Save potentially updated parameters
save(fullfile(Parameters.path.program, 'data', 'Import', 'methods', 'Parameters.mat'), 'Parameters');
disp('Parameters were saved.');

%% Step 1: Create table structure in the database
filepath = newsqlfile(Parameters);
fileID = fopen(filepath, 'w');

fprintf(fileID, 'CREATE SCHEMA IF NOT EXISTS "%s";\n', Parameters.database.schema);

fields = fieldnames(Parameters.database.tables(1));
for i = 1:numel(fields)
    tableName = fields{i};
    tableMeta = Parameters.database.tables.(tableName);
    createTableSQL = generateSQLforTablecreation(tableMeta, tableName, Parameters.database.schema);
    fprintf(fileID, '%s\n', createTableSQL);
end

fclose(fileID);

runsqlfile(filepath, Parameters);

%% Step 2: Generate batch file to launch the application
batFile = fullfile(Parameters.path.program, 'bat', 'start_AutoQ4MS_admin.bat');
fid = fopen(batFile, 'w');
if fid == -1
    error('Could not create BAT file: %s', batFile);
end

% Prepare full path to project folder (escaped for MATLAB command string)
projectPath = strrep(fullfile(string(Parameters.path.program), 'src'), '\', '\\');
matlabCmd = sprintf("cd('%s');setup(); AutoQ4MS", projectPath);

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

%% Step 3: Create desktop shortcut via batch + PowerShell
desktop = Parameters.path.desktop;
imgpath = fullfile(Parameters.path.program, 'img', 'AutoQ4MS_Icon.ico');
shortcutName = 'AutoQ4MS.lnk';
shortcutBat = fullfile(Parameters.path.program, 'bat', 'create_shortcut.bat');

fid = fopen(shortcutBat, 'w');
if fid == -1
    error('Could not create shortcut .bat file.');
end

fprintf(fid, '@echo off\n');
fprintf(fid, 'set "shortcutName=%s"\n', shortcutName);
fprintf(fid, 'set "targetBat=%s"\n', batFile);
fprintf(fid, 'set "workingDir=%s"\n', installationfilepath);
fprintf(fid, 'set "desktop=%s"\n\n', desktop);

fprintf(fid, 'powershell -ExecutionPolicy Bypass -Command ^\n');
fprintf(fid, '"$WshShell = New-Object -ComObject WScript.Shell; ');
fprintf(fid, '$Shortcut = $WshShell.CreateShortcut(''%%desktop%%\\%%shortcutName%%''); ');
fprintf(fid, '$Shortcut.TargetPath = ''%%targetBat%%''; ');
fprintf(fid, '$Shortcut.WorkingDirectory = ''%%workingDir%%''; ');
fprintf(fid, '$Shortcut.WindowStyle = 1; ');
fprintf(fid, '$Shortcut.IconLocation = ''%s''; ^\n', imgpath);
fprintf(fid, '$Shortcut.Save();"\n');
fclose(fid);

status = system(['cmd /c ""' char(shortcutBat) '""']);
if status == 0
    disp('Shortcut was successfully created.');
else
    warning('Error executing shortcut batch file. Exit code: %d', status);
end

function tf = isUserAdmin()
%ISUSERADMIN Check whether MATLAB is running with administrator privileges (Windows).
    try
        [status, ~] = system('net session >nul 2>&1');
        tf = (status == 0);
    catch
        tf = false;
    end
end

