function updatedParameters = editParametersGUI(inputStruct, titleName)
%EDITPARAMETERSGUI  GUI editor for a (possibly nested) parameters struct.
%   updatedParameters = editParametersGUI(inputStruct, titleName)
%   Opens a simple, form-like GUI to edit fields of a given struct. Supports:
%     - numeric scalars and numeric vectors
%     - logical values via toggle button
%     - char/string values (with optional "Browse..." button for paths)
%     - nested structs via "Edit..." sub-dialogs
%
%   Inputs:
%     inputStruct - Struct with parameters to display and edit
%     titleName   - (optional) Window title; if it contains 'path' a "Browse..."
%                   button is shown for string/char fields (file/folder selection)
%
%   Output:
%     updatedParameters - Edited struct, or [] if cancelled
%

    if nargin < 2
        titleName = 'Edit Struct';
    end

    updatedStruct = inputStruct;
    fields = fieldnames(inputStruct);
    n = numel(fields);

    % Basic layout metrics
    guiWidth  = 700;
    rowHeight = 40;
    guiHeight = 100 + n * rowHeight;

    % Create figure (modal-like behavior via uiwait/uitable)
    hFig = figure('Name', titleName, 'MenuBar', 'none', 'NumberTitle', 'off', 'Resize', 'off', ...
        'Color', [0.95 0.95 0.95], 'DockControls', 'off', 'WindowStyle', 'normal', ...
        'Position', centerFig(guiWidth, guiHeight));

    % Build controls row by row
    y = guiHeight - 60;
    for i = 1:n
        field = fields{i};

        % Skip the 'tables' field entirely
        if strcmp(field, 'tables')
            continue;
        end

        val = inputStruct.(field);

        % Field label
        uicontrol(hFig, 'Style', 'text', 'String', field, 'Position', [20, y, 200, 25], ...
            'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95], 'HorizontalAlignment', 'left');

        % Field editor
        if isstruct(val)
            % Nested struct → open sub-dialog
            uicontrol(hFig, 'Style', 'pushbutton', 'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], ...
                'String', 'Edit...', 'Position', [240, y, 100, 25], ...
                'Callback', @(~,~) editNested(field));

        elseif isnumeric(val) && isvector(val) && numel(val) > 1
            % Numeric vector → render one edit per element
            for j = 1:numel(val)
                uicontrol(hFig, 'Style', 'edit', 'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], ...
                    'String', num2str(val(j)), 'Position', [240 + (j-1)*80, y, 70, 25], ...
                    'Callback', @(src,~) updateArrayElement(field, j, src));
            end

        elseif islogical(val)
            % Logical → toggle button with text true/false
            uicontrol(hFig, 'Style', 'togglebutton', 'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], ...
                'String', logicalToString(val), 'Value', val, 'Position', [240, y, 100, 25], ...
                'Callback', @(src,~) toggleLogical(field, src));

        elseif ischar(val) || isstring(val)
            % Char/string → edit box (+ optional Browse)
            editField = uicontrol(hFig, 'Style', 'edit', 'String', char(val), 'Position', [240, y, 340, 25], ...
                'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], 'Callback', @(src,~) updateField(field, src)); %#ok<NASGU>

            if contains(titleName, 'path')
                % Heuristics: for known file fields, open a file chooser
                if strcmp(field,'MATLABexe') || strcmp(field,'proteoWizard') || strcmp(field,'psqlExe') || ...
                   strcmp(field,'ISExcel')   || strcmp(field,'CompExcel')
                    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [590, y, 80, 25], ...
                        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], ...
                        'Callback', @(~,~) browsePath(field, 'file'));
                else
                    % Fallback: folder chooser
                    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [590, y, 80, 25], ...
                        'FontSize', 10, 'BackgroundColor', [0.94 0.94 0.94], ...
                        'Callback', @(~,~) browsePath(field));
                end
            end

        elseif isnumeric(val)
            % Numeric scalar
            uicontrol(hFig, 'Style', 'edit', 'String', convertToString(val), 'Position', [240, y, 100, 25], ...
                'FontSize', 10, 'BackgroundColor', [0.98 0.98 0.98], 'Callback', @(src,~) updateField(field, src));
        end

        y = y - rowHeight;
    end

    % Save/Cancel buttons
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Save',   'Position', [guiWidth/2 - 110, 20, 100, 30], 'Callback', @saveCallback);
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', [guiWidth/2 + 10,  20, 100, 30], 'Callback', @cancelCallback);

    % Modal wait; figure is closed in callbacks
    uiwait(hFig);

    % Return edited parameters (or [] if cancelled)
    updatedParameters = updatedStruct;

    % ------- Nested helpers (capture updatedStruct & inputStruct by closure) -------

    function editNested(fieldName)
        % Open a recursive editor for a sub-struct
        subStruct = updatedStruct.(fieldName);
        edited = editParametersGUI(subStruct, ['Edit: ' fieldName]);
        if ~isempty(edited)
            updatedStruct.(fieldName) = edited;
        end
    end

    function updateField(fieldName, src)
        % Update a scalar field with basic validation based on original type
        originalVal = inputStruct.(fieldName);
        inputStr    = src.String;

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
        % Browse for a file or a folder and update the corresponding field
        if nargin < 2
            type = 'folder'; % default
        end

        current = updatedStruct.(fieldName);

        switch type
            case 'file'
                % Determine starting folder for file dialog
                if isfolder(current)
                    startPath = current;
                else
                    startPath = fileparts(current);
                end
                [file, path] = uigetfile({'*.*', 'All Files'}, 'Select a file', startPath);
                if isequal(file, 0)
                    return; % user cancelled
                end
                newPath = fullfile(path, file);

            case 'folder'
                % Folder selection dialog; start at current if valid
                if isfolder(current)
                    newPath = uigetdir(current);
                else
                    newPath = uigetdir;
                end
                if newPath == 0
                    return; % user cancelled
                end

            otherwise
                return; % unsupported type
        end

        % Update struct value
        updatedStruct.(fieldName) = newPath;

        % Try to update the first matching edit control showing the old path
        allEdits = findall(hFig, 'Style', 'edit');
        for k2 = 1:numel(allEdits)
            if strcmp(allEdits(k2).String, current)
                allEdits(k2).String = newPath;
                break;
            end
        end
    end

    function saveCallback(~,~)
        % Confirm & close
        uiresume(gcbf);
        delete(gcbf);
    end

    function toggleLogical(fieldName, src)
        % Toggle a logical value using the control state
        val = logical(src.Value);
        src.String = logicalToString(val);
        updatedStruct.(fieldName) = val;
    end

    function updateArrayElement(fieldName, index, src)
        % Update one element of a numeric vector
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
        % Cancel editing and return []
        updatedStruct = [];
        uiresume(hFig);
        delete(hFig);
    end
end

% ------------------ Local utilities ------------------

function pos = centerFig(w, h)
    % Center a figure of width w and height h on the main screen
    screenSize = get(0, 'ScreenSize');
    x = (screenSize(3) - w) / 2;
    y = (screenSize(4) - h) / 2;
    pos = [x, y, w, h];
end

function str = convertToString(val)
    % Convert numeric/logical/string to displayable char
    if isnumeric(val)
        str = num2str(val);
    elseif islogical(val)
        str = logicalToString(val);
    else
        str = char(val);
    end
end

function str = logicalToString(b)
    % Render logical true/false as 'true'/'false'
    str = 'false';
    if b
        str = 'true';
    end
end

