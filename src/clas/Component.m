classdef Component
    properties
        % This data is from Excel
        ID % example 'lw208' 
        Name 
        Formula
        Adduct_pos % e.g., [M+H]+
        Adduct_neg
        RT % retention time
        mz_pos 
        mz_neg
        Noise
        Baseline
        peakwindow
        noisewindow


        % This data is results data that is filled during the processing
        foundRT
        normRT
        deltaRT
        intensity
        normint
        identificationConfidence
        similarity
        massaccuracy
        EIC % Extracted Ion Chromatogram
        MS1 % MS1 spectrum from the peak max in EIC
        MS2 % MS2 spectrum if found
        
        
    end
    
    methods
        %% Constructor
        function obj = Component(dataRow)
            % Constructor expects one row from Components.xlsx 
            if nargin > 0
                obj.ID = dataRow.ID;
                obj.Name = dataRow.Name;
                obj.Formula = dataRow.Formula;
                obj.Adduct_pos = dataRow.Adduct_pos;
                obj.Adduct_neg = dataRow.Adduct_neg;
                obj.RT = dataRow.RT;
                obj.mz_pos = dataRow.mz_pos;
                obj.mz_neg = dataRow.mz_neg;
                obj.foundRT = NaN;
                obj.intensity = NaN;
                obj.normint = NaN;
                obj.identificationConfidence = '';
                obj.similarity = NaN;
                obj.massaccuracy = NaN;
                obj.Noise = NaN;
                obj.Baseline = NaN;
                obj.peakwindow = [NaN NaN];
                obj.noisewindow = [NaN NaN];
                obj.deltaRT = NaN;
                obj.normRT = NaN;
                
                
            end
        end
        function s = exportStruct(obj)
            % ExportStruct: Gibt eine Struktur mit den wichtigsten Properties zurück
            
            % Stammdaten aus Excel
            s.ID        = obj.ID;
            s.Name      = obj.Name;
            s.Formula   = obj.Formula;
            s.Adduct_pos = obj.Adduct_pos;
            s.Adduct_neg = obj.Adduct_neg;
            s.RT        = obj.RT;
            s.mz_pos    = obj.mz_pos;
            s.mz_neg    = obj.mz_neg;
            s.Noise     = obj.Noise;
            s.Baseline  = obj.Baseline;
            s.peakwindow = obj.peakwindow;
            s.noisewindow = obj.noisewindow;
            
            % Verarbeitungsergebnisse
            s.foundRT   = obj.foundRT;
            s.intensity = obj.intensity;
            s.normint   = obj.normint;
            s.identificationConfidence = obj.identificationConfidence;
            s.similarity = obj.similarity;
            s.massaccuracy = obj.massaccuracy;
            s.EIC       = obj.EIC;
            s.MS1       = obj.MS1;
            s.MS2       = obj.MS2;
            s.deltaRT = obj.deltaRT;
            s.normRT =  obj.normRT;
            
        end

        %% Perform peak detection and save extracted features
        function obj = peakdetection(obj, ms1_data, RTcorrectionFactor, Parameters, type)
            m_z_ms1 = obj.PosNegDistinction(1, ms1_data(1).polarity);
            if isnan(m_z_ms1) || (obj.RT < Parameters.MS1.MSDataRange(1)) || (obj.RT > Parameters.MS1.MSDataRange(2))
                return
            end

            % Extract MS1 window RT  +-40 seconds
            upper_RT = (obj.RT + RTcorrectionFactor) * 60 + 5 * Parameters.chroma.RTToleranceInSec;
            lower_RT = (obj.RT + RTcorrectionFactor) * 60 - 5 * Parameters.chroma.RTToleranceInSec;
            extracted_ms_data = ms_data_window(ms1_data, [lower_RT, upper_RT]);
            [scanTimes, ionIntensities] = ExtractEICData(extracted_ms_data, m_z_ms1, (m_z_ms1 * Parameters.MS1.XICtolerance_ppm) / 1e6);

            % Smoothing ------------------------------------------------------------
            % Savitzky-Golay smoothing
            if Parameters.pre_treatment.Savitzky.on
                for S = 1:Parameters.pre_treatment.Savitzky.loops
                    ionIntensities = smoothdata(ionIntensities, 'sgolay', Parameters.pre_treatment.Savitzky.windowsize);
                    ionIntensities(ionIntensities < 0) = 0;
                end
            end

            % Gaussian smoothing
            if Parameters.pre_treatment.Gaussian.on
                x = linspace(-Parameters.pre_treatment.Gaussian.kernelSize / 2, Parameters.pre_treatment.Gaussian.kernelSize / 2, Parameters.pre_treatment.Gaussian.kernelSize);
                gaussKernel = exp(-x .^ 2 / (2 * Parameters.pre_treatment.Gaussian.sigma ^ 2));
                gaussKernel = gaussKernel / sum(gaussKernel); % Normalize
                ionIntensities = conv(ionIntensities, gaussKernel, 'same');
                ionIntensities(ionIntensities < 0) = 0;
            end

            % EIC -------------------------------------------------------------------
            if strcmp(type, Parameters.chroma.TypeforRTCorr)
                isblank = 1;
            else
                isblank = 0;
            end
            [obj.foundRT, obj.intensity, obj.noisewindow, obj.peakwindow , obj.Noise, ~, obj.Baseline] = MS1Check(scanTimes, ...
                ionIntensities, Parameters, obj.RT + RTcorrectionFactor, isblank);

            obj.EIC = [scanTimes, ionIntensities];

            % MS1 -------------------------------------------------------------------
            % Save MS1 spectrum at peak max
            ms1_times = StructColumn2Vec(ms1_data, 'retentionTime');
          
            if isnan(obj.foundRT)
                % No peak found  take nearest expected RT spectrum
                differences = abs(ms1_times - obj.RT);
                [~, MSSpectraIndex] = min(differences);
            else
                MSSpectraIndex = find(obj.foundRT == ms1_times);
            end
          
            mz_values = ms1_data(MSSpectraIndex).ScanData(:,1);
            intensityValues = ms1_data(MSSpectraIndex).ScanData(:,2);

            % Keep only values around expected m/z
            delta = (mz_values - m_z_ms1);
            keepindex = (delta <= 2.5 & delta > -0.5);
            mz_values = mz_values(keepindex);
            intensityValues = intensityValues(keepindex);
            obj.MS1 = [mz_values, intensityValues];

            % Calculate mass accuracy
            obj.massaccuracy = calcmassaccuracy(obj.foundRT, m_z_ms1, ms1_data, Parameters);
        end

        %% MS2 Check
        % Performs MS2 spectrum matching against a spectral library using cosine similarity.
        %
        % This method filters MS2 spectra around the retention time of a detected feature,
        % compares each spectrum to a reference spectrum from the library,
        % and retains the best-matching one based on cosine similarity.
        %
        % Inputs:
        %   obj         - The object instance (assumed to contain properties like intensity, foundRT, etc.)
        %   ms2data     - Struct array containing MS2 data with fields like retentionTime and ScanData
        %   Parameters  - Struct containing processing parameters, including:
        %                   Parameters.path.program        : Base path to the program
        %                   Parameters.MS2.libname         : Name of the MS2 library folder
        %                   Parameters.MS2.removePrecursor : Boolean flag to remove precursor peaks
        %                   Parameters.MS2.mzTolerance_ppm : Mass tolerance in ppm
        %                   Parameters.MS2.binWidth        : Bin width for spectrum binning
        %                   Parameters.MS2.binOffset       : Bin offset for spectrum binning
        %                   Parameters.MS2.threshold       : Intensity threshold
        %                   Parameters.chroma.RTToleranceInSec : RT window size in seconds
        %
        % Output:
        %   obj         - Updated object with new fields:
        %                   obj.similarity                : Highest cosine similarity found
        %                   obj.identificationConfidence  : Matching fragment details
        %                   obj.MS2                       : Best matching spectrum
        
        function obj = ms2check(obj, ms2data, Parameters)
            % Exit if the signal is not present
            if isnan(obj.intensity)
                return
            end
        
            try
                % Load polarity and expected adduct
                polarity = ms2data(1).polarity;
                Addukt = obj.PosNegDistinction(3, polarity);
        
                % Build full path to the expected MS2 library file
                filename = strjoin([obj.ID, Addukt, '.json'], "");
                filepath = strjoin([Parameters.path.program ,'\data\' ,'\import\','\mslib\', Parameters.MS2.libname, '\' filename], "");
        
                % Read the reference spectrum from JSON
                dbspectrum = jsondecode(fileread(filepath));

            catch
                warning('No library spectra found for compound ID: %s', obj.ID)
                return
            end
        
            % Extract parameters
            removePrecursor = Parameters.MS2.removePrecursor;
            massTolerance_ppm = Parameters.MS2.mzTolerance_ppm;
            binWidth = Parameters.MS2.binWidth;
            binOffset = Parameters.MS2.binOffset;
            threshold = Parameters.MS2.threshold;
            ms2PrecursorMass = obj.PosNegDistinction(1, polarity);
        
            % Extract MS2 spectra around the chromatographic peak
            idx = [ms2data.retentionTime] >= (obj.foundRT - (Parameters.chroma.RTToleranceInSec/60)) & ...
                  [ms2data.retentionTime] <= (obj.foundRT + (Parameters.chroma.RTToleranceInSec/60));
            filteredData = ms2data(idx);
        
            % Compare all spectra in the window against the library spectrum
            for entry = filteredData
                spectra1 = entry.ScanData;
                try
                    [cosine_similarity, fragMatch] = cosineMS2(spectra1, dbspectrum, ...
                        binWidth, binOffset, threshold, massTolerance_ppm, removePrecursor, ms2PrecursorMass);
                                % Keep best match
                    if isnan(obj.similarity) || obj.similarity < cosine_similarity
                        obj.identificationConfidence = fragMatch;
                        obj.similarity = cosine_similarity;
                        obj.MS2 = entry.ScanData;
                    end
                catch
                    str = sprintf('Error in cosineMS2 - Please check the JSON file %s structure',filepath);
                    WarningPlusDb(str,Parameters,'Processing Setting');
                end
            end
        end

        %% Generate SQL INSERT command for ComponentValue
        function [sqlInsertCommand, columnsStr, valuesStr] = toSQL(obj, SampleID, Parameters, polarity)
            % Target: Entry in "ComponentValue" table
            Tablename = 'ComponentValue';
            metatable = Parameters.database.tables.(Tablename);
            namesInTable = metatable.Names;
        
            % Convert object to structure
            s = exportStruct(obj);
        
            % Add mandatory fields
            s.SampID = SampleID;
            s.ID = obj.ID;
        
            % Manually split EIC if present
            if isfield(s, 'EIC') && ~isempty(s.EIC) && size(s.EIC, 2) == 2
                s.EICScanTime = s.EIC(:, 1);
                s.EICIntensity = s.EIC(:, 2);
                s = rmfield(s, 'EIC');
            end
        
            % Split MS1
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
                'Name', 'Name';
                'RTfound', 'RT';
                'intensity', 'intensity';
                'normint', 'normIntensities';
                'identificationConfidence', 'identificationConfidence';
                'massaccuracy', 'massaccuracy';
                'Noise', 'noise';
                'Baseline', 'baseline';
                'peakwindow', 'peakwindow';
                'noisewindow', 'noisewindow';
                'similarity', 'similarity';
            };
        
            % Perform mapping
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
                    % Field does not exist  ignore
                end
            end

            % Keep only valid fields that are in the DB table
            s_filtered = rmfield(s, setdiff(fieldnames(s), namesInTable));
            % s_filtered.peakwindow = s_filtered.peakwindow';
            % s_filtered.noisewindow = s_filtered.noisewindow';
        
            % Generate SQL command
            [sqlInsertCommand, columnsStr, valuesStr] = createSQLInsertCommand(Parameters, Tablename, s_filtered);
        end
 
        %% Return the m/z or Adduct depending on MS level and mode
        % Author: Linus Strähle
        % Date: 2024-03-24
        function return_value = PosNegDistinction(obj, Level, Mode)
            if Level == 1
                if Mode == '-'
                    return_value = obj.mz_neg;
                else
                    return_value = obj.mz_pos;
                end
            elseif Level == 3
                if Mode == '-'
                    return_value = obj.Adduct_neg;
                else
                    return_value = obj.Adduct_pos;
                end
            end
        end
    end
end
