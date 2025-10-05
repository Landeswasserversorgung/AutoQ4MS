
%% Setup
% Created by Michael Mohr 20.03.2025
% Adapted from original Script of Linus Strähle and Adrian Haun
clc
clear

%% get Parameters
%load("C:\Users\micha\OneDrive\Matlab\Data\Parameters.mat"); % Structure with parameters with which the programme runs

% get folder path
% get parameters
load('..\data\Import\methods\Parameters.mat', 'Parameters');
folderpath = Parameters.path.import;
%folderpath = 'C:\Users\micha\OneDrive\Matlab\MTS_Lite\MTSlite\data\Import';
%mzXMLpath = '..\data\Import\librarySamples';% Library measurements
librarypath = '..\data\Import\mslib\lib1';% Library measurements
mzXMLpath = 'C:\Users\micha\Arbeit\OnlineQC_Papaer\Jason02'; % for testing only
%librarypath = 'C:\Users\micha\Arbeit\OnlineQC_Papaer\Jason02\test'; % for testing only
addpath('..\src\func');
% Import the reference table
%referenceFile = fullfile(folderpath, 'Components_Zorbax.xlsx');
%referenceTable = readtable(referenceFile);
referenceTable = readtable('..\data\Import\Components_Zorbax.xlsx');
% Import internal standards
%referenceFileIS = fullfile(folderpath, 'InternalStandards_Zorbax.xlsx');
%referenceTableIS = readtable(referenceFileIS);
referenceTableIS = readtable('..\data\Import\InternalStandards_Zorbax.xlsx');
% combine tables
%referenceTable = [referenceTable;referenceTableIS];
% Check for missing columns in referenceTable
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
% generates an individual result
%samples = {'_Mix','AIO','gL'};
samples = {'AIO'};

% Define tolerances
retentionTimeTolerance = 0.4; % Min
precursorMassTolerance = 0.05; % Da
% remove Precursor
removePrecursor = 0; % 1 || 0
minI = 5; % Minimum fragment intensity in percent, relative to the highest fragment including precursor
createPlot = 0;

%% Loop through all mzXML files and process them
for k = 1:length(mzXMLFiles)
    baseFileName = mzXMLFiles(k).name;
    fullFileName = fullfile(mzXMLpath, baseFileName);
    
    test = 0;
    for i=1:length(samples)
        sample = string(samples(i));
        
        if contains(baseFileName,sample) && contains(baseFileName, '_p')
            uniqueName_ms1 = ["ms1_data_",sample,"_p",k];
            uniqueName_ms1 = strjoin(uniqueName_ms1,"");
            uniqueName_ms2 = ["ms2_data_",sample,"_p",k];
            uniqueName_ms2 = strjoin(uniqueName_ms2,"");
            sampleID = sample;
            test =1;
            break;
        elseif contains(baseFileName,sample) && contains(baseFileName, '_n')
            uniqueName_ms1 = ["ms1_data_",sample,"_n",k];
            uniqueName_ms1 = strjoin(uniqueName_ms1,"");
            uniqueName_ms2 = ["ms2_data_",sample,"_n",k];
            uniqueName_ms2 = strjoin(uniqueName_ms2,"");
            sampleID = sample;
            test=1;
            break;
        end
    end
  
    % Load mzXML file
    if test ==1
    [ms1_data, ms2_data] = loadmzxml(fullFileName);
   
    % Dynamically save the loaded data with unique variable names
    assignin('base', uniqueName_ms1, ms1_data);
    assignin('base', uniqueName_ms2, ms2_data);
    
    fprintf('Processed %s and saved as %s and %s\n', baseFileName, uniqueName_ms1, uniqueName_ms2);
    else
        continue;
    end

    
    %% Compare ms2_data to Reference Table
    % Reset reference Table
    currentREF = ["Json_",sampleID,'_','referenceTable'];
    currentREF = strjoin(currentREF,"");
    % Check if the variable exists in the workspace
    isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', (currentREF)));
    if isVarInWorkspace
        referenceTable = eval(currentREF);
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
allVars = who;

% Filter variables containing '_referenceTable'
matchingVars = allVars(contains(allVars, '_referenceTable'));
%% Delete zeroes and Precursor from MS2 Spectra
for i = 1:length(matchingVars)
    % Dynamically retrieve the variable using eval
    tableData = eval(matchingVars{i});
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



%% Alternative Plot MS2 Spectra
% Add a new column for figure handles, initializing as empty cells

if createPlot == 1
    for ih=1:2
        for l = 1:height(tableData)
            % Extract MS2 spectrum data for the current row
            if ih==1 %p
                ms2spec = tableData.ScanData_pos{l};
            elseif ih==2
                ms2spec = tableData.ScanData_neg{l};
            end
            if ~isempty(ms2spec)
                % Create a new figure without displaying it
                fig = figure('Visible', 'off');
                
                % Extract m/z and intensity values
                x = ms2spec(:,1);
                y = ms2spec(:,2);
                if ih==1
                    PrecursorMass = tableData.mz_pos(l);
                elseif ih==2
                    PrecursorMass = tableData.mz_neg(l);
                end
                if ih==1
                    adduct = tableData.Adduct_pos(l);
                elseif ih==2
                    adduct = tableData.Adduct_neg(l);
                end
                % Plot the data using a stem plot
                h=stem(x, y, 'filled', 'MarkerSize', 1); % Example plot
                set(h, 'Color', 'k', 'MarkerFaceColor', 'k');  % Set line and marker color to black
                title(['Precursor ', num2str(PrecursorMass), ' ', tableData.LW_number(l), ' ', adduct]); % Ensure numeric value is converted to string
                
                % Labeling the axes
                xlabel('m/z (Da)');
                ylabel('Intensity (counts)');
                
        
          
        
                 % Add m/z values to each marker, adjusting positions to avoid overlap
                 yOffset = max(y) * 0.02;  % Offset for shifting labels slightly, relative to the plot scale
                
                 for i = 1:length(x)
                    % Default vertical position of the text
                    labelY = zeros(i,1);
                    labelY(i,1) = y(i) + 0*yOffset;
                    
                    % Check for close m/z values (within a threshold) and adjust the label positions
                    if  i>1 && abs(x(i) - x(i-1)) < 0.08*x(i) % Threshold to determine if points are too close
                        labelY(i,1) = y(i) + 2 * yOffset +2*i;  % Increase the offset to avoid overlap  
                    end
                    % Determin if there are three points close to each other
                    if i>2 && abs(x(i) - x(i-2)) < 0.10*x(i)
                        labelY(i,1) = y(i) + 3 * yOffset +3*i;  % Increase the offset to avoid overlap
                    end
                     % Determin if there are four points close to each other
                    if i>3 && abs(x(i) - x(i-3)) < 0.12*x(i)
                        labelY(i,1) = y(i) + 4 * yOffset +4*i;  % Increase the offset to avoid overlap
                    end
                    % Place the m/z value as a label near the marker
                    if labelY(i,1) >= max(y)
                        labelY(i,1) = max(y) - 2*i;
                    end
                    text(x(i), labelY(i), num2str(x(i), '%.3f'), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 6);
                 end
               
                % Define the folder name where the plots will be saved
                folderName = strjoin([string(librarypath),"\",'MS2_Plots'],"");
  
        
                % Check if the folder exists, if not, create it
                if ~exist(folderName, 'dir')
                    mkdir(folderName);
                end
                
                % Generate the file name using PrecursorMass and save the plot as a .png file
                fileName = fullfile(folderName, strjoin([tableData.LW_number(l), '_', 'Precursor_', num2str(PrecursorMass), '.png'],""));
                
                % Save the current figure as a .png file in the specified subfolder
                saveas(fig, fileName);
        
                % Close the figure to prevent it from displaying
                close(fig); 
            end
        end
    end
end
%% Done
fprintf('Evaluation Completed! \n');
% Export Sample Reference Tables
for i = 1:length(matchingVars)
    % Dynamically retrieve the variable using eval
    tableData = eval(matchingVars{i});
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
%writetable(referenceTable, 'norman_Fragments_sum.xlsx');