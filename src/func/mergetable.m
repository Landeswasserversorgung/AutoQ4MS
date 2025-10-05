function [outputArg1] = mergetable(T,tolerance)
% merges an ms2 spectrum to remove digital noise, expects ms2 spectrum as
% an array with col 1 being m/z values and col 2 being intensity data
T=array2table(T, 'VariableNames',{'Value','Data'});
%tolerance = tolerance/2;
% Add rounded values to the table as a new column
T.RoundedValue = round(T.Value / tolerance) * tolerance;

% Group by the new 'RoundedValue' column and compute the sum of 'Data' and
% the mean of 'Value'
T_merged = groupsummary(T, 'RoundedValue', 'sum', 'Data');
T2_merged = groupsummary(T, 'RoundedValue', 'mean', 'Value');
T3_merged = table(T2_merged.mean_Value, 'VariableNames', {'Value'});
T3_merged.Data = T_merged.sum_Data;
% Convert back into array
T3_merged=table2array(T3_merged);

outputArg1 = T3_merged;

end