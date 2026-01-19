% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function filtered_ms_data = ms_data_window(ms_data, Window_sec)
%MS_DATA_WINDOW  Filter MS data by a retention time window.
%
%   filtered_ms_data = ms_data_window(ms_data, Window_sec)
%   Returns only those MS data entries whose retention times fall within
%   the specified time window.
%
%   Inputs:
%     ms_data    - Struct array containing MS data. Each element must have
%                  a field:
%                    .retentionTime  - Retention time in minutes
%     Window_sec - Two-element vector [start end] defining the time window
%                  in seconds (e.g. [200 400])
%
%   Output:
%     filtered_ms_data - Struct array containing only entries within the
%                        specified retention time window
%

    % Find indices of MS entries within the specified retention time window
    ind = find( ...
        [ms_data.retentionTime] >= (Window_sec(1) / 60) & ...
        [ms_data.retentionTime] <= (Window_sec(2) / 60) ...
    );

    % Extract matching entries
    filtered_ms_data = ms_data(ind);
end
