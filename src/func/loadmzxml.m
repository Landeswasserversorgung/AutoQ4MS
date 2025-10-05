function [ms1_data, ms2_data] = loadmzxml(outputFilePath)
% loadmzxml Reads mzXML files and extracts MS1 and MS2 data
% This function uses the `readmzXML` helper function to read data from mzXML files.
% It specifically extracts MS1 and MS2 level data and organizes them into structured arrays.
% Linus Strähle 2024-04-02
% Inputs:
%   outputFilePath - The path to the mzXML file to be read.
% Outputs:
%   ms1_data - A structured array containing MS1 data, including retention time,
%              polarity, and scan data.
%   ms2_data - A structured array containing MS2 data, including retention time,
%              precursor mass, polarity, and scan data.

disp('loading MS data');

%% MS 1 Data Extraction
% Extract MS1 level data using the readmzXML function with 'MSLevel', 1 option.
[ScanData, retentionTime, polarity] = readmzXML(outputFilePath, 'MSLevel', 1);

% Initialize ms1_data as an empty struct array
ms1_data = struct('retentionTime', [], 'polarity', [], 'ScanData', []);

for i = 1:numel(retentionTime)
    % Fill in ms1_data for each scan with its retention time, polarity, and scan data
    ms1_data(i).retentionTime = retentionTime(i)/60;
    ms1_data(i).polarity = polarity(i);
    ms1_data(i).ScanData = ScanData{i, 1};
end

disp('MS1 data loaded');
%% MS 2 Data Extraction
% Extract MS2 level data using the readmzXML function with 'MSLevel', 2 option.
[ScanData2, retentionTime2, polarity2, PrecursorMass] = readmzXML(outputFilePath, 'MSLevel', 2);

% Initialize ms2_data as an empty struct array
ms2_data = struct('retentionTime', [], 'PrecursorMass', [], 'polarity', [], 'ScanData', []);

for i = 1:numel(retentionTime2)
    % Fill in ms2_data for each scan with its retention time, precursor mass, polarity, and scan data
    ms2_data(i).retentionTime = retentionTime2(i)/60;
    ms2_data(i).PrecursorMass = PrecursorMass(i);
    ms2_data(i).polarity = polarity2(i);
    ms2_data(i).ScanData = ScanData2{i, 1};
end
disp('MS2 data loaded');
end

