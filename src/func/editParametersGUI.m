function updatedParameters = editParametersGUI(inputStruct, titleName)
% editStructGUI - GUI to edit a nested struct
% updatedStruct = editStructGUI(inputStruct, titleName)

    if nargin < 2
        titleName = 'Edit Struct';
    end

    updatedStruct = inputStruct;
    fields = fieldnames(inputStruct);
    n = numel(fields);

    guiWidth = 700;
    rowHeight = 40;
    guiHeight = 100 + n * rowHeight;

    hFig = figure('Name', titleName, 'MenuBar', 'none', 'NumberTitle', 'off', 'Resize', 'off', ...
        'Color', [0.95 0.95 0.95], 'DockControls', 'off', 'WindowStyle', 'normal', ...
        'Position', centerFig(guiWidth, guiHeight));

    y = guiHeight - 60;
    for i = 1:n
        field = fields{i};
        if strcmp(field, 'tables')
            continue;
        end
        val = inputStruct.(field);

        uicontrol(hFig, 'Style', 'text', 'String', field, 'Position', [20, y, 200, 25], ...
            'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95], 'HorizontalAlignment', 'left');

        if isstruct(val)
            uicontrol(hFig, 'Style', 'pushbutton', 'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], 'String', 'Edit...', 'Position', [240, y, 100, 25], ...
                'Callback', @(~,~) editNested(field));
        elseif isnumeric(val) && isvector(val) && numel(val) > 1
            for j = 1:numel(val)
                uicontrol(hFig, 'Style', 'edit', 'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], 'String', num2str(val(j)), 'Position', [240 + (j-1)*80, y, 70, 25], ...
                    'Callback', @(src,~) updateArrayElement(field, j, src));
            end
        elseif islogical(val)
            uicontrol(hFig, 'Style', 'togglebutton', 'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], 'String', logicalToString(val), 'Value', val, 'Position', [240, y, 100, 25], ...
                'Callback', @(src,~) toggleLogical(field, src));
        elseif ischar(val) || isstring(val)
            editField = uicontrol(hFig, 'Style', 'edit', 'String', char(val), 'Position', [240, y, 340, 25], ...
                'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], 'Callback', @(src,~) updateField(field, src));
            if contains(titleName, 'path')
                if strcmp(field,'MATLABexe')||strcmp(field,'proteoWizard')||strcmp(field,'psqlExe')||strcmp(field,'ISExcel')||strcmp(field,'CompExcel')
                    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [590, y, 80, 25], ...
                        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], ...
                           'Callback', @(~,~) browsePath(field, 'file'));
                else
                    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [590, y, 80, 25], ...
                        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], 'Callback', @(~,~) browsePath(field));
                end
            end
        elseif isnumeric(val)
            uicontrol(hFig, 'Style', 'edit', 'String', convertToString(val), 'Position', [240, y, 100, 25], ...
                'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], 'Callback', @(src,~) updateField(field, src));
        end

        y = y - rowHeight;
    end

    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Save', 'Position', [guiWidth/2 - 110, 20, 100, 30], 'Callback', @saveCallback);
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', [guiWidth/2 + 10, 20, 100, 30], 'Callback', @cancelCallback);

    uiwait(hFig);

    updatedParameters = updatedStruct;

    function editNested(fieldName)
        subStruct = updatedStruct.(fieldName);
        edited = editParametersGUI(subStruct, ['Edit: ' fieldName]);
        if ~isempty(edited)
            updatedStruct.(fieldName) = edited;
        end
        end

    function updateField(fieldName, src)
        originalVal = inputStruct.(fieldName);
        inputStr = src.String;

        if isnumeric(originalVal)
            val = str2double(inputStr);
            if isnan(val)
                warndlg(['Invalid numeric input for field "' fieldName '". Please enter a valid number.'], 'Validation Error');
                return;
            end
        elseif islogical(originalVal)
            val = strcmpi(inputStr, 'true');
        else
            val = inputStr;
        end

        updatedStruct.(fieldName) = val;
    end
function browsePath(fieldName, type)
    if nargin < 2
        type = 'folder'; % Default to folder selection if no type is specified
    end

    current = updatedStruct.(fieldName);

    switch type
        case 'file'
            % Determine starting path for file selection
            if isfolder(current)
                startPath = current;
            else
                startPath = fileparts(current);
            end

            % Open file selection dialog
            [file, path] = uigetfile({'*.*', 'All Files'}, 'Select a file', startPath);
            if isequal(file, 0)
                return; % User cancelled
            end
            newPath = fullfile(path, file);

        case 'folder'
            % Open folder selection dialog with current path if valid
            if isfolder(current)
                newPath = uigetdir(current);
            else
                newPath = uigetdir;
            end
            if newPath == 0
                return; % User cancelled
            end

        otherwise
            return; % Invalid type provided
    end

    % Update the structure with the new path
    updatedStruct.(fieldName) = newPath;

    % Update the corresponding edit field in the UI (if it exists)
    allEdits = findall(hFig, 'Style', 'edit');
    for k = 1:numel(allEdits)
        if strcmp(allEdits(k).String, current)
            allEdits(k).String = newPath;
            break; % Update only the first matching edit field
        end
    end
end


    

        function saveCallback(~,~)
        uiresume(gcbf);  % use current figure as fallback
        delete(gcbf);
    end

    function toggleLogical(fieldName, src)
        val = logical(src.Value);  % use the actual state
        src.String = logicalToString(val);
        updatedStruct.(fieldName) = val;
    end

    function updateArrayElement(fieldName, index, src)
        val = str2double(src.String);
        if isnan(val)
            warndlg(['Invalid numeric input for array element #' num2str(index)], 'Validation Error');
            return;
        end
        current = updatedStruct.(fieldName);
        current(index) = val;
        updatedStruct.(fieldName) = current;
    end

        

    function cancelCallback(~,~)
        updatedStruct = [];
        uiresume(hFig);
        delete(hFig);
    end
end

function pos = centerFig(w, h)
    screenSize = get(0, 'ScreenSize');
    x = (screenSize(3) - w) / 2;
    y = (screenSize(4) - h) / 2;
    pos = [x, y, w, h];
end

function str = convertToString(val)
    if isnumeric(val)
        str = num2str(val);
    elseif islogical(val)
        str = logicalToString(val);
    else
        str = char(val);
    end
end

function str = logicalToString(b)
    str = 'false';
    if b, str = 'true'; end
end

