% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Michael Mohr
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function [cosineScore, fragMatchSummary] = cosineMS2(spectra1, spectra2, binWidth, binOffset, threshold, massTolerance_ppm, removePrecursor, ms2PrecursorMass)
%COSINEMS2  Compute cosine similarity between two MS/MS spectra.
%   Calculates a binned cosine similarity between a sample spectrum (spectra1)
%   and a reference spectrum (spectra2). Spectra are cleaned, optionally
%   removing the precursor, then binned onto a common m/z grid. Low-intensity
%   fragments can be filtered based on the relative dynamic range between
%   spectra to mitigate undetectable peaks.
%
%   Inputs:
%     spectra1, spectra2    - Nx2 double arrays [m/z, intensity]
%     binWidth              - Bin width for the common m/z grid (same units as m/z)
%     binOffset             - Offset for the grid start (same units as m/z)
%     threshold             - Intensity threshold (after scaling by intratio logic)
%     massTolerance_ppm     - Mass tolerance in ppm (used during cleanup)
%     removePrecursor       - Logical flag to remove precursor-related peaks
%     ms2PrecursorMass      - Precursor m/z (used in cleanup if removal is enabled)
%
%   Outputs:
%     cosineScore           - Cosine similarity (scalar double in [0,1])
%     fragMatchSummary      - Fragment match summary as string "k of n"
%


    %% Early exits and tolerance base
    if isempty(spectra1) && isempty(spectra2)
        cosineScore = 0;
        fragMatchSummary = "No Data";
        return;
    end

    if ~isempty(spectra2)
        baseMzMax = max(spectra2(:,1));
    else
        baseMzMax = max(spectra1(:,1));
    end
    massTolerance = baseMzMax * massTolerance_ppm / 1e6;

    %% Cleanup spectra
    minI = 5; % 5% of the most intense fragment

    if ~isempty(spectra1) && width(spectra1) == 2
        spectra1 = MS2cleanup(spectra1, massTolerance, ms2PrecursorMass, removePrecursor, minI);
    elseif width(spectra1) == 1 && height(spectra1) == 2
        spectra1 = transpose(spectra1);
        spectra1 = MS2cleanup(spectra1, massTolerance, ms2PrecursorMass, removePrecursor, minI);
    end

    if ~isempty(spectra2) && width(spectra2) == 2
        spectra2 = MS2cleanup(spectra2, massTolerance, ms2PrecursorMass, removePrecursor, minI);
    elseif width(spectra2) == 1 && height(spectra2) == 2
        spectra2 = transpose(spectra2);
        spectra2 = MS2cleanup(spectra2, massTolerance, ms2PrecursorMass, removePrecursor, minI);
    end

    %% Extract m/z and intensity columns
    mz1 = spectra1(:,1);
    intensity1 = spectra1(:,2);
    mz2 = spectra2(:,1);
    intensity2 = spectra2(:,2);

    %% Build common m/z grid and bin intensities
    common_mz = (min([mz1; mz2]) - binOffset) : binWidth : max([mz1; mz2]);
    [~, binIdx1] = min(abs(mz1 - common_mz), [], 2);
    [~, binIdx2] = min(abs(mz2 - common_mz), [], 2);

    intensity1_binned = zeros(size(common_mz));
    intensity2_binned = zeros(size(common_mz));

    for i = 1:numel(mz1)
        intensity1_binned(binIdx1(i)) = intensity1_binned(binIdx1(i)) + intensity1(i);
    end
    for i = 1:numel(mz2)
        intensity2_binned(binIdx2(i)) = intensity2_binned(binIdx2(i)) + intensity2(i);
    end

    %% Intensity thresholding
    max1 = max(intensity1_binned);
    max2 = max(intensity2_binned);
    if max2 == 0 && max1 == 0
        cosineScore = 0;
        fragMatchSummary = "0 of 0";
        return;
    end
    intratio = max1 / max(max2, eps);

    if intratio < 1
        for i = 1:numel(intensity2_binned)
            if intensity2_binned(i) * intratio <= threshold
                intensity2_binned(i) = 0;
            end
            if intensity1_binned(i) <= threshold
                intensity1_binned(i) = 0;
            end
        end
    elseif intratio > 1
        for i = 1:numel(intensity1_binned)
            if intensity1_binned(i) / intratio <= threshold
                intensity1_binned(i) = 0;
            end
            if intensity2_binned(i) <= threshold
                intensity2_binned(i) = 0;
            end
        end
    else
        intensity1_binned(intensity1_binned <= threshold) = 0;
        intensity2_binned(intensity2_binned <= threshold) = 0;
    end

    %% Cosine similarity
    dot_product = sum(intensity1_binned .* intensity2_binned);
    magnitude1  = sqrt(sum(intensity1_binned .^ 2));
    magnitude2  = sqrt(sum(intensity2_binned .^ 2));
    denom = magnitude1 * magnitude2;

    if denom == 0
        cosine_similarity = 0;
    else
        cosine_similarity = dot_product / denom;
        cosine_similarity = max(0, min(1, cosine_similarity)); % Clamp to [0,1]
    end

    %% Fragment match statistics
    matchCount = 0;
    libCount   = 0;
    for i = 1:numel(intensity2_binned)
        if intensity2_binned(i) > 0
            libCount = libCount + 1;
        end
        if intensity2_binned(i) > 0 && intensity1_binned(i) > 0
            matchCount = matchCount + 1;
        end
    end

    fragMatchSummary = sprintf("%d of %d", matchCount, libCount);
    cosineScore = cosine_similarity;

end
