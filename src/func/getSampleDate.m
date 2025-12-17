function date = getSampleDate(filepath, Parameters, option)
%GETSAMPLEDATE  Determine the sample date based on the selected strategy.
%
%   date = getSampleDate(filepath, Parameters, option)
%   Returns a datetime value representing the sample date. The behavior
%   depends on the selected option.
%
%   Options:
%     0 - Return NaT (no sample date)
%     1 - Use the current system date and time
%     2 - Extract the date stored in the file (currently only for .wiff files)
%     3 - Use the last modification time of the MS data file minus the
%         measurement duration
%     4 - Use the last modification time of the corresponding raw MS file
%         (e.g. .wiff / .wiff2 or configured raw format) minus the
%         measurement duration
%
%   Inputs:
%     filepath   - Full path to the MS data file
%     Parameters - Project parameters struct
%     option     - Integer defining the date extraction mode (see above)
%
%   Output:
%     date       - MATLAB datetime object (or NaT if unavailable)
%

    switch option
        case 0
            % Explicitly return "no date"
            date = datetime(NaT);

        case 1
            % Current date and time
            date = datetime('now');

        case 2
            % Extract date from file metadata (wiff only)
            try
                date = extractDateFromWiff(filepath);
            catch
                date = datetime(NaT);
                WarningPlusDb('no date extraction possible', Parameters, 'Settings');
            end

        case 3
            % Use file modification date minus measurement time
            fileinfo = dir(filepath);
            date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') ...
                   - minutes(Parameters.chroma.MeasurementTime_min);

        case 4
            % Use corresponding raw MS file modification date
            [pathstr, name, ~] = fileparts(filepath);

            rawname = name + Parameters.General.RawMS_Format;
            rawdatafilename = fullfile(pathstr, rawname);

            try
                fileinfo = dir(rawdatafilename);
                date = datetime(fileinfo.datenum, 'ConvertFrom', 'datenum') ...
                       - minutes(Parameters.chroma.MeasurementTime_min);
            catch
                fprintf('%s was not found\n', rawdatafilename);
                date = datetime(NaT);
            end

        otherwise
            error('Wrong value for Parameters.General.SampleDate');
    end
end

