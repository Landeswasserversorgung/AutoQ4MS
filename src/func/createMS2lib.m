function createMS2lib(Parameters)
%CREATEMS2LIB  Build an MS/MS library from reference MS files.
%   Scans reference MS files (recursively), optionally converts them to
%   mzXML, matches MS2 spectra to a reference table using retention time
%   and precursor mass tolerances, and exports JSON/MAT/XLSX outputs per
%   compound/adduct.
%

%% Close leftover waitbars from previous runs
if ~isempty(findall(0,'Type','figure','-and','Tag','TMWWaitbar'))
    delete(findall(0,'Type','figure','-and','Tag','TMWWaitbar'));
end
if ~isempty(findall(0,'Type','figure','-and','Tag','MS2Waitbar'))
    delete(findall(0,'Type','figure','-and','Tag','MS2Waitbar'));
end

%% Load data and tolerances
librarypath  = Parameters.path.program + "\data\Import\mslib\" + Parameters.MS2.libname;
MSFilepath   = Parameters.path.MS2_ReferencePath;

% Tolerances
retentionTimeTolerance = Parameters.chroma.RTToleranceInSec * 3 / 60;  % minutes
precursorMassTolerance = Parameters.MS1.XICtolerance_ppm;              % ppm
removePrecursor        = Parameters.MS2.removePrecursor;               % 1 or 0
minI                   = Parameters.MS2.minIntensityRelative;          % relative min intensity (%)

% Import reference tables
referenceTable   = readtable(Parameters.path.CompExcel);
referenceTableIS = readtable(Parameters.path.ISExcel);

%% Create or overwrite library folder
if exist(librarypath, 'dir')
    % GUI confirmation dialog
    answer = questdlg( ...
        sprintf('The library "%s" already exists.\nDo you want to overwrite it?', Parameters.MS2.libname), ...
        'Library Exists', 'Yes', 'No', 'No');
    
    switch answer
        case 'Yes'
            rmdir(librarypath, 's');
            mkdir(librarypath);
        otherwise
            disp('Operation cancelled by user.');
            return
    end
else
    mkdir(librarypath);
end

%% Harmonize and combine reference tables
missingVars = setdiff(referenceTableIS.Properties.VariableNames, referenceTable.Properties.VariableNames);
for k = 1:numel(missingVars)
    referenceTable.(missingVars{k}) = repmat("undefined", height(referenceTable), 1);
end

referenceTable = referenceTable(:, referenceTableIS.Properties.VariableNames);
referenceTable = [referenceTable; referenceTableIS];

% Initialize columns for matched MS2 spectra
referenceTable.ScanData_pos = cell(height(referenceTable), 1);
referenceTable.ScanData_neg = cell(height(referenceTable), 1);

referenceTable_Empty = referenceTable; % Template

%% Gather all input files recursively
filePattern   = fullfile(MSFilepath, '**', "*" + Parameters.General.MSdataending);
MSFiles       = dir(filePattern);
fullFilePaths = fullfile({MSFiles.folder}, {MSFiles.name})';
nFiles        = numel(fullFilePaths);

if nFiles == 0
    warning('No input files found for pattern: %s', filePattern);
    return
end

%% Progress bar with Cancel option
hWait = waitbar(0, 'Initializing ...', ...
    'Name', 'Building MS2 Library', ...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',true)');
setappdata(hWait, 'canceling', false);
cleanupWB = onCleanup(@() (exist('hWait','var') && isvalid(hWait)) && delete(hWait)); %#ok<NASGU>

%% Main processing loop
for k = 1:nFiles
    if getappdata(hWait, 'canceling')
        disp('Operation cancelled by user.');
        return
    end

    srcPath = fullFilePaths{k};
    disp(srcPath);

    [folder, base, ~] = fileparts(srcPath);
    tgtPath = fullfile(folder, base + ".mzXML");

    % Update progress
    waitbar((k-1)/nFiles, hWait, sprintf('(%d/%d) Checking/Converting: %s', k, nFiles, base));

    % Resolve or convert file
    if exist(tgtPath, 'file')
        mzXMLFilePath = string(tgtPath);
    else
        if strcmpi(Parameters.General.MSdataending, ".mzXML")
            mzXMLFilePath = string(srcPath);
        else
            try
                mzXMLFilePath = string(x2mzxml(srcPath, base, Parameters));
            catch ME
                warning('MS data set %s could not be converted (%s). Skipping.', srcPath, ME.message);
                waitbar(k/nFiles, hWait);
                continue
            end
        end
    end

    % Load mzXML data
    waitbar((k-0.5)/nFiles, hWait, sprintf('(%d/%d) Loading mzXML', k, nFiles));
    [ms1_data, ms2_data] = loadmzxml(mzXMLFilePath);

    % Store in base workspace (legacy behavior)
    uniqueName_ms1 = char("ms1_" + base);
    uniqueName_ms2 = char("ms2_" + base);
    assignin('base', uniqueName_ms1, ms1_data);
    assignin('base', uniqueName_ms2, ms2_data);
    fprintf('Processed %s and saved as %s / %s\n', base, uniqueName_ms1, uniqueName_ms2);

    %% Match MS2 spectra to reference table
    currentREF = char("Json_" + sprintf("Standard_%d", k) + "_referenceTable");
    isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', currentREF));
    if isVarInWorkspace
        referenceTable = evalin('base', currentREF);
    else
        referenceTable = referenceTable_Empty;
    end

    % Two passes: positive & negative
    for ii = 1:2
        for i = 1:height(referenceTable)
            refRetentionTime = referenceTable.RT(i);
            if ii == 1
                refPrecursorMass = referenceTable.mz_pos(i);
                refPolarity      = "+";
            else
                refPrecursorMass = referenceTable.mz_neg(i);
                refPolarity      = "-";
            end

            % Compare to each MS2 entry
            for h = 1:numel(ms2_data)
                ms2RetentionTime = ms2_data(h).retentionTime;
                ms2PrecursorMass = ms2_data(h).PrecursorMass;
                ms2Polarity      = ms2_data(h).polarity;

                % --- Matching criteria ---
                % retention time: minutes
                % precursor mass: ppm → convert to absolute tolerance (Da)
                absTolDa = refPrecursorMass * precursorMassTolerance / 1e6;

                if abs(ms2RetentionTime - refRetentionTime) <= retentionTimeTolerance && ...
                   abs(ms2PrecursorMass - refPrecursorMass) <= absTolDa && ...
                   strcmp(ms2Polarity, refPolarity)

                    % Keep or replace best match (max intensity)
                    if refPolarity == "+"
                        if isempty(referenceTable.ScanData_pos{i})
                            referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                            fprintf('Match for %s; row %d (pos)\n', base, i);
                        else
                            a = max(referenceTable.ScanData_pos{i}(:,2));
                            b = max(ms2_data(h).ScanData(:,2));
                            if b >= a
                                referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                                fprintf('Better match for %s; row %d (pos)\n', base, i);
                            end
                        end
                    else
                        if isempty(referenceTable.ScanData_neg{i})
                            referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                            fprintf('Match for %s; row %d (neg)\n', base, i);
                        else
                            a = max(referenceTable.ScanData_neg{i}(:,2));
                            b = max(ms2_data(h).ScanData(:,2));
                            if b >= a
                                referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                                fprintf('Better match for %s; row %d (neg)\n', base, i);
                            end
                        end
                    end
                end
            end
        end
    end

    % Save updated table to base workspace
    assignin('base', currentREF, referenceTable);
    waitbar(k/nFiles, hWait);
end

% Close progress bar
if isvalid(hWait)
    waitbar(1, hWait, 'Done!');
    pause(0.2);
    delete(hWait);
end

%% Collect all reference tables from base
allVars      = evalin('base', 'who');
matchingVars = allVars(contains(allVars, '_referenceTable'));

%% Cleanup MS2 spectra & export JSON
for i = 1:numel(matchingVars)
    tableData = evalin('base', matchingVars{i});

    for ij = 1:2 % both polarities
        for j = 1:height(tableData)
            if ij == 1
                ms2 = tableData.ScanData_pos{j};
                PrecursorMass = tableData.mz_pos(j);
            else
                ms2 = tableData.ScanData_neg{j};
                PrecursorMass = tableData.mz_neg(j);
            end

            if ~isempty(ms2)
                ms2 = MS2cleanup(ms2, precursorMassTolerance, PrecursorMass, removePrecursor, minI);

                if height(ms2) == 2 && width(ms2) == 1
                    ms2 = transpose(ms2);
                end

                if ij == 1
                    tableData.ScanData_pos{j} = ms2;
                else
                    tableData.ScanData_neg{j} = ms2;
                end

                jsonString = jsonencode(ms2);
                if height(ms2) == 1 && width(ms2) == 2
                    jsonString = ['[', jsonString, ']']; %#ok<AGROW>
                end

                if ij == 1
                    adduct = tableData.Adduct_pos{j};
                else
                    adduct = tableData.Adduct_neg{j};
                end
                filename = strjoin([librarypath, "\", tableData.ID{j}, adduct, ".json"], "");

                fid = fopen(filename, 'w');
                if fid == -1
                    error('Cannot create JSON file: %s', filename);
                end
                fwrite(fid, jsonString, 'char');
                fclose(fid);

                assignin('base', matchingVars{i}, tableData);
            end
        end
    end
end

%% Final export: MAT + Excel per sample
fprintf('Evaluation Completed!\n');
for i = 1:numel(matchingVars)
    tableData = evalin('base', matchingVars{i});

    % Save .mat
    fnMat = strjoin([librarypath, "\", matchingVars{i}, '.mat'], "");
    save(fnMat, 'tableData');

    % Save .xlsx (without MS2 columns)
    tableData.ScanData_pos = [];
    tableData.ScanData_neg = [];
    fnXlsx = strjoin([librarypath, "\", matchingVars{i}, '.xlsx'], "");
    writetable(tableData, fnXlsx);
end

end
