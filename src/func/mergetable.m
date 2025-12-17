function mergedSpectrum = mergetable(T, tolerance)
%MERGETABLE  Merge an MS2 spectrum by binning m/z values to reduce digital noise.
%   mergedSpectrum = mergetable(T, tolerance)
%
%   Expects an MS2 spectrum as an Nx2 array:
%     column 1: m/z values
%     column 2: intensity values
%
%   The spectrum is merged by rounding m/z values to a tolerance grid and
%   summing intensities per bin. The representative m/z per bin is computed
%   as the mean of the original m/z values inside that bin.
%
%   Inputs:
%     T         - Nx2 numeric array [m/z, intensity]
%     tolerance - Binning tolerance (same unit as m/z)
%
%   Output:
%     mergedSpectrum - Merged Nx2 numeric array [mean_mz, sum_intensity]
%

    % Convert input array to a table for grouped aggregation
    T = array2table(T, 'VariableNames', {'Value', 'Data'});

    % Add rounded values (bin centers) as grouping key
    T.RoundedValue = round(T.Value / tolerance) * tolerance;

    % Group by bin key: sum intensities and compute mean m/z
    T_merged  = groupsummary(T, 'RoundedValue', 'sum',  'Data');
    T2_merged = groupsummary(T, 'RoundedValue', 'mean', 'Value');

    % Build merged output table [Value, Data]
    T3_merged = table(T2_merged.mean_Value, 'VariableNames', {'Value'});
    T3_merged.Data = T_merged.sum_Data;

    % Convert back to numeric array
    mergedSpectrum = table2array(T3_merged);
end
