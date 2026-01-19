% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function mode = MS2ModeFromMSdata(PrecursorMassList)
%MS2MODEFROMMSDATA  Determine MS2 acquisition mode (DDA or DIA) from precursor masses.
%
%   mode = MS2ModeFromMSdata(PrecursorMassList)
%   Determines whether MS2 data was acquired in DDA or DIA mode based on
%   the decimal pattern of precursor masses.
%
%   The heuristic assumes DIA data if most precursor masses show a fixed
%   decimal pattern (3rd and 4th decimal places equal to zero).
%
%   Input:
%     PrecursorMassList - Vector of precursor m/z values
%
%   Output:
%     mode              - "DIA" or "DDA"
%

    % Only evaluate the first up to 10 precursor masses
    nCheck = min(10, length(PrecursorMassList));
    precursors = PrecursorMassList(1:nCheck);

    % Count how many precursor masses match the DIA decimal pattern
    countDIApattern = 0;

    for i = 1:nCheck
        if isnan(precursors(i))
            continue;
        end

        % Format mass with four decimal places
        str = sprintf('%.4f', precursors(i));

        % Check if 3rd and 4th decimal places are zero
        if length(str) >= 7 && strcmp(str(end-1:end), '00')
            countDIApattern = countDIApattern + 1;
        end
    end

    % Decision rule
    if countDIApattern >= 8
        mode = "DIA";
    else
        mode = "DDA";
    end
end
