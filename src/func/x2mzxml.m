% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function outputFilePath = x2mzxml(sourceFile_path, NewFileName, Parameters)
%X2MZXML  Convert raw MS data to mzXML using ProteoWizard msconvert.
%
%   outputFilePath = x2mzxml(sourceFile_path, NewFileName, Parameters)
%   Calls the ProteoWizard msconvert command-line tool to convert a raw MS
%   dataset (e.g., .wiff) into mzXML format. The conversion applies filters
%   such as peak picking and scan time cropping.
%
%   Inputs:
%     sourceFile_path - Full path to the source file to be converted
%     NewFileName     - Base name for the output file (without extension)
%                       (Note: may be overwritten based on sourceFile_path)
%     Parameters      - Project parameters struct containing:
%                       Parameters.path.proteoWizard
%                       Parameters.MS1.MSDataRange  (minutes)
%
%   Output:
%     outputFilePath  - Path to the created mzXML file if detected from
%                       msconvert output, otherwise ''.
%

    outputFilePath = '';

    % Derive output directory and base filename from source path
    [outputDir, NewFileName, ~] = fileparts(sourceFile_path);

    % Path to msconvert executable
    msconvertPath = Parameters.path.proteoWizard;

    % Build msconvert command with filters
    cmd = sprintf([ ...
        '"%s" --mzXML --64 --zlib ' ...
        '--filter "peakPicking vendor msLevel=1-2" ' ...
        '--filter "msLevel 1-2" ' ...
        '--filter "scanTime [%s,%s]" ' ...
        '-o "%s" --outfile "%s.mzXML" "%s"' ...
        ], ...
        msconvertPath, ...
        string(Parameters.MS1.MSDataRange(1) * 60), ...
        string(Parameters.MS1.MSDataRange(2) * 60), ...
        outputDir, ...
        NewFileName, ...
        sourceFile_path);

    disp('Conversion in progress...');

    % Execute msconvert
    [status, cmdout] = system(cmd); %#ok<ASGLU>
    disp(cmdout);

    % Try to extract the created file path from msconvert output
    startIndex = strfind(cmdout, 'writing output file:');

    if ~isempty(startIndex)
        outputFilePath = strtrim(cmdout(startIndex + length('writing output file:') : end));
        disp(outputFilePath);
        disp('Conversion completed');
    else
        disp('Error during conversion. Output file path not found.');
    end
end
