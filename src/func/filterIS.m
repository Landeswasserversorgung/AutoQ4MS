% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function Table = filterIS(Table, ISdic, ISKey)
%FILTERIS  Filters table columns based on an internal standard (IS) dictionary.
%   Table = filterIS(Table, ISdic, ISKey)
%
%   Removes columns from a data table that are not flagged as valid
%   for the given IS key in the provided dictionary.
%
%   Inputs:
%     Table  - MATLAB table containing measurement data.
%     ISdic  - Structure containing information about internal standards.
%               Each field corresponds to a column name from Table.
%     ISKey  - String or field name within each ISdic entry used as a logical filter.
%
%   Output:
%     Table  - Filtered table containing only the columns marked as active for ISKey.
%
%   Example:
%     Table = filterIS(Table, ISdic, "UseInCalibration");
%

    for col = Table.Properties.VariableNames
        if strcmp(col{1}, 'datetime_aq')
            continue; % keep acquisition timestamp column
        end
        if ~ISdic(col{1}).(ISKey)
            Table.(col{1}) = []; % remove column if not selected in dictionary
        end
    end
end
