function WarningPlusDb(string,Parameters, Warning_type)
%% This Fuction is a Warning function with the add on to write the warning also in the database
% Linus Straehle 2024-05-28
    warning(string);


    
    Warnings.String = string;
    Warnings.datetime= datetime('now');
    Warnings.Warning_type = Warning_type;

    filepath = newsqlfile(Parameters);

    fileID = fopen(filepath, 'w');    
    fprintf(fileID, '%s\n', createSQLInsertCommand(Parameters,'Warnings',Warnings));
    fclose(fileID);
    
    runsqlfile(filepath, Parameters);

end

