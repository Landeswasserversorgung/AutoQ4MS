% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function [newscanTimes, newionIntensities] = EICWindow(scanTimes, ionIntensities, lower_time_Sec, upper_time_Sec)
%EICWINDOW  Extract a time-window subset from EIC data.
%   [newscanTimes, newionIntensities] = EICWindow(scanTimes, ionIntensities, lower_time_Sec, upper_time_Sec)
%   Filters extracted ion chromatogram (EIC) data to include only points
%   whose scan times fall within the specified lower and upper time limits.
%   The input limits are given in seconds and internally converted to minutes,
%   assuming scanTimes are expressed in minutes.
%
%   Inputs:
%     scanTimes       - Vector of scan times (in minutes)
%     ionIntensities  - Vector of corresponding ion intensities
%     lower_time_Sec  - Lower time bound in seconds
%     upper_time_Sec  - Upper time bound in seconds
%
%   Outputs:
%     newscanTimes      - Filtered scan times within the given time window
%     newionIntensities - Filtered ion intensities corresponding to the same window
%
%   Example:
%     [t, I] = EICWindow(scanTimes, ionIntensities, 120, 300);
%

    % Convert the lower and upper bounds from seconds to minutes
    startTime = lower_time_Sec / 60;
    endTime   = upper_time_Sec / 60;

    % Identify indices where scanTimes fall within the desired interval
    intervalIdx = (scanTimes >= startTime) & (scanTimes <= endTime);

    % Apply filtering to both scanTimes and ionIntensities
    newscanTimes      = scanTimes(intervalIdx);
    newionIntensities = ionIntensities(intervalIdx);
end
