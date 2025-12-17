function filepath = newsqlfile(Parameters)
%NEWSQLFILE  Generate a unique SQL file path with a timestamped filename.
%
%   filepath = newsqlfile(Parameters)
%   Creates a new, non-existing SQL filename based on the current timestamp.
%   If a file with the generated name already exists, the timestamp is
%   regenerated until a unique filename is found.
%
%   Input:
%     Parameters - Project parameters struct containing:
%                  Parameters.path.program
%
%   Output:
%     filepath   - Full path to a new SQL file
%

    while true
        % Generate timestamp-based filename
        ts = char(datetime('now', 'Format', 'yyyyMMdd_HHmmssSSS'));
        filepath = fullfile( ...
            Parameters.path.program, ...
            'src', 'database', ...
            ['sql_commands_', ts, '.sql'] ...
        );

        % Ensure the file does not already exist
        if ~isfile(filepath)
            break;
        end

        pause(0.1);
    end
end

