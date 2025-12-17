function mail2_2(user, subject, message, attachment)
%MAIL2_2  Send emails via PowerShell using Send-MailMessage.
%
%   mail2_2(user, subject, message, attachment)
%   Sends an email to one or multiple recipients using PowerShell's
%   Send-MailMessage command and a predefined SMTP server.
%
%   Inputs:
%     user       - Recipient email address or array of addresses
%     subject    - Email subject (string or char)
%     message    - Cell array of message lines (will be converted to HTML)
%     attachment - Full path to file attachment
%
%   Notes:
%     - The email body is sent as HTML.
%     - The sender address is fixed to dummy.d@lw-online.de.
%     - Requires PowerShell and access to the SMTP server.
%

    % Convert message cell array to HTML body
    M1 = strjoin(message, '<br />');

    % Loop over all recipients
    for i = 1:size(user, 2)

        argument = strcat( ...
            {'powershell -command "Send-MailMessage -BodyAsHtml -From '}, ...
            {'dummy.d@lw-online.de'}, ...
            {' -Subject '}, {''''}, ...
            strcat(string(datetime(now,'ConvertFrom','datenum')), {' '}, subject), {''''}, ...
            {' -To '}, {''''}, user(i), {''''}, ...
            {' -Body '}, {''''}, string(M1), {''''}, ...
            {' -SmtpServer Mail.lw-online.de'}, ...
            {' -Attachments "'}, attachment, {'"'} , '"' ...
        );

        system(char(join(argument)));
    end
end

