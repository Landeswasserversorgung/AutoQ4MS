% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

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
