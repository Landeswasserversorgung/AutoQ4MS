function [RT_peak_max_min, peak_max_intensity, noisewindow, peakwindow, noise, NoiseCheck, baseline] = MS1Check( ...
    scanTimes, ionIntensities, Parameters, Component_RT, isblank)
%MS1CHECK  Evaluate an MS1 extracted ion chromatogram (EIC) peak against noise criteria.
%
%   [RT_peak_max_min, peak_max_intensity, noisewindow, peakwindow, noise, NoiseCheck, baseline] = MS1Check( ...
%       scanTimes, ionIntensities, Parameters, Component_RT, isblank)
%
%   This function searches for the maximum peak near an expected retention time
%   and evaluates it against noise-based criteria (signal-to-noise threshold
%   and minimum number of points above a secondary threshold).
%
%   Inputs:
%     scanTimes       - Scan times (minutes)
%     ionIntensities  - Ion intensities corresponding to scanTimes
%     Parameters      - Project parameters struct, expects at least:
%                       Parameters.chroma.RTToleranceInSec
%                       Parameters.MS1.NoiseDistancetoPeakMax_sec
%                       Parameters.MS1.noisewindowInSec
%                       Parameters.MS1.min_S_N_maximum
%                       Parameters.MS1.min_Level_in_S_N
%                       Parameters.MS1.min_points_over_Level
%                       Parameters.MS1.Noise_default
%     Component_RT    - Expected component retention time (minutes)
%     isblank         - Logical flag; if true, uses a larger peak finding window
%
%   Outputs:
%     RT_peak_max_min     - Retention time of the detected peak maximum (minutes), NaN if < LoD
%     peak_max_intensity  - Baseline-corrected peak maximum intensity, NaN if < LoD
%     noisewindow         - Selected noise window [start_sec, end_sec] in seconds (left or right)
%     peakwindow          - Peak window [min_time_min, max_time_min] in minutes
%     noise               - Selected noise estimate (max-min) within noise window
%     NoiseCheck          - Logical flag indicating whether the peak passes noise criteria
%     baseline            - Baseline estimate (median intensity) within selected noise window
%


    % Expand the initial peak search window for blanks
    if isblank
        factor = 3;
    else
        factor = 1;
    end

    % Extract a window around the expected component RT
    [peakscanTimes, peakionIntensities] = EICWindow( ...
        scanTimes, ionIntensities, ...
        Component_RT * 60 - Parameters.chroma.RTToleranceInSec * factor, ...
        Component_RT * 60 + Parameters.chroma.RTToleranceInSec * factor);

    % Find the maximum within the initial peak window
    [peak_max_intensity, peak_max_index] = max(peakionIntensities);
    RT_peak_max_min = peakscanTimes(peak_max_index); % RT of maximum (minutes)

    % Re-center around the found maximum to refine peak characterization
    [centerdpeakscanTimes, centeredpeakionIntensities] = EICWindow( ...
        scanTimes, ionIntensities, ...
        (RT_peak_max_min * 60 - Parameters.chroma.RTToleranceInSec), ...
        (RT_peak_max_min * 60 + Parameters.chroma.RTToleranceInSec));

    % Re-evaluate maximum within the centered window
    [peak_max_intensity, peak_max_index] = max(centeredpeakionIntensities);
    RT_peak_max_min = centerdpeakscanTimes(peak_max_index);

    % Define peak window in minutes
    peakwindow = [min(centerdpeakscanTimes), max(centerdpeakscanTimes)];

    if isempty(RT_peak_max_min)
        return
    end

    %% Noise window (left side)
    upper_time_Secleft = RT_peak_max_min * 60 - Parameters.MS1.NoiseDistancetoPeakMax_sec;
    lower_time_Secleft = upper_time_Secleft - Parameters.MS1.noisewindowInSec;
    noisewindowleft = [lower_time_Secleft, upper_time_Secleft];

    if noisewindowleft(1) < 180 || noisewindowleft(2) > 1200
        noisewindowleft = NaN;
        noiseleft = NaN;
        baselineleft = NaN;
    else
        [noiseScantimes, noiseionIntensities] = EICWindow(scanTimes, ionIntensities, lower_time_Secleft, upper_time_Secleft); %#ok<ASGLU>
        noiseleft = max(noiseionIntensities) - min(noiseionIntensities);
        baselineleft = median(noiseionIntensities);
    end

    %% Noise window (right side)
    lower_time_Secright = RT_peak_max_min * 60 + Parameters.MS1.NoiseDistancetoPeakMax_sec;
    upper_time_Secright = lower_time_Secright + Parameters.MS1.noisewindowInSec;
    noisewindowright = [lower_time_Secright, upper_time_Secright];

    if noisewindowright(1) < 180 || noisewindowright(2) > 1200
        noisewindowright = NaN;
        noiseright = NaN;
        baselineright = NaN;
    else
        [noiseScantimes, noiseionIntensities] = EICWindow(scanTimes, ionIntensities, lower_time_Secright, upper_time_Secright); %#ok<ASGLU>
        noiseright = max(noiseionIntensities) - min(noiseionIntensities);
        baselineright = median(noiseionIntensities);
    end

    %% Select noise estimate (prefer valid; otherwise choose smaller noise)
    if isnan(noiseright)
        noise = noiseleft;
        baseline = baselineleft;
        noisewindow = noisewindowleft;
    elseif isnan(noiseleft)
        noise = noiseright;
        baseline = baselineright;
        noisewindow = noisewindowright;
    else
        if noiseright > noiseleft
            noise = noiseleft;
            baseline = baselineleft;
            noisewindow = noisewindowleft;
        else
            noise = noiseright;
            baseline = baselineright;
            noisewindow = noisewindowright;
        end
    end

    %% Further evaluations
    if isempty(noise)
        noise = Parameters.MS1.Noise_default;
    elseif noise < Parameters.MS1.Noise_default
        noise = Parameters.MS1.Noise_default;
    end

    % Baseline correction of peak height
    peak_max_intensity = peak_max_intensity - baseline;

    % Criterion 1: peak maximum exceeds minimum S/N threshold
    Criterion1 = ((peak_max_intensity / noise) > Parameters.MS1.min_S_N_maximum);

    % Criterion 2: enough points exceed secondary threshold
    min_intensity = noise * Parameters.MS1.min_Level_in_S_N + baseline;
    Criterion2 = (sum(centeredpeakionIntensities >= min_intensity)) >= Parameters.MS1.min_points_over_Level;

    % Final decision
    if Criterion1 && Criterion2
        NoiseCheck = true;
    else
        peak_max_intensity = NaN;
        RT_peak_max_min = NaN;
        NoiseCheck = false;
    end
end



