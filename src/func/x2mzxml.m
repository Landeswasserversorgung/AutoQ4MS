function outputFilePath = x2mzxml(sourceFile_path, NewFileName, Parameters)
% wiff2mzxml Converts .wiff files to .mzXML format using ProteoWizard's msconvert
%
% This function calls the ProteoWizard msconvert command line tool to convert
% a specified .wiff file to .mzXML format, applying several filters including
% peak picking and scan time filtering.
%
% Inputs:
%   sourceFile_path - The full path to the source .wiff file to be converted.
%   NewFileName        - The base name for the output file (without extension).
%   outputDir       - The directory where the converted file will be saved.
%   msconvertPath   - The full path to the msconvert executable.
%
% Output:
%   outputFilePath  - The full path to the converted .mzXML file.
outputFilePath = '';

% outputDir = Parameters.path.MSDataprocessing;
[outputDir, NewFileName, ~] = fileparts(sourceFile_path);
msconvertPath = Parameters.path.proteoWizard;
% Construct the command to call msconvert with specified options and filters
cmd = sprintf('"%s" --mzXML --64 --zlib --filter "peakPicking vendor msLevel=1-2" --filter "msLevel 1-2" --filter "scanTime [%s,%s]" -o "%s" --outfile "%s.mzXML" "%s"', ...
              msconvertPath,string(Parameters.MS1.MSDataRange(1)*60),string(Parameters.MS1.MSDataRange(2)*60), outputDir, NewFileName, sourceFile_path);
disp('Conversion in progress...');

% Execute the msconvert command
[status, cmdout] = system(cmd);
disp(cmdout);

% Try to extract the path to the newly created file from the command output
startIndex = strfind(cmdout, 'writing output file:');
% Check if the substring was found
if ~isempty(startIndex)
    % Extract everything after the substring
    outputFilePath = strtrim(cmdout(startIndex+length('writing output file:'):end));
    
    % Display the extracted path
    disp(outputFilePath);
    disp('Conversion completed');
else
    disp('Error during conversion. Output file path not found.');
end
end


