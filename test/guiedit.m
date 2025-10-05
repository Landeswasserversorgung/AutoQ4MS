clear
clc

load('data\Import\methods\Parameters.mat');
updatedParameters = editParametersGUI(Parameters);


% % Zeitintervall setzen
% % nowDate = datetime('now');
% % startDate = nowDate - days(365);  % 1 Jahr zurück
% % 
% % Dummy ISdic (kannst du anpassen)
% % ISdic = containers.Map(); % Leerer dictionary – wenn du willst, kann ich dir einen Mock dafür machen
% % Beispiel: ISdic('IS1') = struct('IS_pos', true, 'IS_neg', true);

% Figure mit drei Achsen für RT, MA, Intensity
% f = figure('Position', [100 100 1300 800], 'Name', 'Test DeviceControl');
% ax1 = subplot(3,1,1);
% ax2 = subplot(3,1,2);
% ax3 = subplot(3,1,3);
% 
% % Struct mit den Achsen zusammenstellen
% axesStruct = struct('RT', ax1, 'MA', ax2, 'Intensity', ax3);
% 
% % Aufruf der Funktion zum Testen
% generateISPlots('+', startDate, nowDate, axesStruct, Parameters);

