function runsqlfile(filepath, Parameters)
%RUNSQLFILE Executes SQL commands from a file and saves them to a database
%   This function connects to a PostgreSQL database and executes SQL commands
%   from the specified file. If an error occurs, the SQL command file is renamed
%   and saved for further inspection.
%
%   Inputs:
%       Parameters - Structure with the database connection information:
%           Parameters.database.host - Database host
%           Parameters.database.port - Database port
%           Parameters.database.username - Database username
%           Parameters.database.password - Database password
%           Parameters.database.dbname - Database name
%       errorfileName - Name of the file containing the SQL commands
%       Linus Straehle 2024-07-04

    % Display a message indicating that data is being saved to the database
    disp('Saving data in the database');
    try
        % Set the database password as an environment variable
        setenv('PGPASSWORD', Parameters.database.password);
        
        % Build the command to execute the SQL commands from the file
        command = sprintf('"%s" -h "%s" -p "%s" -U "%s" -d "%s" -f "%s"', ...
            Parameters.path.psqlExe, Parameters.database.host, Parameters.database.port, ...
            Parameters.database.username, Parameters.database.dbname, ...
            filepath);
        
        % Execute the command using the system function
        [status, cmdout] = system(command);
        
        % Check if the command executed successfully
        if status == 0
            % Look for common error indications in the output
            if contains(cmdout, 'FEHLER') || contains(cmdout, 'ERROR')
                % If errors are found in the command output, throw an error
                error('Error executing SQL commands.');
            else
                % If no errors are found, display a success message
                disp('SQL commands executed successfully.');
            end
        else
            % If the command did not execute successfully, throw an error
            error('Error executing SQL commands.');
        end
        fclose('all');
        delete(filepath);
    catch
        
        % In case of an error, rename and save the SQL command file for further inspection
        [~, name, ext] = fileparts(filepath);
        filenameWithExtension = name + ext;
        newFilePath = fullfile(char(Parameters.path.program), 'src','database','failed', filenameWithExtension);
        movefile(char(filepath), char(newFilePath), 'f');
        warning('Error in saving the data in the database. The SQL command file was saved under %s', newFilePath);
    end
end


