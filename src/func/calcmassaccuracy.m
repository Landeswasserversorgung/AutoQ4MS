function massaccuracy = calcmassaccuracy(RT, exactmz, msdata, Parameters)
%CALCMASSACCURACY  Compute mass accuracy (ppm) around a target m/z near a given RT.
%   Compares a provided retention time (RT) and exact mass (exactmz) against
%   measured MS1 data (msdata). For the target m/z, the function evaluates the
%   5 MS spectra closest in time to RT, selects the highest-intensity peak
%   within ±X ppm of exactmz in each spectrum, then averages the selected m/z
%   values and reports the mass error in ppm.
%
%   Inputs:
%     RT         - Retention time used to locate nearby spectra (same units as
%                  msdata.retentionTime)
%     exactmz    - Target m/z value (double)
%     msdata     - Struct array with fields:
%                    .retentionTime : numeric vector/values (one per spectrum)
%                    .ScanData      : N×2 matrix per spectrum [m/z, intensity]
%     Parameters - Struct with fields used for tolerance and logging:
%                    Parameters.MS1.XICWidth_ppm : m/z tolerance (ppm)
%
%   Output:
%     massaccuracy - Mass error in ppm (rounded to 2 decimals). NaN if RT is
%                    NaN or if an error occurs anywhere in the routine.
%

try 
    if isnan(RT)
        % If the peak is below LoD or RT is undefined, return NaN immediately.
        massaccuracy = NaN;
        return;
    end

    %% Locate the 5 spectra closest in time to the provided RT
    % Convert struct field to vector for nearest-neighbor lookup.
    RTinMSdata = StructColumn2Vec(msdata, 'retentionTime');

    % Absolute time differences between each spectrum and the provided RT.
    differences = abs(RTinMSdata - RT);

    % Indices of the five smallest differences (nearest 5 spectra by RT).
    [diffValues, indices] = mink(differences, 5);

    % Guardrail: if any of the 5 nearest are still too far away, abort.
    % (Threshold of 5 units in the same RT units as msdata.retentionTime.)
    if max(diffValues) > 5
        error('The difference between the measured RT and the RT in the MS data is too big');
    end

    %% For each of the 5 spectra, select the highest-intensity peak within ±ppm
    measuredmz = nan(1, 5); % Preallocate with NaN (some spectra may have no peak)

    for i = 1 : numel(indices)
        % Extract m/z and intensity values for this spectrum
        mz_values = msdata(indices(i)).ScanData(:, 1);
        intensityValues = msdata(indices(i)).ScanData(:, 2);

        % Keep only values within ±X ppm around the target m/z
        
        ppmTol = (exactmz * Parameters.MS1.XICtolerance_ppm) / 1e6;
        keepindex = abs(mz_values - exactmz) < ppmTol;

        intensityValues = intensityValues(keepindex);
        mz_values      = mz_values(keepindex);

        % Select the m/z at the maximum intensity in this spectrum
        [~, maxindex] = max(intensityValues);
        if ~numel(maxindex)
            % No candidate peaks in this spectrum — leave NaN and continue
            continue;
        end
        measuredmz(i) = mz_values(maxindex);
    end

    %% Compute mass accuracy in ppm from the mean selected m/z (omit NaNs)
    massaccuracy = round(((mean(measuredmz, 'omitnan') - exactmz) / exactmz) * 1e6, 2);

catch
    % On any error, return NaN and log a warning via the project logger
    massaccuracy = NaN;
    WarningPlusDb('The mass accuracy calculation was not possible', Parameters, 'Processing settings'); 
end

end



