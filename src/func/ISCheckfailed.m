function Sample = ISCheckfailed(DeviceControlCheck, WarningMassage, DeviceControlhtmlImageTag, Sample, Parameters)
%ISCHECKFAILED  Update IS check status and trigger warning email/logging on failure.
%
%   Sample = ISCheckfailed(DeviceControlCheck, WarningMassage, DeviceControlhtmlImageTag, Sample, Parameters)
%   If the device control check passes, the sample is marked as ISCheck = 1
%   and the database entry is updated accordingly. If it fails, the sample is
%   marked as ISCheck = 0, the failure is logged to the database, and an
%   email (HTML) is generated and sent (with a fallback mail function).
%
%   Inputs:
%     DeviceControlCheck        - Logical flag indicating whether device control passed
%     WarningMassage            - Warning message text to include in the email (string/char)
%     DeviceControlhtmlImageTag - HTML snippet (e.g., <img ...>) to include in the email
%     Sample                    - Sample struct (expects fields: ID, MSMode, timestamp_of_measurement, ISCheck)
%     Parameters                - Project parameters struct (database, mail, paths)
%
%   Output:
%     Sample - Updated sample struct with Sample.ISCheck set to 1 or 0

    % Check if device control passed
    if DeviceControlCheck
        Sample.ISCheck = 1;

        % Set ISCheck = true in database
        filepath = newsqlfile(Parameters);
        SQLfileID = fopen(filepath, 'w');
        fprintf(SQLfileID, 'UPDATE "%s"."SampleMaster"\n', Parameters.database.schema);
        fprintf(SQLfileID, 'SET "ISCheck" = true\n');
        fprintf(SQLfileID, 'WHERE "SampleID" = ''%s''\n', Sample.ID);
        runsqlfile(filepath, Parameters);

        disp('IS check passed.');

    else
        % IS check failed
        Sample.ISCheck = 0;

        WarningPlusDb(sprintf('%s IS check failed', Sample.ID), Parameters, 'IS-Check');

        % Try to send a warning email
        try
            while true
                ts = char(datetime('now', 'Format', 'yyyyMMdd_HHmmssSSS'));
                emailfilepath = fullfile(Parameters.path.program, 'src', 'mail', ['email_', ts, '.html']);

                if ~isfile(emailfilepath)
                    break;
                end
                pause(0.1);
            end

            copyfile('..\src\mail\emailstartTemplate.html', emailfilepath);

            fileIDISMail = fopen(emailfilepath, 'a');
            fprintf(fileIDISMail, '<p>Sample ID: %s </p>', Sample.ID);
            fprintf(fileIDISMail, 'Date: %s', char(datetime(Sample.timestamp_of_measurement, 'Format', 'yyyyMMdd_HHmmssSSS')));
            fprintf(fileIDISMail, '<p>MS-mode: %s </p>', Sample.MSMode);
            fprintf(fileIDISMail, '<h3 class="code-yellow">Sample failed IS check</h3>\n');
            fprintf(fileIDISMail, '<p> %s </p>\n', WarningMassage);
            fprintf(fileIDISMail, DeviceControlhtmlImageTag);
            fprintf(fileIDISMail, '<div class="footer">This e-mail was created automatically.</div></body></html>');
            fclose(fileIDISMail);

            if Parameters.Mail.On
                % mailing function
                mail2_2(Parameters.Mail.Sender, Parameters.Mail.SmtpServer, Parameters.Mail.Receiver, "Sample IS-Check failed", "Sample IS-Check failed", emailfilepath);
            end

            delete(emailfilepath);

        catch
            WarningPlusDb('Error in sending IS check failed mail.', Parameters, 'Processing Setting');
        end

        % Set ISCheck = false in database
        filepath = newsqlfile(Parameters);
        SQLfileID = fopen(filepath, 'w');
        fprintf(SQLfileID, 'UPDATE "%s"."SampleMaster"\n', Parameters.database.schema);
        fprintf(SQLfileID, 'SET "ISCheck" = false\n');
        fprintf(SQLfileID, 'WHERE "SampleID" = ''%s''\n', Sample.ID);
        runsqlfile(filepath, Parameters);
    end
end


