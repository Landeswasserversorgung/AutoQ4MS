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

    guiWidth  = 700;
    rowHeight = 40;
    guiHeight = 100 + n * rowHeight;

    hFig = figure( ...
        'Name', titleName, ...
        'MenuBar', 'none', ...
        'NumberTitle', 'off', ...
        'Resize', 'off', ...
        'Color', [0.95 0.95 0.95], ...
        'DockControls', 'off', ...
        'WindowStyle', 'normal', ...
        'Position', centerFig(guiWidth, guiHeight));

    y = guiHeight - 60;

    for i = 1:n
        field = fields{i};

        if strcmp(field, 'tables')
            continue;
        end

        val = inputStruct.(field);

        % Label
        uicontrol(hFig, 'Style', 'text', ...
            'String', field, ...
            'Position', [20, y, 200, 25], ...
            'FontSize', 10, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left');

        % -------- Editors --------

        if isstruct(val)
            uicontrol(hFig, 'Style', 'pushbutton', ...
                'String', 'Edit...', ...
                'Position', [240, y, 100, 25], ...
                'FontSize', 10, ...
                'Callback', @(~,~) editNested(field));

        elseif isnumeric(val) && isvector(val) && numel(val) > 1
            for j = 1:numel(val)
                uicontrol(hFig, 'Style', 'edit', ...
                    'String', num2str(val(j)), ...
                    'Position', [240 + (j-1)*80, y, 70, 25], ...
                    'FontSize', 10, ...
                    'BackgroundColor', [0.98 0.98 0.98], ...
                    'Callback', @(src,~) updateArrayElement(field, j, src));
            end

        elseif islogical(val)
            uicontrol(hFig, 'Style', 'togglebutton', ...
                'String', logicalToString(val), ...
                'Value', val, ...
                'Position', [240, y, 100, 25], ...
                'FontSize', 10, ...
                'Callback', @(src,~) toggleLogical(field, src));

        elseif ischar(val) || isstring(val)
            % 🔑 EDIT FIELD HANDLE
            editField = uicontrol(hFig, 'Style', 'edit', ...
                'String', char(val), ...
                'Position', [240, y, 340, 25], ...
                'FontSize', 10, ...
                'BackgroundColor', [0.98 0.98 0.98], ...
                'Callback', @(src,~) updateField(field, src));

            if contains(titleName, 'path')
                if ismember(field, {'MATLABexe','proteoWizard','psqlExe','ISExcel','CompExcel'})
                    uicontrol(hFig, 'Style', 'pushbutton', ...
                        'String', 'Browse...', ...
                        'Position', [590, y, 80, 25], ...
                        'FontSize', 10, ...
                        'Callback', @(~,~) browsePath(field, editField, 'file'));
                else
                    uicontrol(hFig, 'Style', 'pushbutton', ...
                        'String', 'Browse...', ...
                        'Position', [590, y, 80, 25], ...
                        'FontSize', 10, ...
                        'Callback', @(~,~) browsePath(field, editField, 'folder'));
                end
            end

        elseif isnumeric(val)
            uicontrol(hFig, 'Style', 'edit', ...
                'String', num2str(val), ...
                'Position', [240, y, 100, 25], ...
                'FontSize', 10, ...
                'BackgroundColor', [0.98 0.98 0.98], ...
                'Callback', @(src,~) updateField(field, src));
        end

        y = y - rowHeight;
    end

    % Buttons
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Save', ...
        'Position', [guiWidth/2 - 110, 20, 100, 30], ...
        'Callback', @saveCallback);

    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Cancel', ...
        'Position', [guiWidth/2 + 10, 20, 100, 30], ...
        'Callback', @cancelCallback);

    uiwait(hFig);
    updatedParameters = updatedStruct;

    % ================= Helpers =================

    function editNested(fieldName)
        sub = updatedStruct.(fieldName);
        edited = editParametersGUI(sub, ['Edit: ' fieldName]);
        if ~isempty(edited)
            updatedStruct.(fieldName) = edited;
        end
    end

    function updateField(fieldName, src)
        originalVal = inputStruct.(fieldName);
        str = src.String;

        if isnumeric(originalVal)
            v = str2double(str);
            if isnan(v)
                warndlg(['Invalid numeric input for "' fieldName '"']);
                return;
            end
            updatedStruct.(fieldName) = v;
        else
            updatedStruct.(fieldName) = str;
        end
    end

    function browsePath(fieldName, editHandle, type)
        if nargin < 3
            type = 'folder';
        end

        current = updatedStruct.(fieldName);

        switch type
            case 'file'
                start = fileparts(current);
                if isempty(start), start = pwd; end
                [f,p] = uigetfile({'*.*','All Files'}, 'Select file', start);
                if isequal(f,0), return; end
                newPath = fullfile(p,f);

            case 'folder'
                if isfolder(current)
                    newPath = uigetdir(current);
                else
                    newPath = uigetdir;
                end
                if newPath == 0, return; end
        end

        updatedStruct.(fieldName) = newPath;
        editHandle.String = newPath;   % ⭐ FIX
        drawnow;
    end

    function toggleLogical(fieldName, src)
        v = logical(src.Value);
        src.String = logicalToString(v);
        updatedStruct.(fieldName) = v;
    end

    function updateArrayElement(fieldName, idx, src)
        v = str2double(src.String);
        if isnan(v)
            warndlg('Invalid numeric input');
            return;
        end
        tmp = updatedStruct.(fieldName);
        tmp(idx) = v;
        updatedStruct.(fieldName) = tmp;
    end

    function saveCallback(~,~)
        uiresume(hFig);
        delete(hFig);
    end

    function cancelCallback(~,~)
        updatedStruct = [];
        uiresume(hFig);
        delete(hFig);
    end
end

% -------- Utilities --------

function pos = centerFig(w,h)
    s = get(0,'ScreenSize');
    pos = [(s(3)-w)/2, (s(4)-h)/2, w, h];
end

function s = logicalToString(b)
    if b, s = 'true'; else, s = 'false'; end
end


