function str = convertUmlauts(str)
%CONVERTUMLAUTS  Replace German umlauts and ß with ASCII equivalents.
%   Converts German special characters (ä, ö, ü, Ä, Ö, Ü, ß)
%   into their respective ASCII-friendly substitutions.
%
%   Input:
%     str - Input string (char or string array)
%
%   Output:
%     str - Converted string with all umlauts replaced
%
%   Example:
%     convertUmlauts("Fäßchen") returns "Faesschen"
%
    str = strrep(str, 'ä', 'ae');
    str = strrep(str, 'Ä', 'Ae');
    str = strrep(str, 'ö', 'oe');
    str = strrep(str, 'Ö', 'Oe');
    str = strrep(str, 'ü', 'ue');
    str = strrep(str, 'Ü', 'Ue');
    str = strrep(str, 'ß', 'ss');
end

