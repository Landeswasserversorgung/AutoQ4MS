function mode = MS2ModeFromMSdata(PrecursorMassList)
    % Entscheidet, ob DDA oder DIA anhand der Nachkommastellen der Precursor-Massen
    
    % Nur die ersten 10 Werte
    nCheck = min(10, length(PrecursorMassList));
    precursors = PrecursorMassList(1:nCheck);
    
    % Zähle, wie viele dieser Massen die 3. und 4. Nachkommastelle als 0 haben
    countDIApattern = 0;
    
    for i = 1:nCheck
        if isnan(precursors(i))
            continue;
        end
    
        % String mit 4 Nachkommastellen
        str = sprintf('%.4f', precursors(i));
    
        % Hol die 3. und 4. Nachkommastelle
        if length(str) >= 7 && strcmp(str(end-1:end), '00')
            countDIApattern = countDIApattern + 1;
        end
    end
    
    % Entscheidung: Wenn mindestens 8 der 10 Precursor-Massen diesem Muster entsprechen
    if countDIApattern >= 8
        mode = "DIA";
    else
        mode = "DDA";
    end
end

