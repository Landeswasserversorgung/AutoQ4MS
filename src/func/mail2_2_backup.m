% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Michael Mohr
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

function mail2_2(sender,pw,smtpServer, user,...
                  subject,...
                  message,...
                  attachment)
%MAIL2_2  Send emails via PowerShell using Send-MailMessage.
%
%   mail2_2(user, subject, message, attachment)
%   Sends an email to one or multiple recipients using PowerShell's
%   Send-MailMessage command and a predefined SMTP server.
%
%   Inputs:
%     sender     - Sender email adress
%     smtpServer - SMPT Server for email Template {' -SmtpServer url'} | Replace url by url of smtp server
%     user       - Recipient email address or array of addresses
%     subject    - Email subject (string or char)
%     message    - Cell array of message lines (will be converted to HTML)
%     attachment - Full path to file attachment
%
%   Notes:
%     - The email body is sent as HTML.
%     - Requires PowerShell and access to the SMTP server.
%
if strcmpi(smtpServer,'smtp.gmail.com')
    % --- Configuration ---
% Gmail bot
    % App Password
    if strcmpi(sender, "autoq4ms@gmail.com")
        gmail_app_password = 'oxjkcfmaowdiquxc'; 
        gmail_sender = 'autoq4ms@gmail.com'; 
        % Custom Gmail
    elseif contains(smtpServer,"gmail.com")
        gmail_app_password = pw;
        gmail_sender = sender; 
    end
    % Make sure Body is a Character-Vector
    M1 = char(strjoin(message, '<br />'));
    
    if ischar(user)
        user = string(user);
    end
    
    % Loop over all recipients
    for i = 1:size(user,2)
        
        % Create subject char
        current_subject = char(strcat(string(datetime(now,'ConvertFrom','datenum')), {' '}, subject));
        
        % Create attachment char
        safe_attachment = char(attachment);
        
        % Assemble Powershell command
        
        ps_command = [ ...
            'powershell -command "', ...
            '$pass = ConvertTo-SecureString ''', char(gmail_app_password), ''' -AsPlainText -Force; ', ...
            '$cred = New-Object System.Management.Automation.PSCredential (''', char(gmail_sender), ''', $pass); ', ...
            'Send-MailMessage ', ...
            '-BodyAsHtml ', ...
            '-From ''', char(gmail_sender), ''' ', ...
            '-To ''', char(user(i)), ''' ', ...
            '-Subject ''', current_subject, ''' ', ...
            '-Body ''', M1, ''' ', ...
            '-SmtpServer smtp.gmail.com ', ...
            '-Port 587 -UseSsl ', ...
            '-Credential $cred ', ...
            '-Attachments ''', safe_attachment, '''' ... 
            '"'];
    
        % Execute
        [status, cmdout] = system(ps_command);
        
        if status ~= 0
            disp(['Error sending mail to ', char(user(i))]);
            disp(cmdout);
        else
            disp(['Mail send to ', char(user(i))]);
        end
    end
else
    % Convert message cell array to HTML body
    M1 = strjoin(message, '<br />');
    if ischar(user)
        user = string(user);
    end
    % Loop over all recipients
    for i = 1:size(user,2)
    argument = strcat({'powershell -command "Send-MailMessage -BodyAsHtml -From '},...
                      {sender},...
                      {' -Subject '},{''''}, ...
                      strcat(string(datetime(now,'ConvertFrom','datenum')),{' '},subject),{''''},...
                      {' -To '},{''''},user(i),{''''},...
                      {' -Body '},{''''}, string(M1),{''''},...
                      {' -SmtpServer '},{''''},{smtpServer},...
                      {' -Attachments "'}, attachment, {'"'} ,'"');
%' -SmtpServer smtp.gmail.com
    system(char(join(argument)));
    end
end
end
