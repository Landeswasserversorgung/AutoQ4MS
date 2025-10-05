function date  = getSampleDate(filepath, Parameters,option)
% This Function returns the Sample Date
% For the Calculation of the Sample Date there are three Options with set
% in Parameters struct.
%       1       the current date
%       2       the date that is stored in the file (only for wiff files)
%       3       the last modified date from the ms data set - the Masurement Time
%   Linus Straehle 2024-07-11

     switch option
            case 0
                date = datetime(NaT);
            case 1
                date = datetime('now');
            case 2
                try
                    date = extractDateFromWiff(filepath);
                catch
                    date = datetime(NaT);
                    WarningPlusDb('no date extraction possible', Parameters, 'Settings'); 
                end
            case 3
                fileinfo = dir(filepath);
                date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') - minutes(Parameters.chroma.MeasurementTime_min);
            case 4
                % from corresponding wiff or wiff2 file  
                [pathstr, name, ~] = fileparts(filepath);
                
                rawname =  name + Parameters.General.RawMS_Format;
                rawdatafilename =fullfile(pathstr, rawname);
                fileinfo = dir(rawdatafilename);
                try
                date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') - minutes(Parameters.chroma.MeasurementTime_min);
                catch
                    fprintf("%s was not found \n", rawdatafilename);  
                end
                % try 
                %     rawdatafilename = fullfile(pathstr, [name '.wiff']);
                %     fileinfo = dir(rawdatafilename);
                %     date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') - minutes(Parameters.chroma.MeasurementTime_min);
                % catch
                %     rawdatafilename = fullfile(pathstr, [name '.wiff2']);
                %     fileinfo = dir(rawdatafilename);
                %     date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') - minutes(Parameters.chroma.MeasurementTime_min);
                % end

         otherwise
                error('wrong Value for Parameters.General.SampleDate')
     end
end

