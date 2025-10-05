clc
clear
addpath('functions');
addpath('classes');
%%
spectra1 = [100.0,0;151.0,18;200.5,17]; %Sample
spectra2 = [100.0,400;151.0,900;200.5,600]; %Reference
%varnames = ["mz","intensity"];
%spectra1=array2table(spectra1, 'VariableNames', varnames);
%spectra2=array2table(spectra2, 'VariableNames', varnames);

% Define bin width (adjust based on resolution)
binWidth = 0.5;
binOffset = 0.2; % to keep organic substances in the same bin
threshold = 10; % minimum intensity
cosine_similarity = cosineMS2(spectra1,spectra2,binWidth,binOffset, threshold);


