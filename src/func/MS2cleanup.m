function [outputArg1] = MS2cleanup(ms2,precursorMassTolerance,PrecursorMass,removePrecursor,minI)
%Removes Precursors (optional) and cleans up digital noise from MS2 spectra
%   Detailed explanation goes here
if ~isempty(ms2)
            ms2=mergetable(ms2,precursorMassTolerance);
            maxFrag = max(ms2(:,2));
            for k = 1:height(ms2)
                if removePrecursor==1 && abs(ms2(k,1) - PrecursorMass)<= (4*precursorMassTolerance) % Remove precursor
                    ms2(k,:) = NaN;
                end
                if ms2(k,2) < (minI/100)*maxFrag % Minimum intensity
                    ms2(k,:) = NaN;
                
                end
            end
        
        % Delete NaN rows
       
        rowswithNaN =any(isnan(ms2),2);
        ms2(rowswithNaN,:) = [];
        % Sort fragments by intensity
        ms2=sortrows(ms2,2,'descend');
       
        % Remove all but x fragments
        outputArg1 = ms2;

end