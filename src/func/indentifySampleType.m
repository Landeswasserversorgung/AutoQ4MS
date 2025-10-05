function type = indentifySampleType(filename)
%% This function identifies the sample type based on the filename
%   Linus Strähle 2024-03-28

type = 'Samp';

String = filename;
searchString = {'Blank', 'Cal','AIO-Mix', 'Mix', 'PreRun','Roth', 'QC'};


for i = 1:length(searchString)
    if contains(String, searchString{i})
        type = searchString{i};
        break;
    end
end

end

