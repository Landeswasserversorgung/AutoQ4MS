setup()
rootDir ='/Users/linusstrahle/Library/Mobile Documents/com~apple~CloudDocs/LW-Paper';

update_header(rootDir)
function update_header(rootDir)
    % UPDATE_HEADER Entfernt alte Marker-Header und fügt neue Header in allen .m-Dateien ein.
    %
    %   update_header(rootDir)
    %   rootDir: Pfad zum Projektordner.

    % === KONFIGURATION ===
    author  = 'Linus Straehle';
    project = 'AutoQMS';
    license = 'MIT License';
    year    = datestr(now, 'yyyy');
    nl      = newline;

    % === HEADER-TEXTE als echte Mehrzeilen-Strings ===
    stdHeader = [ ...
        '% ========== AUTOQMS HEADER START ==========' nl ...
        '% Author: '  author nl ...
        '% Project: ' project nl ...
        '% License: ' license nl ...
        '% Year: '    year    nl ...
        '% ========== AUTOQMS HEADER END ============' nl nl ];

    altHeader1 = [ ...
        '% ========== AUTOQMS HEADER START ==========' nl ...
        '% Author: Michael Mohr' nl ...
        '% Project: ' project nl ...
        '% License: ' license nl ...
        '% Year: '    year    nl ...
        '% ========== AUTOQMS HEADER END ============' nl nl ];

    altHeader2 = [ ...
    '% ========== AUTOQMS HEADER START ==========' nl ...
    '% Original Function : zmat' nl ...
    '% Original Author   : Qianqian Fang' nl ...
    '% Created           : 04/30/2019' nl ...
    '% Source Toolbox    : ZMAT (https://github.com/fangq/zmat)' nl ...
    '% Upstream URL      : https://github.com/AdrianHaun/AriumMS/blob/stable/sourcecode/zmat.m' nl ...
    '% Note              : Third-party code — not part of the AutoQMS core' nl ...
    '% ========== AUTOQMS HEADER END ============' nl nl ];

altHeader3 = [ ...
    '% ========== AUTOQMS HEADER START ==========' nl ...
    '% Original Function : readmzXML.m' nl ...
    '% Original Author   : Adrian Haun' nl ...
    '% Source Repository : AriumMS (stable branch)' nl ...
    '% Source URL        : https://github.com/AdrianHaun/AriumMS/blob/stable/sourcecode/readmzXML.m' nl ...
    '% License           : BSD 3-Clause License (Copyright © 2022 Adrian Haun)' nl ...
    '% Note              : Third-party code — not part of the AutoQMS core modifed by the AutoQMS authors' nl ...
    '% ========== AUTOQMS HEADER END ============' nl nl ];


    % Dateinamen für alternative Header definieren
    alt1 = {'special1.m', 'tool1.m'};
    alt2 = {'zmat.m'};
    alt3 = {'readmzXML.m','untitled2.m'};

    % === .m-Dateien sammeln ===
    files = getAllMFiles(rootDir);

    % === Header-Update durchführen ===
    for k = 1:numel(files)
        fp = files{k};
        [~, name, ext] = fileparts(fp);
        fname = [name, ext];

        % Skript-Datei selbst überspringen
        if strcmp(fname, 'header.m')
            continue;
        end

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

%% Hilfsfunktionen

function files = getAllMFiles(folder)
    % GETALLMFILES Listet rekursiv alle .m-Dateien auf
    info  = dir(fullfile(folder, '**', '*.m'));
    files = fullfile({info.folder}, {info.name});
end

function insertOrUpdateHeader(filePath, newHeader)
    % INSERTORUPDATEHEADER Entfernt alte Header-Blöcke und fügt newHeader ein,
    % entfernt außerdem abschließende Newlines.

    startM = '% ========== AUTOQMS HEADER START ==========' ;
    endM   = '% ========== AUTOQMS HEADER END ============' ;

    % 1) Datei einlesen
    fid = fopen(filePath, 'r');
    if fid < 0
        warning('Kann nicht öffnen: %s', filePath);
        return;
    end
    txt = fread(fid, '*char')';
    fclose(fid);

    % 2) Alte Header-Blöcke entfernen
    idx = strfind(txt, startM);
    while ~isempty(idx)
        s     = idx(1);
        eList = strfind(txt, endM);
        ePos  = eList(find(eList > s, 1, 'first'));
        if isempty(ePos), break; end
        e     = ePos + length(endM) - 1;
        txt   = [txt(1:s-1), txt(e+1:end)];
        idx   = strfind(txt, startM);
    end

    % 3) Neuen Header voranstellen
    updated = [newHeader, txt];

    % 4) Alle abschließenden '\n' entfernen
    updated = regexprep(updated, '[\r\n]+$', '');

    % 5) In Datei zurückschreiben
    fid = fopen(filePath, 'w');
    fwrite(fid, updated);
    fclose(fid);
end
