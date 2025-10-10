function createMS2lib(Parameters)
% CREATE MS2 LIBRARY
% Builds an MS/MS library by scanning reference MS files, optionally
% converting them to mzXML, matching MS2 spectra to a reference table, and
% exporting JSON/MAT/XLSX outputs per compound/adduct.

%% Kill any leftover waitbars from previous runs
if ~isempty(findall(0,'Type','figure','-and','Tag','TMWWaitbar'))
    delete(findall(0,'Type','figure','-and','Tag','TMWWaitbar'));
end
if ~isempty(findall(0,'Type','figure','-and','Tag','MS2Waitbar'))
    delete(findall(0,'Type','figure','-and','Tag','MS2Waitbar'));
end

%% Load Data and Tolerances 
librarypath  = Parameters.path.program + "\data\Import\mslib\" + Parameters.MS2.libname;
MSFilepath   = Parameters.path.MS2_ReferencePath;

% Tolerances
retentionTimeTolerance = Parameters.chroma.RTToleranceInSec * 3 / 60;  % minutes
precursorMassTolerance = Parameters.MS1.XICtolerance_ppm;              % unit as provided in Parameters
removePrecursor        = Parameters.MS2.removePrecursor;               % 1 or 0
minI                   = Parameters.MS2.minIntensityRelative;          % relative min intensity (%)

% Import reference tables
referenceTable   = readtable(Parameters.path.CompExcel);
referenceTableIS = readtable(Parameters.path.ISExcel);

%% Create / overwrite library folder
if exist(librarypath, 'dir')
    % Small GUI confirmation instead of console input
    answer = questdlg( ...
        sprintf('The library "%s" already exists.\nDo you want to overwrite it?', Parameters.MS2.libname), ...
        'Library Exists', ...
        'Yes', 'No', 'No');   % Default is 'No'
    
    switch answer
        case 'Yes'
            rmdir(librarypath, 's');   % remove directory and contents
            mkdir(librarypath);
        otherwise
            disp('Operation cancelled by user.');
            return
    end
else
    mkdir(librarypath);
end

%% Harmonize and combine reference tables
% Add any missing variables so both tables share identical columns
missingVars = setdiff(referenceTableIS.Properties.VariableNames, referenceTable.Properties.VariableNames);
for k = 1:numel(missingVars)
    referenceTable.(missingVars{k}) = repmat("undefined", height(referenceTable), 1);
end

% Reorder columns to match referenceTableIS, then concatenate
referenceTable = referenceTable(:, referenceTableIS.Properties.VariableNames);
referenceTable = [referenceTable; referenceTableIS];

% Initialize columns to hold matched MS2 spectra
referenceTable.ScanData_pos = cell(height(referenceTable), 1);
referenceTable.ScanData_neg = cell(height(referenceTable), 1);

% Keep an empty template to re-seed per sample
referenceTable_Empty = referenceTable;

%% Gather all input files (recursive)
filePattern   = fullfile(MSFilepath, '**', "*" + Parameters.General.MSdataending);
MSFiles       = dir(filePattern);
fullFilePaths = fullfile({MSFiles.folder}, {MSFiles.name})';
nFiles        = numel(fullFilePaths);

if nFiles == 0
    warning('No input files found for pattern: %s', filePattern);
    return
end

%% Progress bar (with Cancel button)
hWait = waitbar(0, 'Initializing ...', ...
    'Name', 'Building MS2 Library', ...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',true)');
setappdata(hWait, 'canceling', false);

% Ensure the waitbar is closed on any exit (error/return)
cleanupWB = onCleanup(@() (exist('hWait','var') && isvalid(hWait)) && delete(hWait));

%% Main loop: process each MS file
for k = 1:nFiles
    % Cancel support
    if getappdata(hWait, 'canceling')
        disp('Operation cancelled by user.');
        return
    end

    srcPath = fullFilePaths{k};
    disp(srcPath);

    [folder, base, ~] = fileparts(srcPath);
    tgtPath = fullfile(folder, base + ".mzXML");  % expected mzXML output path

    % Update progress text/value
    waitbar((k-1)/nFiles, hWait, sprintf('(%d/%d) Checking/Converting: %s', k, nFiles, base));

    % Resolve mzXML path: use existing file, direct if already mzXML, or convert
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
                % Move progress forward even if skipped
                waitbar(k/nFiles, hWait);
                continue
            end
        end
    end
f
    % Optional progress text for loading
    waitbar((k-0.5)/nFiles, hWait, sprintf('(%d/%d) Loading mzXML', k, nFiles));

    % Load mzXML data
    [ms1_data, ms2_data] = loadmzxml(mzXMLFilePath);

    % Stash loaded variables in base workspace with unique names (your original behavior)
    uniqueName_ms1 = char("ms1_" + sample);
    uniqueName_ms2 = char("ms2_" + sample);
    assignin('base', uniqueName_ms1, ms1_data);
    assignin('base', uniqueName_ms2, ms2_data);
    fprintf('Processed %s and saved as %s and %s\n', base, uniqueName_ms1, uniqueName_ms2);

    %% Match MS2 spectra to reference rows
    currentREF = char("Json_" + sprintf("Standard_%d", k) + "_referenceTable");

    % Use a sample-specific reference table if it already exists in base
    isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', currentREF));
    if isVarInWorkspace
        referenceTable = evalin('base', currentREF);
    else
        referenceTable = referenceTable_Empty;
    end

    % Two passes: positive and negative polarity
    for ii = 1:2
        for i = 1:height(referenceTable)
            % Reference values
            refRetentionTime = referenceTable.RT(i);
            if ii == 1
                refPrecursorMass = referenceTable.mz_pos(i);
                refPolarity      = "+";
            else
                refPrecursorMass = referenceTable.mz_neg(i);
                refPolarity      = "-";
            end

            % Scan all MS2 entries in the file
            for h = 1:numel(ms2_data)
                ms2RetentionTime = ms2_data(h).retentionTime;
                ms2PrecursorMass = ms2_data(h).PrecursorMass;
                ms2Polarity      = ms2_data(h).polarity;

                % Matching criteria
                if abs(ms2RetentionTime - refRetentionTime) <= retentionTimeTolerance && ...
                   abs(ms2PrecursorMass - refPrecursorMass) <= precursorMassTolerance && ...
                   strcmp(ms2Polarity, refPolarity)

                    % If a match is found, keep the spectrum; if multiple matches
                    % occur, retain the one with the higher max intensity.
                    if refPolarity == "+"
                        if isempty(referenceTable.ScanData_pos{i})
                            referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                            fprintf('Match for %s; updated row %d (pos)\n', base, i);
                        else
                            a = max(referenceTable.ScanData_pos{i}(:,2));
                            b = max(ms2_data(h).ScanData(:,2));
                            if b >= a
                                referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                                fprintf('Better match for %s; updated row %d (pos)\n', base, i);
                            end
                        end
                    else % negative
                        if isempty(referenceTable.ScanData_neg{i})
                            referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                            fprintf('Match for %s; updated row %d (neg)\n', base, i);
                        else
                            a = max(referenceTable.ScanData_neg{i}(:,2));
                            b = max(ms2_data(h).ScanData(:,2));
                            if b >= a
                                referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                                fprintf('Better match for %s; updated row %d (neg)\n', base, i);
                            end
                        end
                    end
                end
            end
        end
    end

    % Save the (possibly updated) sample-specific reference table to base
    assignin('base', currentREF, referenceTable);

    % Advance progress after finishing this file
    waitbar(k/nFiles, hWait);
end

% Close progress bar nicely
if isvalid(hWait)
    waitbar(1, hWait, 'Done!');
    pause(0.2);
    delete(hWait);
end

%% Collect all sample-specific reference tables from base workspace
allVars      = evalin('base', 'who');
matchingVars = allVars(contains(allVars, '_referenceTable'));

%% Clean MS2 spectra (remove zeros/precursor), export JSONs
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

                % Handle transposed spectra (can occur if one row remains)
                if height(ms2) == 2 && width(ms2) == 1
                    ms2 = transpose(ms2);
                end

                % Write cleaned spectrum back
                if ij == 1
                    tableData.ScanData_pos{j} = ms2;
                else
                    tableData.ScanData_neg{j} = ms2;
                end

                % Export JSON (force 2D array if only one fragment)
                jsonString = jsonencode(ms2);
                if height(ms2) == 1 && width(ms2) == 2
                    jsonString = ['[', jsonString, ']']; %#ok<AGROW>
                end

                % Build JSON filename (ID + adduct)
                if ij == 1
                    adduct = tableData.Adduct_pos{j};
                else
                    adduct = tableData.Adduct_neg{j};
                end
                filename = strjoin([librarypath, "\", tableData.ID{j}, adduct, ".json"], "");

                % Write JSON to disk
                fid = fopen(filename, 'w');
                if fid == -1
                    error('Cannot create JSON file: %s', filename);
                end
                fwrite(fid, jsonString, 'char');
                fclose(fid);

                % Push table back to base (keeps it in sync)
                assignin('base', matchingVars{i}, tableData);
            end
        end
    end
end

%% Final export: MAT + Excel per sample
fprintf('Evaluation Completed!\n');
for i = 1:numel(matchingVars)
    tableData = evalin('base', matchingVars{i});

    % Save as .mat
    fnMat = strjoin([librarypath, "\", matchingVars{i}, '.mat'], "");
    save(fnMat, 'tableData');

    % Save as .xlsx (drop MS2 cells for compatibility)
    tableData.ScanData_pos = [];
    tableData.ScanData_neg = [];
    fnXlsx = strjoin([librarypath, "\", matchingVars{i}, '.xlsx'], "");
    writetable(tableData, fnXlsx);
end

end
% function createMS2lib(Parameters)
% 
% %% Load Data and Tolerances 
% librarypath = Parameters.path.program + "\data\Import\mslib\" + Parameters.MS2.libname;
% MSFilepath = Parameters.MS2.ReferencePath; 
% % MSFilepath = Parameters.path.MS2_ReferencePath; %%--> New Name
% 
% % Define tolerances
% retentionTimeTolerance = Parameters.chroma.RTToleranceInSec *3/60; % 0.4; % Min
% precursorMassTolerance = Parameters.MS1.XICtolerance_ppm; %0.05; % Da
% % remove Precursor
% removePrecursor = Parameters.MS2.removePrecursor; % 1 || 0
% minI = Parameters.MS2.minIntensityRelative; % Minimum fragment intensity in percent, relative to the highest fragment including precursor
% % Import the reference table
% referenceTable = readtable(Parameters.path.CompExcel);
% referenceTableIS = readtable(Parameters.path.ISExcel);
% 
% %% Check if the Library already exist
% if exist(librarypath, 'dir')
%     % Dialogfenster anzeigen
%     answer = questdlg( ...
%         sprintf('The library "%s" already exists.\nDo you want to overwrite it?', Parameters.MS2.libname), ...
%         'Library Exists', ...   % Titel des Fensters
%         'Yes', 'No', 'No');     % Buttons (Standard ist 'No')
% 
%     switch answer
%         case 'Yes'
%             rmdir(librarypath, 's');  % Entfernt das vorhandene Verzeichnis samt Inhalt
%             mkdir(librarypath);
%         case 'No'
%             disp('Operation cancelled by user.');
%             return
%     end
% else
%     mkdir(librarypath);
% end
% 
% %% 
% 
% 
% % combine tables
% missingVars = setdiff(referenceTableIS.Properties.VariableNames, referenceTable.Properties.VariableNames);
% 
% % Add the missing columns with default values (e.g., NaN) to referenceTable
% for k = 1:length(missingVars)
%     referenceTable.(missingVars{k}) =  repmat("undefined", height(referenceTable), 1);
% end
% 
% % Reorder columns to match referenceTableIS
% referenceTable = referenceTable(:, referenceTableIS.Properties.VariableNames);
% 
% % Now concatenate the tables
% referenceTable = [referenceTable; referenceTableIS];
% 
% % Initialize column for ms2 spectra
% referenceTable.ScanData_pos = cell(height(referenceTable),1);
% referenceTable.ScanData_neg = cell(height(referenceTable),1);
% % Backup empty reference table
% referenceTable_Empty = referenceTable;
% 
% 
% % Alle Dateien mit gewünschter Endung (rekursiv)
% filePattern   = fullfile(MSFilepath, '**', "*" + Parameters.General.MSdataending);
% MSFiles       = dir(filePattern);
% fullFilePaths = fullfile({MSFiles.folder}, {MSFiles.name})';
% 
% hWait = waitbar(0, 'Initialisiere ...', ...
%     'Name', 'Erstelle MS2-Bibliothek', ...
%     'CreateCancelBtn', 'setappdata(gcbf,''canceling'',true)');
% setappdata(hWait, 'canceling', false);
% 
% % dafür sorgen, dass das Fenster bei Fehler/Return sicher zugeht
% cleanupWB = onCleanup(@() (exist('hWait','var') && isvalid(hWait)) && delete(hWait));
% 
% 
% %% Loop through all msfiles and process them if necessary
% for k = 1:length(fullFilePaths)
%     disp(fullFilePaths{k})
%     [folder, base, ~] = fileparts(fullFilePaths{k});
%     tgtPath = fullfile(folder, base + ".mzXML");  % Zielpfad der mzXML-Datei
%     waitbar((k-1)/nFiles, hWait, sprintf('(%d/%d) Prüfe/Konvertiere: %s', k, nFiles, base));
% 
% 
%     % Falls die Zieldatei schon existiert: übernehmen und weiter
%     if exist(tgtPath, 'file')
%         mzXMLFilePath = string(tgtPath);
% 
%     else
%         % Wenn die Eingabedatei bereits .mzXML ist: direkt übernehmen
%         if strcmpi(Parameters.General.MSdataending, ".mzXML")
%             mzXMLFilePath = string(fullFilePaths{k});
%         else
%             % Andernfalls konvertieren
%             try
%                 mzXMLFilePath = string(x2mzxml(fullFilePaths{k}, base, Parameters));
%             catch ME
%                 warning('MS data set %s could not be converted (%s). Skipping.', fullFilePaths{k}, ME.message);
%                 continue;
%             end
%         end
%     end
% 
%     sample = strtok(base,'.');
%     sample = matlab.lang.makeValidName(sample);
%     uniqueName_ms1 = ["ms1_data_",sample];
%     uniqueName_ms1 = strjoin(uniqueName_ms1,"");
%     uniqueName_ms2 = ["ms2_data_",sample];
%     uniqueName_ms2 = strjoin(uniqueName_ms2,"");
%     sampleID = sample;
% 
% 
%     % Load mzXML file
%     [ms1_data, ms2_data] = loadmzxml(mzXMLFilePath);
% 
%     % Dynamically save the loaded data with unique variable names
%     assignin('base', uniqueName_ms1, ms1_data);
%     assignin('base', uniqueName_ms2, ms2_data);
% 
%     fprintf('Processed %s and saved as %s and %s\n', base, uniqueName_ms1, uniqueName_ms2);
% 
% 
%     %% Compare ms2_data to Reference Table
%     % Reset reference Table
%     currentREF = ["Json_",sampleID,'_','referenceTable'];
%     currentREF = strjoin(currentREF,"");
%     % Check if the variable exists in the workspace !!!!!!
%     isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', (currentREF)));
%     %sVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', currentREF));
%     %sVarInWorkspace = evalin('base', ['exist(''', currentREF, ''', ''var'')']);
% 
%     if isVarInWorkspace
%         referenceTable = evalin('base', currentREF);
%     else
%         referenceTable = referenceTable_Empty;
%     end
%     for ii=1:2
%         for i = 1:height(referenceTable)
%         % Get reference values
%         refRetentionTime = referenceTable.RT(i);
%         if ii==1 % Positive
%             refPrecursorMass = referenceTable.mz_pos(i);
%             refPolarity = "+";
% 
%         elseif ii==2 % Negative
%             refPrecursorMass = referenceTable.mz_neg(i);
%             refPolarity = "-";
%         end
%             for h = 1:length(ms2_data)
%                 % Get ms2_data values
%                 ms2RetentionTime = ms2_data(h).retentionTime;
%                 ms2PrecursorMass = ms2_data(h).PrecursorMass;
%                 ms2Polarity = ms2_data(h).polarity;
% 
%                 % Check conditions for matches
%                 if abs(ms2RetentionTime - refRetentionTime) <= retentionTimeTolerance && ...
%                    abs(ms2PrecursorMass - refPrecursorMass) <= precursorMassTolerance && ...
%                    strcmp(ms2Polarity, refPolarity)
% 
%                     %isInternalStandard = contains(referenceTable.Mix(i), 'Istd');
%                     %isMixMatch = contains(uniqueName_ms2, referenceTable.Mix(i));
% 
%                     %if isMixMatch || isInternalStandard
%                         % If match, copy ScanData to the corresponding line in the Reference table
%                         if refPolarity == "+"
%                             if isempty(referenceTable.ScanData_pos{i})
%                                 referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
%                                 fprintf('Match found for %s; Updated row %d of Reference table with ScanData from %s\n', base, i, uniqueName_ms2);
%                             else
%                                 a = max(referenceTable.ScanData_pos{i}(:,2));
%                                 b = max(ms2_data(h).ScanData(:,2));
%                                 if b >= a
%                                     referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
%                                     fprintf('Better Match found for %s: Updated row %d of Reference table with ScanData from %s\n', base, i, uniqueName_ms2);
%                                 end
%                             end
%                         elseif refPolarity == "-"
%                             if isempty(referenceTable.ScanData_neg{i})
%                                 referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
%                                 fprintf('Match found for %s; Updated row %d of Reference table with ScanData from %s\n', base, i, uniqueName_ms2);
%                             else
%                                 a = max(referenceTable.ScanData_neg{i}(:,2));
%                                 b = max(ms2_data(h).ScanData(:,2));
%                                 if b >= a
%                                     referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
%                                     fprintf('Better Match found for %s: Updated row %d of Reference table with ScanData from %s\n', base, i, uniqueName_ms2);
%                                 end
%                             end
% 
%                         end
%                     %end
%                 end
%             end
%         end
%     end
% % Save sample specific reference Table
% sampleREF = currentREF;
% sampleREF = strjoin(sampleREF,"");
% assignin('base', sampleREF, referenceTable);
% end
% 
% if isvalid(hWait)
%     waitbar(1, hWait, 'Fertig!');
%     pause(0.2);  % kurzes visuelles Feedback
%     delete(hWait);
% end
% %% Get all reference tables
% % Get all variables in the workspace
% allVars = evalin('base', 'who');
% 
% % Filter variables containing '_referenceTable'
% matchingVars = allVars(contains(allVars, '_referenceTable'));
% %% Delete zeroes and Precursor from MS2 Spectra
% for i = 1:length(matchingVars)
%     % Dynamically retrieve the variable using eval
%     tableData = evalin('base',matchingVars{i});
%     for ij=1:2 % both polarities
%         for j = 1:height(tableData)
%             if ij==1 %positive  
%                 ms2 = tableData.ScanData_pos{j};
%                 PrecursorMass= tableData.mz_pos(j);
%             elseif ij==2 %negative
%                 ms2 = tableData.ScanData_neg{j};
%                 PrecursorMass= tableData.mz_neg(j);
%             end
% 
%             if ~isempty(ms2)
%                 ms2 = MS2cleanup(ms2,precursorMassTolerance,PrecursorMass,removePrecursor,minI);
%                 % handle transposed spectra (can happen if only one row
%                 % remains after cleanup)
%                 if height(ms2)==2 && width(ms2)==1
%                     ms2=transpose(ms2);
%                 end
%                 % assign MS2 to table
%                 if ij==1 %positive 
%                     tableData.ScanData_pos{j} = ms2;
%                 elseif ij==2 %negative
%                     tableData.ScanData_neg{j} = ms2;  
%                 end
% 
%                 % Create Json files from spectra
%                 % Convert the array to a JSON-formatted string
%                 jsonString = jsonencode(ms2);
%                 % enfoce 2D Arrays, if only one fragment is detected
%                 if height(ms2)==1 && width(ms2)==2
%                     jsonStringB = ["[",jsonString,"]"];
%                     jsonStringB = strjoin(jsonStringB,"");
%                     jsonString = char(jsonStringB);
%                 end
%                 % Define the filename
%                 if ij==1
%                     adduct = tableData.Adduct_pos{j};
%                 elseif ij==2
%                     adduct = tableData.Adduct_neg{j};
%                 end
%                 filename = [librarypath,"\",tableData.ID{j},adduct,".json"];
%                 filename = strjoin(filename,"");
% 
%                 % Write the JSON string to the file
%                 fid = fopen(filename, 'w');
%                 if fid == -1
%                     error('Cannot create JSON file');
%                 end
%                 fwrite(fid, jsonString, 'char');
%                 fclose(fid);
% 
%                 % Save as sample specific _referenceTable
%                 assignin('base', matchingVars{i}, tableData);
%             end
%         end
%     end
% end
% 
% %% Done
% fprintf('Evaluation Completed! \n');
% % Export Sample Reference Tables
% for i = 1:length(matchingVars)
%     % Dynamically retrieve the variable using eval
%     tableData = evalin('base',matchingVars{i});
%     %save matlab
%     filename = [librarypath,"\",matchingVars{i},'.mat'];
%     filename = strjoin(filename,"");
%     save(filename,'tableData');
%     % save excel
%     tableData.ScanData_pos = []; % For compatibility in .xlsx
%     tableData.ScanData_neg = []; % For compatibility in .xlsx
%     filename = [librarypath,"\",matchingVars{i},'.xlsx'];
%     filename = strjoin(filename,"");
%     writetable(tableData, filename);
% end
% 
% end
