% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function processing(methodPath)
%PROCESSING Run the MS data processing pipeline.
%
%   This function scans for new MS data sets, processes each sample, handles
%   logging/database notifications, and prevents multiple instances from running
%   simultaneously (via a lock file in the temp directory).
%
%   Input:
%       methodPath (string/char, optional)
%           Path to a .mat file containing a variable named "Parameters".
%           If not provided, the default Parameters.mat is used.

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

        % Filter by file extension and remove "PreRun" files
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

        %% Sort files according to configured order
        sortedFilePaths = sortFilesByModificationDate(filteredPaths, Parameters);

        %% Process each MS file
        for w = 1:numel(sortedFilePaths)
            disp('/////////////////////////////////////////////////////////////////');
            fprintf('Processing MS data set %d/%d\n', w, numel(sortedFilePaths));

            FilePath = sortedFilePaths(w);

            % Apply processing logic to one file
            sampleprocessing(FilePath, Parameters);

            % Copy processed data back to the archive folder
            CopyMatchingNameParts(sortedFilePaths(w), Parameters.path.savedMSData, Parameters.path.MSDataSource);
        end

        %% Cleanup
        disp('/////////////////////////////////////////////////////////////////////');
        disp('Processing finished');
        disp('******************************************************************');
        pause(5);
        delete(lockfile);

    catch e
        disp('Error in Processing');
        delete(lockfile);  % Remove lock file on error
        rethrow(e);
    end
end
