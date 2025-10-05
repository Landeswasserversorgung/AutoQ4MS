function str = convertUmlauts(str)
    % Konvertiert deutsche Umlaute in ihre entsprechenden Umschreibungen
    str = strrep(str, 'ä', 'ae');
    str = strrep(str, 'Ä', 'Ae');
    str = strrep(str, 'ö', 'oe');
    str = strrep(str, 'Ö', 'Oe');
    str = strrep(str, 'ü', 'ue');
    str = strrep(str, 'Ü', 'Ue');
    str = strrep(str, 'ß', 'ss');
end


