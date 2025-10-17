classdef Sample
    % SAMPLE - Class for representing and processing an MS sample.
    %
    % This class encapsulates the workflow for processing mass spectrometry
    % data, including metadata extraction, RT correction, peak detection,
    % and storage in a relational database.

    properties
        ID                          % Sample ID (derived from filename)
        timestamp_of_measurement   % Time of data acquisition
        sampling_timestamp         % Time the sample was taken
        Type                        % Sample classification (e.g. Blank, QC)
        MSMode                      % Ion mode: '+' or '-'
        MS2Mode                     % MS2 mode: DDA or DIA
        ISdic                       % Dictionary of Internal Standards
        Compdic                     % Dictionary of Components
        ISCheck                     % Boolean or flag if sample passed device checks
        RTCorrection                % RT correction factor (in seconds)
    end

    methods
        function obj = Sample(FilePath, ms1_data, ms2_data, Parameters)
            % Constructor for the Sample class
            % Loads metadata, sample type, MS mode, and initializes dictionaries.
        
            [~, filename, ~] = fileparts(FilePath);
            obj.ID = filename;
            obj.timestamp_of_measurement = getSampleDate(FilePath, Parameters, Parameters.General.timestamp_of_measurement);
            obj.sampling_timestamp = getSampleDate(FilePath, Parameters, Parameters.General.sampling_timestamp);
            obj.Type = indentifySampleType(obj.ID);
            obj.MSMode = char(ms1_data(1).polarity);
        
            if Parameters.MS2.From
                obj.MS2Mode = MS2ModeFromMSdata(StructColumn2Vec(ms2_data, "PrecursorMass"));
            else
                obj.MS2Mode = getMS2Mode(filename);
            end
        
            obj.ISCheck = NaN;
            obj.RTCorrection = NaN;
        
            %% Load component dictionary
            optsComp = detectImportOptions(Parameters.path.CompExcel);
            optsComp = setvartype(optsComp, {'ID','Name','Formula','Adduct_pos','Adduct_neg'}, 'string');
            optsComp = setvartype(optsComp, {'RT','mz_pos','mz_neg'}, 'double');
            T = readtable(Parameters.path.CompExcel, optsComp);
        
            componentDict = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:height(T)
                comp = Component(T(i,:));
                componentDict(char(comp.ID)) = comp;
            end
            obj.Compdic = componentDict;
        
            %% Load internal standards dictionary
            optsIS = detectImportOptions(Parameters.path.ISExcel);
            optsIS = setvartype(optsIS, {'ID','Name','Formula','Adduct_pos','Adduct_neg'}, 'string');
            optsIS = setvartype(optsIS, {'IS_pos','IS_neg'}, 'logical');
            optsIS = setvartype(optsIS, {'RT','mz_pos','mz_neg'}, 'double');
            T2 = readtable(Parameters.path.ISExcel, optsIS);
        
            ISdict = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i = 1:height(T2)
                is = InternalStandard(T2(i,:));
                ISdict(char(is.ID)) = is;
            end
            obj.ISdic = ISdict;
        end
        %% RT Correction Factor based on historical IS RT values in defined sample type
        function obj = RTCorrectionFactor(obj, Parameters)
            if Parameters.chroma.RTcorrON
                try 
                    % Skip correction if sample type matches exclusion type
                    if strcmp(obj.Type, Parameters.chroma.TypeforRTCorr) 
                        obj.RTCorrection = NaN;
                        return;
                    end
        
                    % Define time window for RT correction
                    nowDate = obj.timestamp_of_measurement;
                    startDate = obj.timestamp_of_measurement - days(Parameters.chroma.maxdaydistanceforRTcorr);
        
                    % Format timestamps for database query
                    nowDateStr = datestr(nowDate, 'yyyy-mm-dd HH:MM:SS');
                    startDateStr = datestr(startDate, 'yyyy-mm-dd HH:MM:SS');
        
                    % Define query parameters
                    extract = 'foundRT';
                    Table = 'ISValue';
                    DBISCheck = 'true';
                    SampleType = Parameters.chroma.TypeforRTCorr;
        
                    % Query database for IS RT data
                    [ISRTTable, ~] = SQLRequest(startDateStr, nowDateStr, obj.MSMode, extract, Table, DBISCheck, SampleType, Parameters);
                    if height(ISRTTable) == 0
                        error('No data in table');
                    end
        
                    
                    % Determine MS mode and corresponding IS key and threshold
                    if strcmp(obj.MSMode, '+')
                        ISKey = 'IS_pos';
                    else 
                        ISKey = 'IS_neg';
                    end
                    % Filter out irrelevant IS columns
                    ISRTTable = filterIS(ISRTTable, obj.ISdic, ISKey);
        
                    % Normalize retention times to target RT in seconds
                    columnNames = ISRTTable.Properties.VariableNames;
                    for i = 1:numel(columnNames)
                        columnName = columnNames{i};
                        if strcmp(columnName, 'datetime_aq'), continue; end
                        ISRTTable.(columnName) = (ISRTTable.(columnName) - obj.ISdic(columnName).RT) * 60;
                    end
        
                    % Use latest values to calculate correction
                    lastRow = ISRTTable(end, 2:end);
                    values = table2array(lastRow);
                    obj.RTCorrection = median(values, 'omitnan');
                catch
                    obj.RTCorrection = NaN;
                    WarningPlusDb('No RT correction possible.',Parameters, 'Processing Setting');
                end
            else
                obj.RTCorrection = NaN;
            end
        end
        %% Peak detection for all entries in a given dictionary (ISdic or Compdic)
        function obj = dicpeakdetection(obj, dicname, msdata, Parameters)
            % If RT correction is NaN, default to 0 shift
            if isnan(obj.RTCorrection)
                RTcorrectionFactor = 0;
            else
                RTcorrectionFactor = obj.RTCorrection / 60;  % Convert seconds to minutes
            end

            % Get the target dictionary
            dicMap = obj.(dicname);
            keyList = keys(dicMap);

            % Apply peak detection to each dictionary entry
            for i = 1:length(keyList)
                key = keyList{i};
                if isKey(dicMap, key)
                    entry = dicMap(key);
                    try
                        dicMap(key) = entry.peakdetection(msdata, RTcorrectionFactor, Parameters, obj.Type);
                    catch ME
                        warning("Peak detection failed for %s: %s", key, ME.message);
                    end
                end
            end
        end
        %% MS2 spectrum check for dictionary entries (DDA only)
        function obj = dicMS2Check(obj, dicname, ms2data, Parameters)
            % Only apply MS2 checking if sample was acquired in DDA mode
            if strcmp(obj.MS2Mode, 'DDA')
                dicMap = obj.(dicname);
                keyList = keys(dicMap);

                % Apply MS2 validation to each entry
                for i = 1:length(keyList)
                    key = keyList{i};
                    if isKey(dicMap, key)
                        entry = dicMap(key);
                        try
                            dicMap(key) = entry.ms2check(ms2data, Parameters);
                        catch ME
                            warning("MS2 check failed for %s: %s", key, ME.message);
                        end
                    end
                end
            else
                warning('MS2Check skipped: Not a DDA acquisition.');
            end
        end
        %% Display the contents of a given dictionary (ISdic or Compdic)
        function T = showdic(obj, dicname)
            % Access the selected dictionary
            dicMap = obj.(dicname);
            keyList = keys(dicMap);

            % Convert all entries to exportable structs
            entries = cell(length(keyList), 1);
            for i = 1:length(keyList)
                key = keyList{i};
                entry = dicMap(key);
                entries{i} = entry.exportStruct();
            end

            % Convert to table and display
            T = struct2table(vertcat(entries{:}));
            disp(T);
        end
        %% Save core Sample metadata to the SQL database
        function toSQL(obj, Parameters)
            % Define table name and metadata format
            Tablename = 'SampleMaster';
            metatable = Parameters.database.tables.(Tablename);
            namesInTable = metatable.Names;

            % Convert object properties to struct
            s = struct(obj);

            % Define how to rename fields to match DB schema
            fieldMapping = {
                'ID', 'SampleID';
                'Type', 'type';
                'MSMode', 'polarity';
                'ISCheck', 'ISCheck';
                'timestamp_of_measurement', 'datetime_aq';
                'sampling_timestamp', 'datetime_samp';
                'RTCorrection','RTCorrection'
            };

            % Construct DB-struct with renamed fields only
            s_db = struct();
            for i = 1:size(fieldMapping, 1)
                origField = fieldMapping{i,1};
                newField = fieldMapping{i,2};
                if isfield(s, origField)
                    s_db.(newField) = s.(origField);
                end
            end

            % Generate SQL insert command
            [sqlInsertCommand, ~, ~] = createSQLInsertCommand(Parameters, Tablename, s_db);

            % Write and execute SQL file
            filepath = newsqlfile(Parameters);
            SQLfileID = fopen(filepath, 'w');
            fprintf(SQLfileID, '%s\n', sqlInsertCommand);
            fclose(SQLfileID);
            runsqlfile(filepath, Parameters);
        end
                %% Save dictionary values (ISdic or Compdic) to SQL database with size management
        function dic2db(obj, dicname, Parameters)
            % Define maximum file size (e.g., 5 MB)
            maxSizeMB = 5;
            maxSizeBytes = maxSizeMB * 1024 * 1024;

            % Create a new SQL file path
            sqlPath = newsqlfile(Parameters);
            SQLfileID = fopen(sqlPath, 'w');

            % Iterate over all entries in the dictionary
            dicMap = obj.(dicname);
            keyList = keys(dicMap);
            for i = 1:length(keyList)
                key = keyList{i};
                entry = dicMap(key);

                % Skip entries with no polarity match
                if isnan(entry.PosNegDistinction(1, obj.MSMode))
                    continue;
                end

                % Generate SQL insert command for entry
                [sqlInsertCommand, ~, ~] = entry.toSQL(obj.ID, Parameters, obj.MSMode);

                % Check current file size
                fseek(SQLfileID, 0, 'eof');
                fileSize = ftell(SQLfileID);
                if fileSize > maxSizeBytes
                    fclose(SQLfileID);
                    runsqlfile(Parameters, 'Sample');
                    sqlPath = newsqlfile(Parameters);
                    SQLfileID = fopen(sqlPath, 'w');
                end

                % Write SQL command to file
                fprintf(SQLfileID, '%s\n', sqlInsertCommand);
            end

            % Finalize and execute last SQL file
            fclose(SQLfileID);
            runsqlfile(sqlPath, Parameters);
        end

        %% Perform system suitability checks using internal standards
        function obj = DeviceControl(obj, Parameters)
            SampleISCheck = true;

            % Determine MS mode and IS polarity selector
            if strcmp(obj.MSMode, '+')
                minimumISnumber = Parameters.DeviceControl.minimumISpos;
                ISKey = 'IS_pos';
            else
                minimumISnumber = Parameters.DeviceControl.minimumISneg;
                ISKey = 'IS_neg';
            end

            % Time window for check
            nowDate = obj.timestamp_of_measurement;
            startDate = nowDate - days(Parameters.DeviceControl.interval_days);
            nowStr = datestr(nowDate, 'yyyy-mm-dd HH:MM:SS');
            startStr = datestr(startDate, 'yyyy-mm-dd HH:MM:SS');

            % Prepare plot figure
            fig = figure('Visible','off', 'Position', [100, 100, 1300, 800]);
            sgtitle('Device Control');
            markers = repmat({'o-', '*-', 'x-', 's-', 'd-', '^-', 'v-', '>-', '<-'}, 20, 1);
            warningText = "Sample failed IS Check";

            %% RT Deviation Check
            [RTTable, ~] = SQLRequest(startStr, nowStr, obj.MSMode, 'foundRT', 'ISValue', '', '', Parameters);
            RTTable = filterIS(RTTable, obj.ISdic, ISKey);
            RTTable_abs=RTTable(:,2:end);
            sz = [1,width(RTTable)-1]; % Create Median table 
            varType = repmat("double",1,width(RTTable)-1); 
            medianRT = table('Size',sz,'VariableTypes',varType,'VariableNames',RTTable.Properties.VariableNames(2:end));
            medianRT{:,:} = NaN;
            normRT = table('Size',sz,'VariableTypes',varType,'VariableNames',RTTable.Properties.VariableNames(2:end));
            normRT{:,:} = NaN;
            for col = RTTable.Properties.VariableNames(2:end)
                RTTable.(col{1}) = (RTTable.(col{1}) - median(RTTable.(col{1}), 'omitnan')) * 60;
                medianRT.(col{1}) = median(RTTable_abs.(col{1}), 'omitnan');

            end
            % break if array is empty
            % if height(RTTable)==0
            %     return;
            % end
            % Normalise Retention times x/median(x)
            lastRTs_abs = RTTable_abs{end, :}; % Last RTs in min
            normRT = lastRTs_abs./ medianRT; % Normalised RT

            lastRTs = RTTable{end, 2:end}; % Deviation in seconds
            valid = lastRTs(~isnan(lastRTs));
            %lastRTs = array2table(lastRTs,'VariableNames',RTTable.Properties.VariableNames(2:end)); % Convert to table
            
            inRange = (valid > Parameters.DeviceControl.RT_lowerLimit) & (valid < Parameters.DeviceControl.RT_upperLimit);
            if sum(inRange) < minimumISnumber
                msg = sprintf('Warning: %.0f of %.0f internal standards are out of RT range', numel(valid) - sum(inRange), numel(valid));
                WarningPlusDb(msg, Parameters, 'Device');
                SampleISCheck = false;
                warningText = [warningText, ' | ', msg];
            end
            plotDeviceMetric(RTTable, Parameters.DeviceControl.RT_lowerLimit, Parameters.DeviceControl.RT_upperLimit, 'RT deviation / s', 'Internal Standard Retention Time Deviation', markers);
            % Save normalized RT and deltaRT to DB
            % Upload deviation in seconds
            filepath = newsqlfile(Parameters);
            fid = fopen(filepath, 'w');
            for i = 1:length(RTTable.Properties.VariableNames)-1
                name = RTTable.Properties.VariableNames{i+1};
                deltaVal = lastRTs(i);
                entry = obj.ISdic(name);
                entry.deltaRT = deltaVal;
                obj.ISdic(name) = entry;
                cmd = createSimpleSQLUpdateCommand(Parameters.database.schema, 'ISValue', 'deltaRT', deltaVal, {'ID', name; 'SampID', obj.ID});
                fprintf(fid, '%s\n', cmd);
            end
            fclose(fid);
            runsqlfile(filepath, Parameters);
            % Upload normalized retention times
            filepath = newsqlfile(Parameters);
            fid = fopen(filepath, 'w');
            for i = 1:length(RTTable.Properties.VariableNames)-1
                name = RTTable.Properties.VariableNames{i+1};
                normVal = normRT(:,i);
                normVal=table2array(normVal);
                entry = obj.ISdic(name);
                entry.normRT = normVal;
                obj.ISdic(name) = entry;
                cmd = createSimpleSQLUpdateCommand(Parameters.database.schema, 'ISValue', 'normRT', normVal, {'ID', name; 'SampID', obj.ID});
                fprintf(fid, '%s\n', cmd);
            end
            fclose(fid);
            runsqlfile(filepath, Parameters);
            %% Mass Accuracy Check
            [MACTable, ~] = SQLRequest(startStr, nowStr, obj.MSMode, 'massaccuracy', 'ISValue', '', '', Parameters);
            MACTable = filterIS(MACTable, obj.ISdic, ISKey);

            lastMAC = MACTable{end, 2:end};
            valid = lastMAC(~isnan(lastMAC));
            inRange = abs(valid) < Parameters.DeviceControl.massaccuracy;
            if sum(inRange) < minimumISnumber
                msg = sprintf('Warning: %.0f of %.0f internal standards are out of mass accuracy range', numel(valid) - sum(inRange), numel(valid));
                WarningPlusDb(msg, Parameters, 'Device');
                SampleISCheck = false;
                warningText = [warningText, ' | ', msg];
            end
            plotDeviceMetric(MACTable, -Parameters.DeviceControl.massaccuracy, Parameters.DeviceControl.massaccuracy, 'Mass accuracy / ppm', 'Internal Standard Mass Accuracy', markers);

            %% Intensity Check
            [intTable, ~] = SQLRequest(startStr, nowStr, obj.MSMode, 'intensity', 'ISValue', '', '', Parameters);
            for col = intTable.Properties.VariableNames(2:end)
                if ~obj.ISdic(col{1}).(ISKey)
                    intTable.(col{1}) = [];
                end
            end

            for col = intTable.Properties.VariableNames(2:end)
                logs = log10(intTable.(col{1}));
                normed = median(logs, 'omitnan') - logs;
                intTable.(col{1}) = 10 .^ (-normed);
            end

            lastInt = intTable{end, 2:end};
            valid = lastInt(~isnan(lastInt));
            inRange = (valid > Parameters.DeviceControl.intensity_lowerLimit) & (valid < Parameters.DeviceControl.intensity_upperLimit);
            if sum(inRange) < minimumISnumber
                msg = sprintf('Warning: %.0f of %.0f internal standards are out of intensity range', numel(valid) - sum(inRange), numel(valid));
                WarningPlusDb(msg, Parameters, 'Device');
                SampleISCheck = false;
                warningText = [warningText, ' | ', msg];
            end

            % Save normalized intensities to DB
            filepath = newsqlfile(Parameters);
            fid = fopen(filepath, 'w');
            for i = 1:length(intTable.Properties.VariableNames)-1
                name = intTable.Properties.VariableNames{i+1};
                normVal = intTable{end, i+1};
                entry = obj.ISdic(name);
                entry.normint = normVal;
                obj.ISdic(name) = entry;
                cmd = createSimpleSQLUpdateCommand(Parameters.database.schema, 'ISValue', 'normIntensities', normVal, {'ID', name; 'SampID', obj.ID});
                fprintf(fid, '%s\n', cmd);
            end
            fclose(fid);
            runsqlfile(filepath, Parameters);

            % Plot and store normalized intensity
            [normIntTable, ~] = SQLRequest(startStr, nowStr, obj.MSMode, 'normIntensities', 'ISValue', '', '', Parameters);
            normIntTable = filterIS(normIntTable, obj.ISdic, ISKey);
            plotDeviceMetric(normIntTable, Parameters.DeviceControl.intensity_lowerLimit, Parameters.DeviceControl.intensity_upperLimit, 'Relative Intensity', 'Internal Standard Intensity', markers, true);
            
            % Save figure and convert to Base64
            imgPath = fullfile(Parameters.path.program, 'src', 'mail', 'images', ...
                    sprintf('DeviceControl_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            
            exportgraphics(fig, imgPath, 'Resolution', 600);
            imgData = fread(fopen(imgPath, 'rb'), '*uint8');
            base64 = matlab.net.base64encode(imgData);
            imgTag = sprintf('<img src="data:image/png;base64,%s" alt="Graph" class="graph">', base64);

            % Final ISCheck status
            obj.ISCheck = ISCheckfailed(SampleISCheck, warningText, imgTag, obj, Parameters);
            close(fig);
            if exist(imgPath, 'file')
                delete(imgPath);
            end
        end

    end
end
