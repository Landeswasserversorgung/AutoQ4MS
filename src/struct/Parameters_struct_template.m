%%  Parameter Initialization Script
% Configuration script for initializing the Parameters struct used by AutoQ4MS.

clearvars -except installationfilepath;
clc;

%% Set working directory to script location
thisFile = mfilename('fullpath');
[thisPath, ~, ~] = fileparts(thisFile);
cd(thisPath);

%% Initialize struct
Parameters = struct();

%% ========== 1. General Paths & Configuration ==========
Parameters.General.MSdataending = ".mzXML";
Parameters.General.RawMS_Format = ".wiff";
Parameters.General.timestamp_of_measurement = 4; % 1 = now; 2 = file metadata; 3 = creation date
Parameters.General.sampling_timestamp = 1;        % 0 = NaT; 1 = now; etc.

Parameters.isOn.deletemzXML = false;

% Base tools and executable paths
Parameters.path.MATLABexe = "Test"; % matlab.exe
Parameters.path.proteoWizard = "";  % msconvert.exe
Parameters.path.psqlExe = "";       % psql.exe
Parameters.path.desktop = "";

% MS data source and archive
Parameters.path.MSDataSource = "";
Parameters.path.savedMSData = "";

% Processing order
Parameters.General.SampleOrder = 1; % 0 = modification date, 1 = name (A-Z)

% Program base directory
scriptDir = fileparts(mfilename('fullpath'));
parentDir = fileparts(scriptDir);
Parameters.path.program = string(fileparts(parentDir));

% Excel files
Parameters.path.ISExcel = fullfile(Parameters.path.program, 'data', 'Import', 'InternalStandards_Zorbax.xlsx');
Parameters.path.CompExcel = fullfile(Parameters.path.program, 'data', 'Import', 'Components_Zorbax.xlsx');

%% ========== 2. E-Mail Notification Settings ==========
Parameters.Mail.On = false;
Parameters.Mail.Receiver = [""];
Parameters.Mail.Sender = "";

%% ========== 3. Database Configuration ==========
Parameters.database.host = '';     % should be localhost
Parameters.database.port = '';     % should be 5432
Parameters.database.dbname = '';
Parameters.database.username = ''; % should be postgres
Parameters.database.password = ''; % should be encrypted
Parameters.database.schema = 'parameters'; % do not change

%% ========== 4. MS1 Processing Settings ==========
Parameters.MS1.min_S_N_maximum = 5;
Parameters.MS1.min_Level_in_S_N = 2;
Parameters.MS1.min_points_over_Level = 5;
Parameters.MS1.XICtolerance_ppm = 20;
Parameters.MS1.NoiseDistancetoPeakMax_sec = 15;
Parameters.MS1.noisewindowInSec = 15;
Parameters.MS1.Noise_default = 15;
Parameters.MS1.MSDataRange = [1, 30];

%% ========== 5. MS2 Processing Settings ==========
Parameters.MS2.libname = "lib1";
Parameters.MS2.minIntensity = 20;          % Remove noise during MS2 check
Parameters.MS2.minIntensityRelative = 5;   % Minimum intensity during library generation
Parameters.MS2.mzTolerance_ppm = 20;
Parameters.MS2.binWidth = 0.5;
Parameters.MS2.binOffset = 0.2;
Parameters.MS2.threshold = 10;
Parameters.MS2.removePrecursor = true;     % During generation and check
Parameters.MS2.From = 1;                   % 1 = from MS data
Parameters.path.MS2_ReferencePath = "";    % Path for MS2 library reference samples (standards)

%% ========== 6. Chromatography Settings ==========
Parameters.chroma.RTToleranceInSec = 9;
Parameters.chroma.TypeforRTCorr = 'Roth';
Parameters.chroma.MeasurementTime_min = 37;
Parameters.chroma.maxdaydistanceforRTcorr = 30;
Parameters.chroma.RTcorrON = true;

%% ========== 7. Data Pre-Treatment ==========
Parameters.pre_treatment.Savitzky.on = true;
Parameters.pre_treatment.Savitzky.windowsize = 5;
Parameters.pre_treatment.Savitzky.loops = 2;

Parameters.pre_treatment.Gaussian.on = false;
Parameters.pre_treatment.Gaussian.sigma = 0.8;
Parameters.pre_treatment.Gaussian.kernelSize = 6;

%% ========== 8. Device Control Settings ==========
Parameters.DeviceControl.interval_days = 60;
Parameters.DeviceControl.RT_upperLimit = 10;
Parameters.DeviceControl.RT_lowerLimit = -10;
Parameters.DeviceControl.intensity_upperLimit = 2;
Parameters.DeviceControl.intensity_lowerLimit = 0.5;
Parameters.DeviceControl.massaccuracy = 10;
Parameters.DeviceControl.minimumISneg = 6;
Parameters.DeviceControl.minimumISpos = 9;

%% ========== 9. Task Manager Settings ==========
Parameters.TaskManager.On = false;
Parameters.TaskManager.Interval = 5;
Parameters.TaskManager.GuiOn = true;

%% ========== 10. Database Table Definitions ==========
% SampleMaster table
Names = {'SampleID', 'polarity', 'type', 'datetime_aq', 'datetime_samp', 'ISCheck', 'RTCorrection'}';
DataTypes = {'VARCHAR', 'CHAR', 'VARCHAR', 'timestamp without time zone', 'timestamp without time zone', 'BOOLEAN', 'DOUBLE PRECISION'}';
Lengths = {[], 1, 10, [], [], [], []}';
Scales = {[], [], [], [], [], [], []}';
NotNull = {true, true, true, true, false, false, false}';
PrimaryKey = {true, false, false, false, false, false, false}';

tableMeta = table(Names, DataTypes, Lengths, Scales, NotNull, PrimaryKey);
Parameters.database.tables.SampleMaster = tableMeta;

% ISValue table
Names = { ...
    'SampID', 'ID', 'Name', 'RT', 'foundRT', 'normRT', 'deltaRT', 'intensity', 'normIntensities', ...
    'identificationConfidence', 'similarity', 'massaccuracy', 'ISCheck', 'IS', ...
    'EICScanTime', 'EICIntensity', 'PeakMaxMSmz', 'PeakMaxMSintensity', 'MS2mz', 'MS2_intensity'}';
DataTypes = { ...
    'VARCHAR', 'VARCHAR', 'VARCHAR', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', ...
    'VARCHAR', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'BOOLEAN', 'BOOLEAN', ...
    'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]'}';
Lengths = {100, 10, 100, [], [], [], [], [], [], 35, [], [], [], [], [], [], [], [], [], []}';
Scales = {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []}';
NotNull = {true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}';
PrimaryKey = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}';

tableMeta = table(Names, DataTypes, Lengths, Scales, NotNull, PrimaryKey);
Parameters.database.tables.ISValue = tableMeta;

% ComponentValue table
Names = { ...
    'SampID', 'ID', 'Name', 'RT', 'foundRT', 'normRT', 'deltaRT', 'intensity', 'normIntensities', ...
    'identificationConfidence', 'similarity', 'massaccuracy', ...
    'EICScanTime', 'EICIntensity', 'noise', 'baseline', 'peakwindow', 'noisewindow', ...
    'PeakMaxMSmz', 'PeakMaxMSintensity', 'MS2mz', 'MS2_intensity'}';
DataTypes = { ...
    'VARCHAR', 'VARCHAR', 'VARCHAR', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION', ...
    'VARCHAR', 'DOUBLE PRECISION', 'DOUBLE PRECISION', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'INTEGER', 'INTEGER', ...
    'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', ...
    'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]', 'DOUBLE PRECISION[]'}';
Lengths = {100, 10, 150, [], [], [], [], [], [], 35, [], [], [], [], [], [], [], [], [], [], [], []}';
Scales = {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []}';
NotNull = {true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}';
PrimaryKey = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false}';

tableMeta = table(Names, DataTypes, Lengths, Scales, NotNull, PrimaryKey);
Parameters.database.tables.ComponentValue = tableMeta;

% Warnings table
Names = {'datetime', 'String', 'Warning_type'}';
DataTypes = {'timestamp without time zone', 'VARCHAR', 'VARCHAR'}';
Lengths = {[], [], 20}';
Scales = {[], [], []}';
NotNull = {true, true, false}';
PrimaryKey = {false, false, false}';

tableMeta = table(Names, DataTypes, Lengths, Scales, NotNull, PrimaryKey);
Parameters.database.tables.Warnings = tableMeta;

%% Save final Parameters struct
save(fullfile(Parameters.path.program, 'data', 'Import', 'methods', 'Parameters.mat'), 'Parameters');


