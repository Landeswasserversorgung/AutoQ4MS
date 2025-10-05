function MS2Mode = getMS2Mode(Filename)
%	This Function gets the MS2 Mode DDA or DIA from the Filename
%   Linus Straehle 2024-11-07

    if contains(Filename, 'DDA')
        MS2Mode = 'DDA';
    elseif contains(Filename, 'DIA')
        MS2Mode = 'DIA';
    else
        error('unkonwn MS2 Mode');
    end
    
    % If files are not named correct turn this on
    % MS2Mode = 'DDA';
end

