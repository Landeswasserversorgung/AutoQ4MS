function sampleprocessing(FilePath, Parameters)
%SAMPLEPROCESSING Process a single MS data file from raw input to database entry.
%
% Inputs:
%   FilePath   (string/char, optional)
%       Full path to an MS data file (e.g., .wiff/.wiff2/.mzXML depending on setup).
%   Parameters (struct, optional)
%       Parameters struct loaded from a .mat file.
%
% If either argument is missing, default values are used.

    %% 0) Setup: set current working directory to this file location
    thisFile = mfilename('fullpath');
    [thisPath, ~, ~] = fileparts(thisFile);
    cd(thisPath);

    %% 1) Load Parameters if not provided
    if nargin < 2 || isempty(Parameters)
        paramPath = fullfile('..', 'data', 'Import', 'methods', 'Parameters.mat');
        if ~isfile(paramPath)
            error('Default Parameters.mat file not found: %s', paramPath);
        end
        loaded = load(paramPath, 'Parameters');
        if ~isfield(loaded, 'Parameters')
            error('Loaded file does not contain a "Parameters" struct.');
        end
        Parameters = loaded.Parameters;
    end

    %% 2) Use default file if none provided (for testing only)
    if nargin < 1 || isempty(FilePath)
        % TODO: Remove this hardcoded path before production use.
        FilePath = "";
    end

    %% 3) Convert to mzXML format if necessary
    if strcmp(".mzXML", Parameters.General.MSdataending)
        mzXMLFilePath = FilePath;  % already mzXML
    else
        [~, fileName, ~] = fileparts(FilePath);
        try
            mzXMLFilePath = string(x2mzxml(FilePath, fileName, Parameters));
        catch
            msg = sprintf(['MS data set %s could not be converted ' ...
                           '(it may be incomplete or corrupted). Deleting.'], FilePath);
            WarningPlusDb(msg, Parameters, 'Processing Setting');

            % Only delete if an output file exists
            if exist('mzXMLFilePath', 'var') && isfile(mzXMLFilePath)
                delete(mzXMLFilePath);
            end
            return;
        end
    end

    %% 4) Load MS1 and MS2 data from mzXML
    try
        [ms1_data, ms2_data] = loadmzxml(mzXMLFilePath);
    catch
        msg = sprintf(['MS data set %s could not be loaded ' ...
                       '(it may be incomplete or corrupted). Deleting.'], FilePath);
        WarningPlusDb(msg, Parameters, 'Processing Setting');
        delete(mzXMLFilePath);
        return;
    end

    %% 5) Create Sample object
    Sample1 = Sample(FilePath, ms1_data, ms2_data, Parameters);

    %% 6) Retention time correction and internal standard processing
    Sample1 = Sample1.RTCorrectionFactor(Parameters);
    Sample1.toSQL(Parameters);

    disp('Internal Standards:');
    Sample1 = Sample1.dicpeakdetection("ISdic", ms1_data, Parameters);
    Sample1 = Sample1.dicMS2Check("ISdic", ms2_data, Parameters);
    Sample1.dic2db("ISdic", Parameters);
    Sample1.showdic("ISdic");

    disp('Device Control:');
    Sample1 = Sample1.DeviceControl(Parameters);

    %% 7) Detect and save compounds
    disp('Components:');
    Sample1 = Sample1.dicpeakdetection("Compdic", ms1_data, Parameters);
    Sample1 = Sample1.dicMS2Check("Compdic", ms2_data, Parameters);
    Sample1.showdic("Compdic");
    Sample1.dic2db("Compdic", Parameters);

    %% 8) Optional cleanup
    if Parameters.isOn.deletemzXML
        fprintf('Deleting: %s\n', mzXMLFilePath);
        delete(mzXMLFilePath);
    end
end
