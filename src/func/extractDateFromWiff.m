function dateTime = extractDateFromWiff(filePath)
%% This function reads a wiff file and extract the Checksum Time 
% Linus Straehle 2024-04-29
    % Open the file in binary read mode
    fileID = fopen(filePath, 'rb');
    
    % Check if the file was successfully opened
    if fileID == -1
        error('File could not be opened. Check the path and permissions.');
    end
    
    % Read the entire content as binary data
    fileContents = fread(fileID, '*uint8');
    fclose(fileID);
    
    % Try to find text segments
    textIndices = fileContents > 31 & fileContents < 127; % ASCII printable characters
    textString = char(fileContents(textIndices)');
    %disp(textString);
    
    % Use a regular expression to search for the date
    pattern = '\[Checksum Time: (.*?)\]';
    tokens = regexp(textString, pattern, 'tokens');
    
    if ~isempty(tokens)
        dateString = tokens{1}{1};  % Extract the first found date
        % Try to parse the date and convert it to a datenum object
        try
            dateNum = datenum(dateString, 'dddd, mmmm dd, yyyy HH:MM:SS');
        catch
            warning('Date could not be converted into a datenum object.');
            dateNum = [];
        end
    else
        disp('No date found.');
        dateNum = [];
    end
    dateTime = datetime(dateNum , 'ConvertFrom', 'datenum');
end
