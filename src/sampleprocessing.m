function processing(methodPath)
% PROCESSING - Runs the MS data processing pipeline.
%
% Prevents parallel execution via a lockfile that is ALWAYS cleaned up.

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

    % --- Create lockfile ---
    fid = fopen(lockfile, 'w');
    if fid < 0
        error('Could not create lockfile: %s', lockfile);
    end
    fclose(fid);

    % --- GUARANTEED cleanup ---
    cleanupLock = onCleanup(@() deleteLockfile(lockfile));

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

        %% Check logs
        logCount = CountlogFiles(fullfile(Parameters.path.program, 'logs'));
        if logCount > 0
            WarningPlusDb( ...
                sprintf('There are %d log files', logCount), ...
                Parameters, 'Processing Setting');
        end

        %% Check failed SQL
        sqlFailCount = CountsqlFiles(fullfile(Parameters.path.program, 'src', 'database', 'failed'));
        if sqlFailCount > 0
            WarningPlusDb( ...
                sprintf('There are %d failed SQL files', sqlFailCount), ...
                Parameters, 'Processing Setting');
        end

        %% Scan for new MS files
        listNewFilePaths = ListAllFinishedFiles( ...
            Parameters.path.MSDataSource, ...
            Parameters.path.savedMSData);

        filteredPaths = listNewFilePaths( ...
            endsWith(listNewFilePaths, Parameters.General.MSdataending));
        filteredPaths = filteredPaths(~contains(filteredPaths, 'PreRun'));

        if isempty(filteredPaths)
            disp('No new MS data found');
            return;   % 🔒 lockfile still cleaned automatically
        end

        fprintf('%d MS data sets found\n', numel(filteredPaths));

        %% Sort & process
        sortedFilePaths = sortFilesByModificationDate(filteredPaths, Parameters);

        for w = 1:numel(sortedFilePaths)
            fprintf('Processing %d / %d\n', w, numel(sortedFilePaths));
            FilePath = sortedFilePaths(w);

            sampleprocessing(FilePath, Parameters);
            CopyMatchingNameParts( ...
                FilePath, ...
                Parameters.path.savedMSData, ...
                Parameters.path.MSDataSource);
        end

        disp('Processing finished');

    catch e
        disp('Error in Processing');
        rethrow(e);   % 🔒 lockfile still cleaned
    end
end


%% --- Helper --------------------------------------------------------------
function deleteLockfile(lockfile)
    if exist(lockfile, 'file')
        delete(lockfile);
    end
end



