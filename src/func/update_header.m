% ========== MTSLITE HEADER START ==========\n% Author: Linus Straehle
% Project: MTSlite
% License: MIT License
% Year: 2025
% ========== MTSLITE HEADER END ============\n\n\n\n\n\n\n\n\n\n\n\n\n
function update_header(rootDir)
    % UPDATE_HEADER Entfernt alte Header und fügt neue Marker-Header in allen .m-Dateien ein.
    %
    %   update_header(rootDir)
    %   rootDir: Pfad zum Projektordner.

    % === KONFIGURATION ===
    author  = 'Linus Straehle';
    project = 'MTSlite';
    license = 'MIT License';
    year    = datestr(now, 'yyyy');

    % Dateinamen für alternative Header
    alt1 = {'special1.m', 'tool1.m'};
    alt2 = {'special2.m'};
    alt3 = {'special3.m'};

    % === Header-Templates erzeugen ===
    stdHeader  = generateHeader( author, project, license, year );
    altHeader1 = generateAltHeader(author, 'Spezialmodul 1');
    altHeader2 = generateAltHeader(author, 'Toolset 2');
    altHeader3 = generateAltHeader(author, 'Speziell 3');

    % === Alle .m-Dateien finden ===
    files = getAllMFiles(rootDir);

    % === Header in jeder Datei updaten ===
    for k = 1:numel(files)
        fp = files{k};
        [~, name, ext] = fileparts(fp);
        fname = [name, ext];

        if ismember(fname, alt1)
            hdr = altHeader1;
        elseif ismember(fname, alt2)
            hdr = altHeader2;
        elseif ismember(fname, alt3)
            hdr = altHeader3;
        else
            hdr = stdHeader;
        end

        insertOrUpdateHeader(fp, hdr);
    end
end

%% ---- Hilfsfunktionen ----

function header = generateHeader(author, project, license, year)
    % GENERATEHEADER Erstellt den Standard-Header mit Markern.
    startM = '';
    header = [startM, body, endM, '\n'];
end

function header = generateAltHeader(author, note)
    % GENERATEALTHEADER Erstellt einen alternativen Header mit Anmerkung.
    startM = '';
    header = [startM, body, endM, '\n'];
end

function files = getAllMFiles(folder)
    % GETALLMFILES Listet alle .m-Dateien rekursiv auf.
    info = dir(fullfile(folder, '**', '*.m'));
    files = fullfile({info.folder}, {info.name});
end

function insertOrUpdateHeader(filePath, newHeader)
    % INSERTORUPDATEHEADER Löscht alte Header-Blöcke und fügt newHeader ein.

    % Marker genauso wie in generateHeader:
    startM = '';

    % 1) Einlesen
    fid = fopen(filePath, 'r');
    if fid < 0
        warning('Kann nicht öffnen: %s', filePath);
        return;
    end
    txt = fread(fid, '*char')';
    fclose(fid);

    % 2) Alle existierenden Header-Blöcke entfernen
    idx = strfind(txt, startM);
    while ~isempty(idx)
        s = idx(1);
        eList = strfind(txt, endM);
        ePos = eList(find(eList > s,1,'first'));
        if isempty(ePos)
            break;
        end
        e = ePos + length(endM) - 1;
        txt = [txt(1:s-1), txt(e+1:end)];
        idx = strfind(txt, startM);
    end

    % 3) Neuen Header voranstellen
    updated = [newHeader, txt];

    % 4) Alle abschließenden '\n' entfernen
    while ~isempty(updated) && updated(end) == newline
        updated(end) = [];
    end

    % 5) Speichern
    fid = fopen(filePath, 'w');
    fwrite(fid, updated);
    fclose(fid);
end
