
% === Test-Script for 'method' class ===
clear; clc;
thisFile = mfilename('fullpath');
[thisPath, ~, ~] = fileparts(thisFile);
cd(thisPath);

% --- Step 1: Load base Parameters ---
% You should already have this file in your project
load('../data/Import/methods/Parameters.mat');  % adjust if your path differs

% --- Step 2: Create a new method (with user input) ---
disp('--- Creating new method ---');
m = method(Parameters);  % prompts for method name

% --- Step 3: Run the method manually via .bat file ---
disp('--- Running method manually (opens MATLAB GUI) ---');
m.run();
pause(30);

% --- Step 4: Turn task ON (creates Windows Task) ---
disp('--- Turning task ON ---');
m = m.turnTaskon();

% --- Step 5: Turn task OFF (deletes Windows Task) ---
disp('--- Turning task OFF ---');
m = m.turnTaskoff();

% --- Step 6: Save & reload method from file ---
disp('--- Saving and reloading method ---');
savedName = m.Name;
clear m

% Load method from file
disp(['--- Loading method "', savedName, '" from file ---']);
m2 = method(Parameters, savedName);

% --- Step 7: Delete method (task + files) ---
disp('--- Deleting method ---');
m2.delmethod();

disp('✅ All tests completed.');

%%
m = method(Parameters);  % prompts for method name
m = method(Parameters);  % prompts for method name
m = method(Parameters);  % prompts for method name
