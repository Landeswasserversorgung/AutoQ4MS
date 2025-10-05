function [] = writeintxtforHTML(htmlStrings,fileID)
            for k = 1:length(htmlStrings)
                fprintf(fileID, '%s\n', htmlStrings{k});
            end
end

