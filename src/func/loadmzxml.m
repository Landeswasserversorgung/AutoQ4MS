function [ms1_data, ms2_data] = loadmzxml(outputFilePath)
%LOADMZXML  Read mzXML files and extract MS1 and MS2 scan data.
%
%   [ms1_data, ms2_data] = loadmzxml(outputFilePath)
%   Uses the helper function readmzXML to load MS1 and MS2 level data from
%   an mzXML file and organizes the results into structured arrays.
%
%   Input:
%     outputFilePath - Full path to the mzXML file
%
%   Outputs:
%     ms1_data - Struct array with fields:
%                  .retentionTime  - Retention time in minutes
%                  .polarity       - Scan polarity
%                  .ScanData       - [m/z, intensity] matrix
%
%     ms2_data - Struct array with fields:
%                  .retentionTime  - Retention time in minutes
%                  .PrecursorMass  - Precursor m/z
%                  .polarity       - Scan polarity
%                  .ScanData       - [m/z, intensity] matrix

    disp('Loading MS data');

    %% MS1 data extraction
    % Read MS1-level scans
    [ScanData, retentionTime, polarity] = readmzXML(outputFilePath, 'MSLevel', 1);

    % Initialize output structure
    ms1_data = struct('retentionTime', [], 'polarity', [], 'ScanData', []);

    for i = 1:numel(retentionTime)
        ms1_data(i).retentionTime = retentionTime(i) / 60; % seconds → minutes
        ms1_data(i).polarity      = polarity(i);
        ms1_data(i).ScanData      = ScanData{i, 1};
    end

    disp('MS1 data loaded');

    %% MS2 data extraction
    % Read MS2-level scans
    [ScanData2, retentionTime2, polarity2, PrecursorMass] = readmzXML(outputFilePath, 'MSLevel', 2);

    % Initialize output structure
    ms2_data = struct('retentionTime', [], 'PrecursorMass', [], 'polarity', [], 'ScanData', []);

    for i = 1:numel(retentionTime2)
        ms2_data(i).retentionTime  = retentionTime2(i) / 60; % seconds → minutes
        ms2_data(i).PrecursorMass = PrecursorMass(i);
        ms2_data(i).polarity      = polarity2(i);
        ms2_data(i).ScanData      = ScanData2{i, 1};
    end

    disp('MS2 data loaded');
end


