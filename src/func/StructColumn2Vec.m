function Vec = StructColumn2Vec(Struct, Column)
    % StructColumn2Vec Extracts a column from a structure array into a vector or cell array.
    %   Vec = StructColumn2Vec(Struct, Column) takes a structure array 'Struct'
    %   and a column name 'Column' and returns a vector or cell array containing
    %   the values from that column. Supports both numeric and string data.
    %   Linus Straehle 2024-04-16

    if isempty(Struct)
        error('The input structure is empty.');
    end
 
    % Check the type of the first element to determine how to initialize Vec
    numeric = true;
    for i = 1 : numel(Struct)
        if ~isnumeric(Struct(i).(Column))
            numeric = false;
            break;
        end
    end
        
        
        if numeric
            Vec = zeros(numel(Struct), 1);  % Initialize for numeric data
        else 
            Vec = strings(numel(Struct), 1);  % Initialize for string data
        end

        % Fill Vec with the data from the structure
        for i = 1:numel(Struct)
            Vec(i) = Struct(i).(Column);
        end
end
