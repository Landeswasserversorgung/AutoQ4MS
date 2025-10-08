function run_method(methodFile)
%RUN_METHOD  setup -> processing, eigenes Log-Handling intern
%   - Nur ein Argument: methodFile (Pfad zur .mat)
%   - Logdatei wird bei Erfolg gelöscht, bei Fehler behalten

    % --- Pfade & Log vorbereiten ---
    thisDir = fileparts(mfilename('fullpath'));
    if ~isempty(thisDir), cd(thisDir); end
    addpath(genpath(thisDir));

    if ~isfile(methodFile)
        error('Method file not found: %s', methodFile);
    end

    [~, methodName] = fileparts(methodFile);

    % sicherstellen, dass thisDir existiert (Ordner von run_method.m = ...\src)
    if ~exist('thisDir','var') || isempty(thisDir)
        thisDir = fileparts(mfilename('fullpath'));
    end
    
    % eine Ebene hoch (Projektwurzel) und dort "logs"
    projRoot = fileparts(thisDir);           % ...\AutoQ_paper
    logDir   = fullfile(projRoot, 'logs');   % ...\AutoQ_paper\logs
    if ~isfolder(logDir), mkdir(logDir); end
    
    ts      = datestr(now, 'yyyymmdd-HHMM');
    logPath = fullfile(logDir, sprintf('%s_%s.log', methodName, ts));


    diary(logPath); diary on
    c = onCleanup(@() diary('off')); %#ok<NASGU>

    try
        logline('=== RUN_METHOD START ===');
        logline(sprintf('processing located at: %s', which('processing')));

        % --- optionales setup ---
        if exist('setup','file')
            logline('BEGIN setup()');
            setup();
            logline('END setup()');
            clearvars -except methodFile logPath c
        else
            logline('setup() not found — skipping.');
        end
f
        % --- processing ---
        logline(sprintf('BEGIN processing(''%s'')', methodFile));
        processing(methodFile);
        logline('END processing()');
        logline('SUCCESS: processing finished');

        % --- Log bei Erfolg löschen ---
        diary off
        try, delete(logPath); catch, end
        maybeExit(0);

    catch e
        logline('FAIL: exception caught');
        fprintf(2, '%s\n', getReport(e,'extended','hyperlinks','off'));
        diary off
        fprintf('[AutoQ4MS] Log kept at: %s\n', logPath);
        maybeExit(1);
        rethrow(e);  % im Desktop den Fehler sichtbar machen
    end
end

function logline(msg)
    fprintf('[AutoQ4MS] %s | %s\n', datestr(now,31), msg);
end

function maybeExit(code)
    % Beendet MATLAB nur im -batch/-nodesktop Betrieb
    if ~usejava('desktop')
        exit(code);
    end
end

