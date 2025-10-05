function [outputArg1,outputArg2] = cosineMS2(spectra1,spectra2, binWidth, binOffset, threshold,massTolerance_ppm,removePrecursor,ms2PrecursorMass)
%cosineMS2 Calculates cosine similarity of ms2 spectra form two spectra,
%a binWidth, an Offset, an intensity threshold, a mass tolerance, the precursor mass and if the precursor should be removed Spectra 1 is the sample spectrum while spectra 2
%is the reference
%% Cleanup Spectra
minI=5; % 5% of most intense fragment
massTolerance = max(spectra2(:,1))*massTolerance_ppm/100000;
if ~isempty(spectra1) && width(spectra1) ==2
    spectra1=MS2cleanup(spectra1,massTolerance,ms2PrecursorMass,removePrecursor,minI);
elseif width(spectra1)==1 && height(spectra1)==2
    spectra1=transpose(spectra1);
    spectra1=MS2cleanup(spectra1,massTolerance,ms2PrecursorMass,removePrecursor,minI);
end

% spectra2
if ~isempty(spectra2)&& width(spectra2) ==2
   spectra2=MS2cleanup(spectra2,massTolerance,ms2PrecursorMass,removePrecursor,minI);
elseif width(spectra2)==1 && height(spectra2)==2
   spectra2=transpose(spectra2);
   spectra2=MS2cleanup(spectra2,massTolerance,ms2PrecursorMass,removePrecursor,minI);
end

        
%% Extract values
% Extract m/z and intensities
mz1 = spectra1(:,1);  % Sample
intensity1 = spectra1(:,2);

mz2 = spectra2(:,1); % Library
intensity2 = spectra2(:,2);


%% Binning

common_mz = min([mz1; mz2])-binOffset:binWidth:max([mz1; mz2]); 

% Assign each m/z value to its closest bin
[~, binIdx1] = min(abs(mz1 - common_mz), [], 2);
[~, binIdx2] = min(abs(mz2 - common_mz), [], 2);

% Initialize intensity vectors
intensity1_binned = zeros(size(common_mz));
intensity2_binned = zeros(size(common_mz));

% Sum intensities in each bin
for i = 1:length(mz1)
    intensity1_binned(binIdx1(i)) = intensity1_binned(binIdx1(i)) + intensity1(i);
end
for i = 1:length(mz2)
    intensity2_binned(binIdx2(i)) = intensity2_binned(binIdx2(i)) + intensity2(i);
end


%% Cosine similarity

% find more intense spectrum#
intratio = max(intensity1_binned) / max(intensity2_binned);
% remove fragments from reference, if they could not have been detected in sample
if intratio < 1
    for i=1:length(intensity2_binned)
        if intensity2_binned(i) * intratio <= threshold % more intense spectrumm
            intensity2_binned(i) = 0;
            
        end
        if intensity1_binned(i) <= threshold % less intense spectrum to avoid issues due to values below threshold
           intensity1_binned(i) = 0;
        end
    end
elseif intratio > 1
    for i=1:length(intensity1_binned)
        if intensity1_binned(i) / intratio <= threshold % more intense spectrumm
           intensity1_binned(i) = 0;
        end
        if intensity2_binned(i) <= threshold % less intense spectrum to avoid issues due to values below threshold
           intensity2_binned(i) = 0;
        end
    end
end
% Compute dot product and magnitudes
dot_product = sum(intensity1_binned .* intensity2_binned);
magnitude1 = sqrt(sum(intensity1_binned .^ 2));
magnitude2 = sqrt(sum(intensity2_binned .^ 2));
% Calculate cosine similarity
cosine_similarity = dot_product / (magnitude1 * magnitude2);

% Calculate number of matching fragmets
matchCount=0;
libCount =0;
for i=1:width(intensity2_binned)
    if intensity2_binned(i) >0 
        libCount = libCount+1;
    end
    if intensity2_binned(i) >0 && intensity1_binned(i) >0
        matchCount = matchCount+1;
    end
end
fragMatch = sprintf("%d of %d",matchCount,libCount);
% generate output
if ~isempty(spectra1) || ~isempty(spectra2)
    outputArg1 = cosine_similarity;
    outputArg2 = fragMatch;
else
     outputArg1 =0;
     outputArg2 = "No Data";
end
end
% comment to update git
