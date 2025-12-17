function MS2Mode = getMS2Mode(Filename)
%GETMS2MODE  Determine MS2 acquisition mode (DDA or DIA) from a filename.
%
%   MS2Mode = getMS2Mode(Filename)
%   Inspects the given filename and returns the MS2 acquisition mode
%   based on the presence of specific substrings.
%
%   The function assumes:
%     - Filenames containing 'DDA' indicate Data-Dependent Acquisition
%     - Filenames containing 'DIA' indicate Data-Independent Acquisition
%
%   Input:
%     Filename - Filename or full file path (string or char)
%
%   Output:
%     MS2Mode  - 'DDA' or 'DIA'
%

    if contains(Filename, 'DDA')
        MS2Mode = 'DDA';
    elseif contains(Filename, 'DIA')
        MS2Mode = 'DIA';
    else
        error('Unknown MS2 mode. Filename must contain "DDA" or "DIA".');
    end

    % If files are not named correctly, uncomment the following line:
    % MS2Mode = 'DDA';
end


