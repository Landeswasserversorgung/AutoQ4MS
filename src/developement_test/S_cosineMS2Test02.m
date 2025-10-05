clc
clear
%%
%spectra1 = [100.0,0;151.0,18;200.5,17]; %Sample
%spectra2 = [100.0,400;151.0,900;200.5,600]; %Reference
%varnames = ["mz","intensity"];
%spectra1=array2table(spectra1, 'VariableNames', varnames);
%spectra2=array2table(spectra2, 'VariableNames', varnames);

% Define bin width (adjust based on resolution)
binWidth = 0.5;
binOffset = 0.2; % to keep organic substances in the same bin
threshold = 10; % minimum intensity to match spectra
% Define tolerances
retentionTimeTolerance = 0.2; % to assign ms2

precursorMassTolerance = 0.05; % to assign ms2
minI = 5; % Minimum fragment intensity in percent, relative to the highest fragment including precursor
%% import library
load('C:\Users\micha\OneDrive\Matlab\MS2 Library\Library2_Positivelist_withPrecursor.mat');
load("C:\Users\micha\OneDrive\Matlab\MTSpro-V3\data\Import\Parameters.mat");
assignin('base', "referenceTable", Mit_Precursor2_gL_referenceTable);
clear Mit_Precursor2_gL_referenceTable;
% Backup empty reference table
referenceTable_Empty = referenceTable;
%% import samples
folderpath = "C:\Users\micha\Arbeit\OnlineQC_Papaer\mzXML\AIO_5ug";
% Get list of mzXML files in folderpath
filePattern = fullfile(folderpath, '*.mzXML');
mzXMLFiles = dir(filePattern);
createPlot = 1;
samples = {'Mix4_1000ngL'};
removePrecursor = 0;
%% Loop through all mzXML files and process them
for k = 1:length(mzXMLFiles)
    baseFileName = mzXMLFiles(k).name;
    fullFileName = fullfile(folderpath, baseFileName);
    %validName = matlab.lang.makeValidName(baseFileName);
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
    currentREF = ["Comparison_",sampleID,'_','referenceTable'];
    currentREF = strjoin(currentREF,"");
    % Check if the variable exists in the workspace
    isVarInWorkspace = evalin('base', sprintf('exist(''%s'', ''var'')', (currentREF)));
    if isVarInWorkspace
        referenceTable = eval(currentREF);
    else
        referenceTable = referenceTable_Empty;
    end
    for i = 1:height(referenceTable)
    % Get reference values
    refRetentionTime = referenceTable.retentionTime(i);
    refPrecursorMass = referenceTable.PrecursorMass(i);
    refPolarity = referenceTable.polarity{i}; % Assuming Polarity is stored as string

    for h = 1:length(ms2_data)
        % Get ms2_data values
        ms2RetentionTime = ms2_data(h).retentionTime;
        ms2PrecursorMass = ms2_data(h).PrecursorMass;
        ms2Polarity = ms2_data(h).polarity;

        % Check conditions for matches
        if abs(ms2RetentionTime - refRetentionTime) <= retentionTimeTolerance && ...
           abs(ms2PrecursorMass - refPrecursorMass) <= precursorMassTolerance && ...
           strcmp(ms2Polarity, refPolarity)
            
           %referenceTable.referenceTable.ScanDataSamp{i} = ms2_data(h).ScanData; 
           
                %If match, copy ScanData to the corresponding line in the Reference table
                if ~ismember("ScanDataSample",referenceTable.Properties.VariableNames)
                    referenceTable.ScanDataSample(:) = cell(1);
                end
                if isempty(referenceTable.ScanDataSample{i})
                    referenceTable.ScanDataSample{i} = ms2_data(h).ScanData;
                    fprintf('Match found for %s; Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                else
                    a = max(referenceTable.ScanDataSample{i}(:,2));
                    b = max(ms2_data(h).ScanData(:,2));
                    if b >= a
                        referenceTable.ScanDataSample{i} = ms2_data(h).ScanData;
                        fprintf('Better Match found for %s: Updated row %d of Reference table with ScanData from %s\n', baseFileName, i, uniqueName_ms2);
                    end
                end
            %end
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
% %% Delete zeroes and Precursor from MS2 Spectra
% for i = 1:length(matchingVars)
%     % Dynamically retrieve the variable using eval
%     tableData = eval(matchingVars{i});
%     for j = 1:height(tableData)
%         ms2 = tableData.ScanDataSample{j};
%         if ~isempty(ms2)
%             ms2=mergetable(ms2,precursorMassTolerance);
%             maxFrag = max(ms2(:,2));
%             for k = 1:height(ms2)
%                 if removePrecursor==1 && abs(ms2(k,1) - tableData.PrecursorMass(j))<= (4*precursorMassTolerance) % Remove precursor
%                     ms2(k,:) = NaN;
%                 end
%                 if ms2(k,2) < (minI/100)*maxFrag % Minimum intensity
%                     ms2(k,:) = NaN;
% 
%                 end
%             end
% 
%         % Delete NaN rows
% 
%         rowswithNaN =any(isnan(ms2),2);
%         ms2(rowswithNaN,:) = [];
%         % Sort fragments by intensity
%         ms2=sortrows(ms2,2,'descend');
%         tableData.ScanDataSample{j} = ms2;
% 
%         % Remove all but x fragments
%         end
%         ms2Lib = tableData.ScanData{j};
%         % Create strings from fragments Sample
%         if ~isempty(ms2)
%             frags = ms2(:,1);
%             fragstringSamp = strjoin(arrayfun(@num2str, frags, 'UniformOutput', false), '; ');
%             tableData.fragstringSamp{j} = fragstringSamp;
%             int = ms2(:,2);
%             intstringSamp = strjoin(arrayfun(@num2str, int, 'UniformOutput', false), '; ');
%             tableData.intstringSamp{j} = intstringSamp;
%         end
%         % Create strings from fragments Library
%         if ~isempty(ms2Lib)
%             fragsLib = ms2Lib(:,1);
%             fragstringLib = strjoin(arrayfun(@num2str, fragsLib, 'UniformOutput', false), '; ');
%             tableData.fragstringLib{j} = fragstringLib;
%             intLib = ms2Lib(:,2);
%             intstringLib = strjoin(arrayfun(@num2str, intLib, 'UniformOutput', false), '; ');
%             tableData.intstringLib{j} = intstringLib;
%         end
%         % Save as sample specific _referenceTable
%         assignin('base', matchingVars{i}, tableData);
% 
%     end
% end


%% run function


for m=1:length(matchingVars)
    tableData2 = eval(matchingVars{m});
    for n=1:height(tableData2)
         if ~isempty(tableData2.ScanDataSample{n}) && ~isempty(tableData2.ScanData{n})
            sampleSpec =tableData2.ScanDataSample{n};
            librarySpec =tableData2.ScanData{n};
            % get cosine similarity
            precursorMass = tableData2.PrecursorMass(n);
            XIC_tolerance_ppm = Parameters.MS1.XICtolerance_ppm;
            [cosine_similarity,fragMatch] = cosineMS2(sampleSpec,librarySpec,binWidth,binOffset, threshold,XIC_tolerance_ppm,removePrecursor,precursorMass);
            tableData2.cosineSimilarity(n) = cosine_similarity;
            tableData2.fragMatch(n) = fragMatch;
            % plot MS2 Sample (top) against reference (bottom)
            xLib = librarySpec(:,1);
            xSamp = sampleSpec(:,1);
            yLib = librarySpec(:,2);
            ySamp = sampleSpec(:,2);
            yLibMirror = -yLib;
            % Create figure
            fig=figure;
            hold on;
            stem(xSamp,ySamp,'b','DisplayName','Sample', 'MarkerSize', 1);
            stem(xLib,yLibMirror,'r','DisplayName','Library', 'MarkerSize', 1);
            hold off;
            % Set x axis to the middle of the plot
            yMax = max([abs(ySamp); abs(yLibMirror)]);
            ylim([-yMax*1.05, yMax*1.05]);
            % add labels
            xlabel('m/z (Da)','FontSize',8);
            ylabel('Intensity (cts)','FontSize',8);
            titleName = strjoin([tableData2.Substance(n),"_","ESI",tableData2.polarity(n)," ","Cosine_Similarity: ",cosine_similarity],"");
            title(titleName,'Interpreter','none','FontSize',8);
            legend('Location', 'northwest','FontSize',8);
            grid on;
            % Generate the file name using PrecursorMass and save the plot as a .png file
            uniqueName = strjoin([tableData2.Substance(n) '_' 'Precursor_' num2str(tableData2.PrecursorMass(n))],"");
            validfileName = matlab.lang.makeValidName(uniqueName);
            fileName = fullfile(folderpath, [validfileName '.png']);
           
            % Save the current figure as a .png file in the specified subfolder
            saveas(fig, fileName);
            
            
         end
         close all;
    end
    % remove arrays for export
    tableData3 = tableData2;
    tableData3.ScanData =[];
    tableData3.ScanDataSample =[];
    tableData3.fragstring =[];
    tableData3.intstring = [];
    tableName = strjoin([folderpath,"\",matchingVars{m},".xlsx"],"");
    writetable(tableData3,tableName);
end

