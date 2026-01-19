% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

% ========== MTSLITE HEADER START ==========
% Author: Linus Straehle
% Project: MTSlite
% License: MIT License
% Year: 2025
% ========== MTSLITE HEADER END ============

function update_header(rootDir)
%UPDATE_HEADER  Remove old headers and insert a new marker-based header into all .m files.
%
%   update_header(rootDir)
%   rootDir: Path to the project root folder.

    %% Configuration
    author  = 'Linus Straehle';
    project = 'MTSlite';
    license = 'MIT License';
    year    = datestr(now, 'yyyy');

    % Filenames for alternative headers
    alt1 = {'special1.m', 'tool1.m'};
    alt2 = {'special2.m'};
    alt3 = {'special3.m'};

    %% Build header templates
    stdHeader  = generateHeader(author, project, license, year);
    altHeader1 = generateAltHeader(author, 'Spezialmodul 1');
    altHeader2 = generateAltHeader(author, 'Toolset 2');
    altHeader3 = generateAltHeader(author, 'Speziell 3');

    %% Find all .m files recursively
    files = getAllMFiles(rootDir);

    %% Update header for each file
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

%% ---- Helper functions ----

function header = generateHeader(author, project, license, year)
%GENERATEHEADER  Create the default marker header.
    startM = '';
    header = [startM, body, endM, '\n'];
end

function header = generateAltHeader(author, note)
%GENERATEALTHEADER  Create an alternative marker header with a note.
    startM = '';
    header = [startM, body, endM, '\n'];
end

function files = getAllMFiles(folder)
%GETALLMFILES  Recursively list all .m files under a folder.
    info = dir(fullfile(folder, '**', '*.m'));
    files = fullfile({info.folder}, {info.name});
end

function insertOrUpdateHeader(filePath, newHeader)
%INSERTORUPDATEHEADER  Remove existing header blocks and prepend newHeader.

    % Marker must match the one used in generateHeader:
    startM = '';

    % 1) Read file contents
    fid = fopen(filePath, 'r');
    if fid < 0
        warning('Cannot open file: %s', filePath);
        return;
    end
    txt = fread(fid, '*char')';
    fclose(fid);

    % 2) Remove all existing header blocks
    idx = strfind(txt, startM);
    while ~isempty(idx)
        s = idx(1);
        eList = strfind(txt, endM);
        ePos = eList(find(eList > s, 1, 'first'));
        if isempty(ePos)
            break;
        end
        e = ePos + length(endM) - 1;
        txt = [txt(1:s-1), txt(e+1:end)];
        idx = strfind(txt, startM);
    end

    % 3) Prepend new header
    updated = [newHeader, txt];

    % 4) Remove trailing newline characters
    while ~isempty(updated) && updated(end) == newline
        updated(end) = [];
    end

    % 5) Write back to disk
    fid = fopen(filePath, 'w');
    fwrite(fid, updated);
    fclose(fid);
end
