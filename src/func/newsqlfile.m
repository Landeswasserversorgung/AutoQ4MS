function filepath = newsqlfile(Parameters)
         while true
                ts = char(datetime('now','Format','yyyyMMdd_HHmmssSSS'));  
                filepath = fullfile(Parameters.path.program, 'src', 'database', ['sql_commands_', ts, '.sql']);
                
                if ~isfile(filepath)  
                    break;
                end
                pause(0.1);
         end
end

