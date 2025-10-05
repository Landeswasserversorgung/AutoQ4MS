function Sample = ISCheckfailed(DeviceControlCheck,WarningMassage, DeviceControlhtmlImageTag, Sample,Parameters)
%	This Function perfom a Sample IS Check. If one the Sample IS Check or the
%	DeviceControlCheck is failed a Warning mail were send 
%   Detailed explanation goes here

     % Check if the DeviceControlCheck and SampleISCheck passed
     if  DeviceControlCheck
         Sample.ISCheck = 1;
         % Change IS True in DB auf IS False

         filepath = newsqlfile(Parameters);
         SQLfileID = fopen(filepath, 'w');
         fprintf(SQLfileID, 'UPDATE "%s"."SampleMaster"\n', Parameters.database.schema);
         fprintf(SQLfileID, 'SET "ISCheck" = true\n');
         fprintf(SQLfileID, 'WHERE "SampleID" = ''%s''\n', Sample.ID);
         runsqlfile(filepath, Parameters); 
         disp('IS check passed.');
     else
         % IS Check is failed 
         Sample.ISCheck = 0;
         WarningPlusDb(sprintf('%s IS check failed',Sample.ID),Parameters, 'IS-Check');
         % try to send a warning Mail
         try
            while true
                ts = char(datetime('now','Format','yyyyMMdd_HHmmssSSS'));  
                emailfilepath = fullfile(Parameters.path.program, 'src', 'mail', ['email_', ts, '.html']);
                
                if ~isfile(emailfilepath)  
                    break;
                end
                pause(0.1);
            end 
            copyfile('..\src\mail\emailstartTemplate.html', emailfilepath);
            fileIDISMail = fopen(emailfilepath, 'a');
            fprintf(fileIDISMail,'<p>Sample ID: %s </p>', Sample.ID);
            fprintf(fileIDISMail,'Date: %s', char(datetime(Sample.timestamp_of_measurement,'Format','yyyyMMdd_HHmmssSSS')));
            fprintf(fileIDISMail,'<p>MS-mode: %s </p>', Sample.MSMode );
            fprintf(fileIDISMail, '<h3 class="code-yellow">Sample failed IS check</h3>\n');
            fprintf(fileIDISMail, '<p> %s </p>\n', WarningMassage);
            fprintf(fileIDISMail, DeviceControlhtmlImageTag);
            fprintf(fileIDISMail, '<div class="footer">This e-mail was created automatically.</div></body></html>');
            fclose(fileIDISMail);
            if Parameters.Mail.On
            try
                sendmail( Parameters.Mail.Sender ,Parameters.Mail.Receiver, 'Sample IS-Check failed',emailfilepath);
            catch
                mail2_2(Parameters.Mail.Receiver,"Sample IS-Check failed","Sample IS-Check failed",emailfilepath); % Backup mailing function           
            end
            end
            delete(emailfilepath);
         catch
            WarningPlusDb('Error in sending IS check failed mail.',Parameters, 'Processing Setting');
         end
        % Change IS True in DB auf IS False
        filepath = newsqlfile(Parameters);
        SQLfileID = fopen(filepath, 'w');
        fprintf(SQLfileID, 'UPDATE "%s"."SampleMaster"\n', Parameters.database.schema);
        fprintf(SQLfileID, 'SET "ISCheck" = false\n');
        fprintf(SQLfileID, 'WHERE "SampleID" = ''%s''\n', Sample.ID);
        runsqlfile(filepath,Parameters); 
     end
end

