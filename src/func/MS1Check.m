function [RT_peak_max_min, peak_max_intensity, noisewindow, peakwindow , noise, NoiseCheck, baseline] = MS1Check(scanTimes, ...
    ionIntensities, Parameters, Component_RT, isblank)
    %%   This function receives mass spectrometric EIC data and performs a search based on parameters
    %   Linus Straehle 2024-04-02
    
    %   Inputs:
%       scanTimes - Array of times at which scans were taken.
%       ionIntensities - Array of ion intensities corresponding to each scan time.
%       Component_RT - The expected retention time for the component.
%       isblank - is the sample Blank --> bigger Peak finding Window
%       Parameters Struct
%           RTToleranceInSec - Tolerance for the retention time in seconds.
%           peakwindow_Sec - Two-element array specifying the start and end times of the peak window in seconds. 
%           NoiseDistancetoPeakMaxInSec - The distance in seconds between the peak maximum and the search range for the noise
%           min_S_N_maximum - The S/N ratio of the maximum to be above the LOD
%           min_Level_in_S_N -  minimum level for creterium below
%           MS1.min_points_over_Level - minimum number of points above the min level

    if isblank
        factor = 3;
    else
        factor = 1;
    end
    
        
    
    % Extracts a window around the specified component retention time with a given tolerance.
    [peakscanTimes, peakionIntensities] = EICWindow(scanTimes, ionIntensities,...
        Component_RT*60-Parameters.chroma.RTToleranceInSec*factor, Component_RT*60+Parameters.chroma.RTToleranceInSec*factor);
    
    % Identify the maximum peak intensity and its corresponding retention time (RT) within the extracted data.
    % This finds the maxima in the specified window.
    [peak_max_intensity, peak_max_index] = max(peakionIntensities);
    RT_peak_max_min = peakscanTimes(peak_max_index); % RT of the maxima in minutes
    
% %     % Optional: Plot the extracted ion chromatogram to visualize the peak finding window.
%     plot(peakscanTimes, peakionIntensities, '-x','MarkerSize', 6);
%     xlabel('Retention Time (minutes)'); 
%     ylabel('Intensity');
%     title('Peak Finding Window');
%     drawnow; % Updates figures and processes any pending callbacks.
%     pause(5); % Pauses for 2 seconds to allow visualization of the plot.
%     clf; % Clears the current figure window.
    
    % Re-centers the window around the identified peak maximum to refine the peak characterization.
    [centerdpeakscanTimes, centeredpeakionIntensities] = EICWindow(scanTimes, ionIntensities,...
        (RT_peak_max_min*60-Parameters.chroma.RTToleranceInSec), (RT_peak_max_min*60+Parameters.chroma.RTToleranceInSec));
    
    % Re-evaluate the maximum peak intensity and its RT in the re-centered window.
    [peak_max_intensity, peak_max_index] = max(centeredpeakionIntensities);
    RT_peak_max_min = centerdpeakscanTimes(peak_max_index); % RT of the maximum peak in minutes
    
    % Defines the peak window based on the refined peak RT and tolerance.
    peakwindow = [min(centerdpeakscanTimes)  , max(centerdpeakscanTimes) ];
 
%     % Optional: Plot the re-centered chromatogram to visualize the peak.
%     plot(centerdpeakscanTimes, centeredpeakionIntensities,'-x','MarkerSize', 6);
%     xlabel('Retention Time (minutes)'); 
%     ylabel('Intensity');
%     title('Centered Peak');
%     drawnow; % Updates figures and processes any pending callbacks.
%     pause(5); % Pause for 2 seconds to allow visualization of the plot.
%     clf; % Clears the current figure window.

    if isempty(RT_peak_max_min)
        return
    end
    
    %% Noise Left side
    % Determine noise characteristics by analyzing a window before the peak.
    upper_time_Secleft= RT_peak_max_min*60-Parameters.MS1.NoiseDistancetoPeakMax_sec ;
    lower_time_Secleft = upper_time_Secleft - Parameters.MS1.noisewindowInSec ;
    noisewindowleft = [lower_time_Secleft, upper_time_Secleft]; % Defines the noise analysis window.
    
    
    if noisewindowleft(1) < 180 || noisewindowleft(2) > 1200
        %Noise window is out of range 
        noisewindowleft = NaN;
        noiseleft = NaN;
        baselineleft =NaN;
        %disp('Noise window is out of range');
    else
        % Noise Difference between highest and lowest value
        [noiseScantimes, noiseionIntensities] = EICWindow(scanTimes, ...
            ionIntensities, lower_time_Secleft, upper_time_Secleft);
        % Noise = Difference between highest and lowest value
        noiseleft = max(noiseionIntensities)- min(noiseionIntensities);
        baselineleft = median(noiseionIntensities);
    end
    
    %     % Optional: Plot to visualize the noise window.
%     plot(noiseScantimes, noiseionIntensities, '-x','MarkerSize', 6);
%     xlabel('Retention Time (minutes)'); 
%     ylabel('Intensity');
%     title('Noise Window Left');
%     drawnow; % Updates figures and processes any pending callbacks.
%     pause(5); % Pause for 2 seconds to allow visualization of the plot.
%     clf; % Clears the current figure window.
    
    
    %% Noise right side 
    % Determine noise characteristics by analyzing a window before the peak.
    
    lower_time_Secright = RT_peak_max_min*60+Parameters.MS1.NoiseDistancetoPeakMax_sec ;
    upper_time_Secright = lower_time_Secright + Parameters.MS1.noisewindowInSec ;
    noisewindowright = [lower_time_Secright, upper_time_Secright]; % Defines the noise analysis window.
    
    
    if noisewindowright(1) < 180 || noisewindowright(2) > 1200
        %Noise window is out of range 
        noisewindowright = NaN;
        noiseright = NaN;
        baselineright =NaN;
        %disp('Noise window is out of range');
    else
        % Noise Difference between highest and lowest value
        [noiseScantimes, noiseionIntensities] = EICWindow(scanTimes, ...
            ionIntensities, lower_time_Secright, upper_time_Secright);
        % Noise = Difference between highest and lowest value
        noiseright = max(noiseionIntensities)- min(noiseionIntensities);
        baselineright = median(noiseionIntensities);
    end
    
        %     % Optional: Plot to visualize the noise window.
%     plot(noiseScantimes, noiseionIntensities, '-x','MarkerSize', 6);
%     xlabel('Retention Time (minutes)'); 
%     ylabel('Intensity');
%     title('Noise Window Right');
%     drawnow; % Updates figures and processes any pending callbacks.
%     pause(5); % Pause for 2 seconds to allow visualization of the plot.
%     clf; % Clears the current figure window.
    
    %% Compare left and right Noise
    if isnan(noiseright)
            noise = noiseleft;
            baseline = baselineleft;
            noisewindow = noisewindowleft;
    elseif isnan(noiseleft)
            noise = noiseright;
            baseline = baselineright;
            noisewindow = noisewindowright;
        else
        %use the smaller noise
        if noiseright > noiseleft %Noise left used
            noise = noiseleft;
            baseline = baselineleft;
            noisewindow = noisewindowleft;
        else %Noise right used
            noise = noiseright;
            baseline = baselineright;
            noisewindow = noisewindowright;
        end
    end
    
    %% further evaluations
    
    if isempty(noise)
        noise = Parameters.MS1.Noise_default;
    elseif (noise < Parameters.MS1.Noise_default) 
            noise = Parameters.MS1.Noise_default; % Small non-zero value assigned to noise.
    end
    
    % Correct the peak height with the baseline
    peak_max_intensity = peak_max_intensity-baseline;
    % Checks if the peak maximum intensity is significantly above the noise level (based on user-defined minimum signal-to-noise ratio).
    Criterion1 = (((peak_max_intensity) / noise) > Parameters.MS1.min_S_N_maximum);%Peak Maximum is > 5*N
    % Further checks if a sufficient number of points exceed a secondary signal-to-noise level.
    min_intensity = noise*Parameters.MS1.min_Level_in_S_N+baseline ;
    Criterion2 = (sum(centeredpeakionIntensities >= min_intensity)) >= Parameters.MS1.min_points_over_Level; %minimum  5 points > 2 Noins  
 
    
%Check criterion and determine noise check value
    if Criterion1 && Criterion2
        NoiseCheck = true; % Indicates the peak passes noise criteria.
    else
        peak_max_intensity = NaN; % Indicates peak intensity is below the limit of detection (LoD).
        RT_peak_max_min = NaN;
        NoiseCheck = false; % Indicates the peak does not pass noise criteria.
    end

end


