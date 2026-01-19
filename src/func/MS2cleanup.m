% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Michael Mohr
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function outputArg1 = MS2cleanup(ms2, precursorMassTolerance, PrecursorMass, removePrecursor, minI)
%MS2CLEANUP  Clean and filter an MS2 spectrum.
%
%   output = MS2cleanup(ms2, precursorMassTolerance, PrecursorMass, removePrecursor, minI)
%   Cleans an MS2 spectrum by merging close m/z values, optionally removing
%   precursor ions, and filtering low-intensity fragments.
%
%   Inputs:
%     ms2                   - MS2 spectrum [m/z, intensity]
%     precursorMassTolerance - Tolerance used for merging and precursor removal
%     PrecursorMass          - Precursor m/z value
%     removePrecursor        - Logical flag (1/0) to remove precursor ions
%     minI                   - Minimum relative intensity threshold (in %)
%
%   Output:
%     outputArg1             - Cleaned MS2 spectrum sorted by intensity
%

    if ~isempty(ms2)

        % Merge fragments within tolerance to reduce digital noise
        ms2 = mergetable(ms2, precursorMassTolerance);

        % Maximum fragment intensity
        maxFrag = max(ms2(:,2));

        % Filter fragments
        for k = 1:height(ms2)

            % Remove precursor peak (optional)
            if removePrecursor == 1 && ...
               abs(ms2(k,1) - PrecursorMass) <= (4 * precursorMassTolerance)
                ms2(k,:) = NaN;
            end

            % Remove fragments below minimum relative intensity
            if ms2(k,2) < (minI / 100) * maxFrag
                ms2(k,:) = NaN;
            end
        end

        % Remove rows containing NaN values
        rowsWithNaN = any(isnan(ms2), 2);
        ms2(rowsWithNaN, :) = [];

        % Sort fragments by intensity (descending)
        ms2 = sortrows(ms2, 2, 'descend');

        outputArg1 = ms2;
    end
end
