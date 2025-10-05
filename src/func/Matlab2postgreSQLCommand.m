function Matlab2postgreSQLCommand(SQLCommand, Parameters)
%%  This function Executes an SQL command in the Command window
%   Linus Strähle 2024-05-16

host = Parameters.database.host;
port = Parameters.database.port;
dbname = Parameters.database.dbname;
username  = Parameters.database.username;
psql_path = Parameters.path.psqlExe;

% Path to the .pgpass file
pgpass_dir = fullfile(getenv('APPDATA'), 'postgresql');
pgpass_path = fullfile(pgpass_dir, '.pgpass');

% Create a temporary batch script
batch_file = [tempname, '.bat'];

% Content of the batch script
batch_content = sprintf([
    '@echo off\n' ...
    'set PGPASSFILE=%s\n' ...
    'echo run SQL-Command\n' ...
    '"%s" -h %s -p %s -U %s -d %s -c "%s"\n' ...
    'set PGPASSFILE=\n' ...
], pgpass_path, psql_path, host, port, username, dbname, SQLCommand);

% Write the batch script
fid = fopen(batch_file, 'wt');
if fid == -1
    error('Error opening batch file for writing.');
end
fprintf(fid, '%s', batch_content);
fclose(fid);

% Execute the batch script and capture the output
[status, cmdout] = system(['cmd /C "', batch_file, '"']);

cmdout_utf8 = native2unicode(uint8(cmdout), 'UTF-8');

if (contains(regexprep(cmdout_utf8, '[\r\n]', ''), 'run SQL-CommandINSERT 0')||...
        contains(regexprep(cmdout_utf8, '[\r\n]', ''), 'run SQL-CommandCREATE TABLE')|| ...
        contains(regexprep(cmdout_utf8, '[\r\n]', ''), 'run SQL-CommandCREATE DATABASE'))
    % SQL was executed Sucsessfully
    disp('SQL was executed successfully!');
else
    disp('Command line output:');
    disp(cmdout_utf8);
    error('Error executing the SQL command.');
end


% Delete the temporary batch file
delete(batch_file);
end

pgsqluser


