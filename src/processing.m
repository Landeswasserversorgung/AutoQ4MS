function processing(methodPath)
% PROCESSING - Runs the MS data processing pipeline.
% 
% This function scans for new MS data sets, applies the sample processing
% function, and handles logging and database notifications. It also prevents 
% multiple instances from running simultaneously.
%
% Parameters:
%   methodPath (string): Optional path to a .mat file containing a
%                        'Parameters' struct. If not provided, a default is used.

    clc;
    clearvars -except methodPath;

    %% Prevent multiple instances of the same method
    try
        [~, methodname, ~] = fileparts(methodPath);
    catch
        methodname = 'Parameters';
    end
    
    lockfile = fullfile(tempdir, [char(methodname), '.lock']);
    if exist(lockfile, 'file')
        fprintf('Another instance is already running. Exiting.\n');
        return;
    end
    fclose(fopen(lockfile, 'w'));  % Create lock file

    try

        %% Set working directory to script location
        thisFile = mfilename('fullpath');
        [thisPath, ~, ~] = fileparts(thisFile);
        cd(thisPath);
    
        %% Load Parameters
        if nargin < 1 || isempty(methodPath)
            methodPath = fullfile('..', 'data', 'Import', 'methods', 'Parameters.mat');
        end
    
        if ~isfile(methodPath)
            error('Parameters file not found: %s', methodPath);
        end
    
        disp(methodPath);
        loaded = load(methodPath, 'Parameters');
    
        if ~isfield(loaded, 'Parameters')
            error('The file does not contain a variable named "Parameters".');
        end
        Parameters = loaded.Parameters;
    
        %% Check for existing log files
        logCount = CountlogFiles(fullfile(Parameters.path.program, 'logs'));
        if logCount > 0
            msg = sprintf('There are %d log files in %s', logCount, fullfile(Parameters.path.program, 'logs'));
            WarningPlusDb(msg, Parameters, 'Processing Setting');
        end
    
        %% Check for failed SQL files
        sqlFailCount = CountsqlFiles(fullfile(Parameters.path.program, 'src', 'database', 'failed'));
        if sqlFailCount > 0
            msg = sprintf('There are %d sql files in %s', sqlFailCount, ...
                fullfile(Parameters.path.program, 'src', 'database', 'failed'));
            WarningPlusDb(msg, Parameters, 'Processing Setting');
        end
        
        %% Scan for new MS files
        listNewFilePaths = ListAllFinishedFiles(Parameters.path.MSDataSource, Parameters.path.savedMSData);
    
        % Filter by file extension and remove 'PreRun' files
        filteredPaths = listNewFilePaths(endsWith(listNewFilePaths, Parameters.General.MSdataending));
        filteredPaths = filteredPaths(~contains(filteredPaths, 'PreRun'));
    
        if isempty(filteredPaths)
            disp('No new MS data found');
            disp('******************************************************************');
            pause(5);
            delete(lockfile);
            return;
        else
            disp('New MS data found');
        end
    
        fprintf('%d MS data sets found\n', numel(filteredPaths));
    
        %% Sort files by modification date
        sortedFilePaths = sortFilesByModificationDate(filteredPaths,Parameters);
    
        %% Process each MS file
        for w = 1:numel(sortedFilePaths)
            disp('/////////////////////////////////////////////////////////////////');
            fprintf('Processing MS data set %d/%d\n', w, numel(sortedFilePaths));
            FilePath = sortedFilePaths(w);
    
            % Apply processing logic to one file
            sampleprocessing(FilePath, Parameters);
    
            % Copy the processed data back
            CopyMatchingNameParts(sortedFilePaths(w), Parameters.path.savedMSData, Parameters.path.MSDataSource);
        end
    
        %% Cleanup
        disp('/////////////////////////////////////////////////////////////////////');
        disp('Processing finished');
        disp('******************************************************************');
        pause(5);
        
        
    catch e
        disp('Error in Processing')
        delete(lockfile);  % Remove lock file
        rethrow(e);
    end
 
end
