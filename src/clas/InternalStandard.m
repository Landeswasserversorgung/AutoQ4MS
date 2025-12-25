classdef InternalStandard < Component
%INTERNALSTANDARD  Specialized Component representing an internal standard.
%
%   This class extends Component with polarity flags (IS_pos / IS_neg) and
%   provides export and SQL serialization helpers.

    properties
        IS_pos
        IS_neg
    end

    methods
        %% Constructor
        function obj = InternalStandard(dataRow)
            %INTERNALSTANDARD  Construct an InternalStandard from a table row.
            %
            %   The base Component constructor is called first. Then the
            %   subclass-specific flags IS_pos / IS_neg are loaded if present.

            obj@Component(dataRow); % Call parent class constructor

            if ismember('IS_pos', dataRow.Properties.VariableNames)
                obj.IS_pos = dataRow.IS_pos;
            end
            if ismember('IS_neg', dataRow.Properties.VariableNames)
                obj.IS_neg = dataRow.IS_neg;
            end
        end

        function s = exportStruct(obj)
            %EXPORTSTRUCT  Export the key properties and processing results as a struct.

            % Metadata (from Excel / configuration)
            s.ID         = obj.ID;
            s.Name       = obj.Name;
            s.Formula    = obj.Formula;
            s.Adduct_pos = obj.Adduct_pos;
            s.Adduct_neg = obj.Adduct_neg;
            s.RT         = obj.RT;
            s.mz_pos     = obj.mz_pos;
            s.mz_neg     = obj.mz_neg;
            s.Noise      = obj.Noise;
            s.Baseline   = obj.Baseline;
            s.peakwindow = obj.peakwindow;
            s.noisewindow = obj.noisewindow;

            % Processing results
            s.foundRT                  = obj.foundRT;
            s.intensity                = obj.intensity;
            s.normint                  = obj.normint;
            s.identificationConfidence = obj.identificationConfidence;
            s.deltaRT                  = obj.deltaRT;
            s.normRT                   = obj.normRT;

            s.massaccuracy = obj.massaccuracy;
            s.EIC          = obj.EIC;
            s.MS1          = obj.MS1;
            s.MS2          = obj.MS2;

            % Polarity flags (for display / filtering)
            s.IS_pos = obj.IS_pos;
            s.IS_neg = obj.IS_neg;
        end

        %% Generate SQL INSERT command for ISValue table
        function [sqlInsertCommand, columnsStr, valuesStr] = toSQL(obj, SampleID, Parameters, polarity)
            %TOSQL  Generate an INSERT command for the ISValue table.
            %
            %   [sqlInsertCommand, columnsStr, valuesStr] = toSQL(obj, SampleID, Parameters, polarity)
            %
            %   Inputs:
            %     SampleID    - Value stored in ISValue.SampID
            %     Parameters  - Project parameters (expects Parameters.database.tables.ISValue)
            %     polarity    - '+' or '-' (selects which IS flag is mapped into the DB field "IS")

            Tablename = 'ISValue';
            metatable = Parameters.database.tables.(Tablename);
            namesInTable = metatable.Names; %#ok<NASGU>

            % Convert object to struct snapshot
            s = exportStruct(obj);

            % Required/mapped fields
            s.SampID = SampleID;
            s.ID = obj.ID;

            if polarity == '-'
                IS = "IS_neg";
            else
                IS = "IS_pos";
            end

            % Split EIC (if present and valid)
            if isfield(s, 'EIC') && ~isempty(s.EIC) && size(s.EIC, 2) == 2
                s.EICScanTime = s.EIC(:, 1);
                s.EICIntensity = s.EIC(:, 2);
                s = rmfield(s, 'EIC');
            end

            % Split MS1 (if present and valid)
            if isfield(s, 'MS1') && ~isempty(s.MS1) && size(s.MS1, 2) == 2
                s.PeakMaxMSmz = s.MS1(:, 1);
                s.PeakMaxMSintensity = s.MS1(:, 2);
                s = rmfield(s, 'MS1');
            end

            % Split MS2 (if present and valid)
            if isfield(s, 'MS2') && ~isempty(s.MS2) && size(s.MS2, 2) == 2
                s.MS2mz = s.MS2(:, 1);
                s.MS2_intensity = s.MS2(:, 2);
                s = rmfield(s, 'MS2');
            end

            % Optional field mapping
            renameFields = {
                'foundRT', 'foundRT';
                'Name', 'Name';
                'intensity', 'intensity';
                'identificationConfidence', 'identificationConfidence';
                'massaccuracy', 'massaccuracy';
                'ISCheck', 'ISCheck';
                IS, 'IS';
                'similarity', 'similarity';
            };

            % Populate mapped values (missing fields are ignored and will become NULL later)
            for i = 1:size(renameFields, 1)
                source = split(renameFields{i, 1}, '.');
                target = renameFields{i, 2};

                try
                    if numel(source) == 1
                        s.(target) = obj.(source{1});
                    elseif numel(source) == 2
                        s.(target) = obj.(source{1}).(source{2});
                    end
                catch
                    % Field not available -> ignore (treated as NULL by createSQLInsertCommand)
                end
            end

            % Keep only fields that exist in the database table
            s_filtered = rmfield(s, setdiff(fieldnames(s), metatable.Names));

            % Generate SQL insert command
            [sqlInsertCommand, columnsStr, valuesStr] = createSQLInsertCommand(Parameters, Tablename, s_filtered);
        end
    end
end



