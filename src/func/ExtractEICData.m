% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function [scanTimes, ionIntensities] = ExtractEICData(extracted_ms_data, target_mz, varargin)
%EXTRACTEICDATA  Extracts ion intensities for a specific m/z value across scans.
%   [scanTimes, ionIntensities] = ExtractEICData(extracted_ms_data, target_mz, tolerance)
%
%   This function scans through mass spectrometry (MS) data and sums the
%   ion intensities for all m/z values that fall within a defined tolerance
%   of a target m/z value.
%
%   Inputs:
%     extracted_ms_data - Struct array containing MS scan data.
%                         Each element must include:
%                           .ScanData(:,1): m/z values
%                           .ScanData(:,2): intensity values
%                           .retentionTime : scan time (in minutes)
%     target_mz         - The target m/z value to extract.
%     tolerance (opt.)  - m/z tolerance (absolute). Default = 0.005.
%
%   Outputs:
%     scanTimes        - Vector of retention times for each scan.
%     ionIntensities   - Vector of summed ion intensities within tolerance.
%
%   Example:
%     [t, I] = ExtractEICData(msdata, 445.34, 0.01);
%

    % Handle optional tolerance parameter
    if nargin > 2
        mz_tolerance = varargin{1};
    else
        mz_tolerance = 0.005; % Default m/z tolerance
    end

    numScans = numel(extracted_ms_data);

    % Preallocate result vectors
    ionIntensities = zeros(numScans, 1);
    scanTimes      = zeros(numScans, 1);

    % Iterate through all scans
    for i = 1:numScans
        % Extract m/z and intensity values for current scan
        mzValues        = extracted_ms_data(i).ScanData(:,1);
        intensityValues = extracted_ms_data(i).ScanData(:,2);

        % Logical mask for m/z values within tolerance
        withinTol = abs(mzValues - target_mz) <= mz_tolerance;

        % Sum the intensities for matching peaks
        ionIntensities(i) = sum(intensityValues(withinTol));

        % Store the corresponding retention time
        scanTimes(i) = extracted_ms_data(i).retentionTime;
    end
end
