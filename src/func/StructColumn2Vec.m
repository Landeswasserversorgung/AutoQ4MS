function Vec = StructColumn2Vec(Struct, Column)
%STRUCTCOLUMN2VEC  Extract a field from a struct array into a vector.
%
%   Vec = StructColumn2Vec(Struct, Column)
%   Extracts the values of the specified field from a struct array and
%   returns them as either a numeric vector or a string array, depending
%   on the field content.
%
%   Inputs:
%     Struct - Struct array containing the requested field
%     Column - Name of the field to extract (string or char)
%
%   Output:
%     Vec    - Vector (numeric) or string array containing the field values
%

    if isempty(Struct)
        error('The input structure is empty.');
    end

    % Determine whether all values in the field are numeric
    numeric = true;
    for i = 1:numel(Struct)
        if ~isnumeric(Struct(i).(Column))
            numeric = false;
            break;
        end
    end

    % Preallocate output vector
    if numeric
        Vec = zeros(numel(Struct), 1);
    else
        Vec = strings(numel(Struct), 1);
    end

    % Fill output vector with field values
    for i = 1:numel(Struct)
        Vec(i) = Struct(i).(Column);
    end
end
