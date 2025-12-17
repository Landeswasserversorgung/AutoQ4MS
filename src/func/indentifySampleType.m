function type = identifySampleType(filename)
%IDENTIFYSAMPLETYPE  Identify the sample type based on the filename.
%
%   type = identifySampleType(filename)
%   Determines the sample type by searching for predefined keywords
%   within the given filename. If no keyword is found, the default
%   type 'Samp' is returned.
%
%   Input:
%     filename - Filename or full file path (string or char)
%
%   Output:
%     type     - Identified sample type (string), e.g. 'Blank', 'Cal', 'QC'
%

    % Default sample type
    type = 'Samp';

    % Keywords used to identify sample types
    searchString = {'Blank', 'Cal', 'AIO-Mix', 'Mix', 'PreRun', 'Roth', 'QC'};

    % Search for known identifiers in the filename
    for i = 1:length(searchString)
        if contains(filename, searchString{i})
            type = searchString{i};
            break;
        end
    end
end
