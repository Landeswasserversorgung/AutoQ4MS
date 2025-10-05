function massaccuracy = calcmassaccuracy(RT, exactmz, msdata, Parameters)
%CALCMASSACCURACY Calculates the mass accuracy based on retention time and exact mass
%   This function calculates the mass accuracy by comparing the provided 
%   retention time (RT) and exact mass (exactmz) with the measured data 
%   (msdata). It uses the specified parameters (Parameters) for the calculation.
%   For the exact mass is uesd the mean of m/z Values of the Peaks with the highest 
%   Intensitiy in a range of exactmz +- X ppm over the 5 MS Spectra next to the
%   given RT.
%
%   Inputs:
%       RT - Retention time to compare
%       exactmz - Exact mass to compare
%       msdata - Struct containing the measured MS data with fields:
%           'retentionTime' - Retention times of the MS data
%           'ScanData' - Matrix with mz values and intensity values
%       Parameters - Struct containing the parameters for the calculation:
%           Parameters.MS1.XICWidth_ppm - Tolerance for mz values in ppm
%
%   Outputs:
%       massaccuracy - Calculated mass accuracy in ppm
%   Linus Straehle

try 
    if isnan(RT)
       % Peak is <LoD
       massaccuracy = NaN;
       return;
    end
    % Extract retention times from the msdata struct
    RTinMSdata = StructColumn2Vec(msdata, 'retentionTime');
    
    % Calculate absolute differences between provided RT and MS data RTs
    differences = abs(RTinMSdata - RT);
    
    % Find the indices of the five smallest differences
    [diffValues, indices] = mink(differences, 5);
    
    % Check if the maximum difference is within acceptable range
    if max(diffValues) > 5
        error('The difference between the measured RT and the RT in the MS data is too big');
    end

    % Initialize measured mz values with NaN
    measuredmz = nan(1, 5);

    % Loop through the indices of the smallest differences
    for i = 1 : numel(indices)
        % Get MS data corresponding to the current RT
        mz_values = msdata(indices(i)).ScanData(:, 1);
        intensityValues = msdata(indices(i)).ScanData(:, 2);
        
        % Filter mz values and intensity values within the specified tolerance range
        keepindex = abs(mz_values - exactmz) < (exactmz * Parameters.MS1.XICtolerance_ppm) / 1e6;
        intensityValues = intensityValues(keepindex);
        mz_values = mz_values(keepindex);
        
        % Save the mz value with the highest intensity
        [~, maxindex] = max(intensityValues);
        if ~numel(maxindex)
            continue; % Size is Null --> no Peak in this Spectra
        end
        measuredmz(i) = mz_values(maxindex);
    end

    % Calculate the mass accuracy in ppm
    massaccuracy = round(((mean(measuredmz, 'omitnan') - exactmz) / exactmz) * 1e6, 2);
catch
    % In case of an error, return NaN and log the warning
    massaccuracy = NaN;
    WarningPlusDb('The mass accuracy calculation was not possible', Parameters, 'Processing settings'); 
end

end


