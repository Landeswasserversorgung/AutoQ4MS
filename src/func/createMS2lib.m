function [] = createMS2lib(Parameters)
%% get Parameters
%load("C:\Users\micha\OneDrive\Matlab\Data\Parameters.mat"); % Structure with parameters with which the programme runs

% get folder path
% get parameters
% load('C:\Transfer\MTSlite\data\Import\methods\Parameters.mat', 'Parameters');
folderpath = Parameters.path.program;
librarypath = Parameters.path.program + "\data\Import\mslib\" + Parameters.MS2.libname;
% librarypath = 'C:\Transfer\MTSlite\data\Import\mslib\lib3';% Library measurements
if exist(librarypath, 'dir')
    choice = input("The library " + Parameters.MS2.libname + " already exists. Overwrite it? (y/n): ",'s');
    if strcmpi(choice, 'y')
        rmdir(librarypath, 's');  % Remove the existing directory and its contents
        mkdir(librarypath);
    else
        disp('Operation cancelled by user.');
        return
    end
else
    mkdir(librarypath);
end

mzXMLpath = Parameters.MS2.ReferencePath;%'I:\MS2LPH\mzXML_MS2_Test'; % for testing only

addpath(Parameters.path.program +'\src\func');
% Define tolerances
retentionTimeTolerance = Parameters.chroma.RTToleranceInSec *3/60; % 0.4; % Min
precursorMassTolerance = Parameters.MS1.XICtolerance_ppm; %0.05; % Da
% remove Precursor
removePrecursor = Parameters.MS2.removePrecursor; % 1 || 0
minI = Parameters.MS2.minIntensityRelative; % Minimum fragment intensity in percent, relative to the highest fragment including precursor
% Import the reference table

%referenceTable = readtable('C:\Transfer\MTSlite\data\Import\Components_Zorbax.xlsx');
referenceTable = readtable(Parameters.path.CompExcel);
%referenceTableIS = readtable('C:\Transfer\MTSlite\data\Import\InternalStandards_Zorbax.xlsx');
referenceTableIS = readtable(Parameters.path.ISExcel);
% combine tables

missingVars = setdiff(referenceTableIS.Properties.VariableNames, referenceTable.Properties.VariableNames);

% Add the missing columns with default values (e.g., NaN) to referenceTable
for k = 1:length(missingVars)
    referenceTable.(missingVars{k}) =  repmat("undefined", height(referenceTable), 1);
end

% Reorder columns to match referenceTableIS
referenceTable = referenceTable(:, referenceTableIS.Properties.VariableNames);

% Now concatenate the tables
referenceTable = [referenceTable; referenceTableIS];

% Initialize column for ms2 spectra
referenceTable.ScanData_pos = cell(height(referenceTable),1);
referenceTable.ScanData_neg = cell(height(referenceTable),1);
% Backup empty reference table
referenceTable_Empty = referenceTable;
% Get list of mzXML files in folderpath
filePattern = fullfile(mzXMLpath, '*.mzXML');
mzXMLFiles = dir(filePattern);
% define samples --> Matches file name and result table, each sample
%samples = {'AIO'};




%% Loop through all mzXML files and process them
for k = 1:length(mzXMLFiles)
    baseFileName = mzXMLFiles(k).name;
    fullFileName = fullfile(mzXMLpath, baseFileName);
    sample = strtok(mzXMLFiles(k).name,'.');
    sample = matlab.lang.makeValidName(sample);
    uniqueName_ms1 = ["ms1_data_",sample];
    uniqueName_ms1 = strjoin(uniqueName_ms1,"");
    uniqueName_ms2 = ["ms2_data_",sample];
    uniqueName_ms2 = strjoin(uniqueName_ms2,"");
    sampleID = sample;
       

  
    % Load mzXML file

    [ms1_data, ms2_data] = loadmzxml(fullFileName);
   
    % Dynamically save the loaded data with unique variable names
    assignin('base', uniqueName_ms1, ms1_data);
    assignin('base', uniqueName_ms2, ms2_data);
    
    fprintf('Processed %s and saved as %s and %s\n', baseFileName, uniqueName_ms1, uniqueName_ms2);
  
    
    %% Compare ms2_data to Reference Table
    % Reset reference Table
    currentREF = ["Json_",sampleID,'_','referenceTable'];
    currentREF = strjoin(currentREF,"");
    % Check if the variable exists in the workspace !!!!!!
    isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', (currentREF)));
    %sVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', currentREF));
    %sVarInWorkspace = evalin('base', ['exist(''', currentREF, ''', ''var'')']);

    if isVarInWorkspace
        referenceTable = evalin('base', currentREF);
    else
        referenceTable = referenceTable_Empty;
    end
    for ii=1:2
        for i = 1:height(referenceTable)
        % Get reference values
        refRetentionTime = referenceTable.RT(i);
        if ii==1 % Positive
            refPrecursorMass = referenceTable.mz_pos(i);
            refPolarity = "+";
            
        elseif ii==2 % Negative
            refPrecursorMass = referenceTable.mz_neg(i);
            refPolarity = "-";
        end
            for h = 1:length(ms2_data)
                % Get ms2_data values
                ms2RetentionTime = ms2_data(h).retentionTime;
                ms2PrecursorMass = ms2_data(h).PrecursorMass;
                ms2Polarity = ms2_data(h).polarity;
        
                % Check conditions for matches
                if abs(ms2RetentionTime - refRetentionTime) <= retentionTimeTolerance && ...
                   abs(ms2PrecursorMass - refPrecursorMass) <= precursorMassTolerance && ...
                   strcmp(ms2Polarity, refPolarity)
        
                    %isInternalStandard = contains(referenceTable.Mix(i), 'Istd');
                    %isMixMatch = contains(uniqueName_ms2, referenceTable.Mix(i));
        
                    %if isMixMatch || isInternalStandard
                        % If match, copy ScanData to the corresponding line in the Reference table
                        if refPolarity == "+"
                            if isempty(referenceTable.ScanData_pos{i})
                                referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                                fprintf('Match found for %s; Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                            else
                                a = max(referenceTable.ScanData_pos{i}(:,2));
                                b = max(ms2_data(h).ScanData(:,2));
                                if b >= a
                                    referenceTable.ScanData_pos{i} = ms2_data(h).ScanData;
                                    fprintf('Better Match found for %s: Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                                end
                            end
                        elseif refPolarity == "-"
                            if isempty(referenceTable.ScanData_neg{i})
                                referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                                fprintf('Match found for %s; Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                            else
                                a = max(referenceTable.ScanData_neg{i}(:,2));
                                b = max(ms2_data(h).ScanData(:,2));
                                if b >= a
                                    referenceTable.ScanData_neg{i} = ms2_data(h).ScanData;
                                    fprintf('Better Match found for %s: Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                                end
                            end

                        end
                    %end
                end
            end
        end
    end
% Save sample specific reference Table
sampleREF = currentREF;
sampleREF = strjoin(sampleREF,"");
assignin('base', sampleREF, referenceTable);
end
%% Get all reference tables
% Get all variables in the workspace
allVars = evalin('base', 'who');

% Filter variables containing '_referenceTable'
matchingVars = allVars(contains(allVars, '_referenceTable'));
%% Delete zeroes and Precursor from MS2 Spectra
for i = 1:length(matchingVars)
    % Dynamically retrieve the variable using eval
    tableData = evalin('base',matchingVars{i});
    for ij=1:2 % both polarities
        for j = 1:height(tableData)
            if ij==1 %positive  
                ms2 = tableData.ScanData_pos{j};
                PrecursorMass= tableData.mz_pos(j);
            elseif ij==2 %negative
                ms2 = tableData.ScanData_neg{j};
                PrecursorMass= tableData.mz_neg(j);
            end

            if ~isempty(ms2)
                ms2 = MS2cleanup(ms2,precursorMassTolerance,PrecursorMass,removePrecursor,minI);
                % handle transposed spectra (can happen if only one row
                % remains after cleanup)
                if height(ms2)==2 && width(ms2)==1
                    ms2=transpose(ms2);
                end
                % assign MS2 to table
                if ij==1 %positive 
                    tableData.ScanData_pos{j} = ms2;
                elseif ij==2 %negative
                    tableData.ScanData_neg{j} = ms2;  
                end
                
                % Create Json files from spectra
                % Convert the array to a JSON-formatted string
                jsonString = jsonencode(ms2);
                % enfoce 2D Arrays, if only one fragment is detected
                if height(ms2)==1 && width(ms2)==2
                    jsonStringB = ["[",jsonString,"]"];
                    jsonStringB = strjoin(jsonStringB,"");
                    jsonString = char(jsonStringB);
                end
                % Define the filename
                if ij==1
                    adduct = tableData.Adduct_pos{j};
                elseif ij==2
                    adduct = tableData.Adduct_neg{j};
                end
                filename = [librarypath,"\",tableData.ID{j},adduct,".json"];
                filename = strjoin(filename,"");
                
                % Write the JSON string to the file
                fid = fopen(filename, 'w');
                if fid == -1
                    error('Cannot create JSON file');
                end
                fwrite(fid, jsonString, 'char');
                fclose(fid);
        
                % Save as sample specific _referenceTable
                assignin('base', matchingVars{i}, tableData);
            end
        end
    end
end

%% Done
fprintf('Evaluation Completed! \n');
% Export Sample Reference Tables
for i = 1:length(matchingVars)
    % Dynamically retrieve the variable using eval
    tableData = evalin('base',matchingVars{i});
    %save matlab
    filename = [librarypath,"\",matchingVars{i},'.mat'];
    filename = strjoin(filename,"");
    save(filename,'tableData');
    % save excel
    tableData.ScanData_pos = []; % For compatibility in .xlsx
    tableData.ScanData_neg = []; % For compatibility in .xlsx
    filename = [librarypath,"\",matchingVars{i},'.xlsx'];
    filename = strjoin(filename,"");
    writetable(tableData, filename);
end

end