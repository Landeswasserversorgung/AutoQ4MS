clc
clear

%% ===== Import Components =====
% Detect import options for Components.xlsx
optsComp = detectImportOptions('Components.xlsx');

% Set variable types explicitly
optsComp = setvartype(optsComp, 'ID', 'string');
optsComp = setvartype(optsComp, 'Name', 'string');
optsComp = setvartype(optsComp, 'Formula', 'string');
optsComp = setvartype(optsComp, 'Adduct_pos', 'string');
optsComp = setvartype(optsComp, 'Adduct_neg', 'string');
optsComp = setvartype(optsComp, 'RT', 'double');
optsComp = setvartype(optsComp, 'mz_pos', 'double');
optsComp = setvartype(optsComp, 'mz_neg', 'double');

% Read the table using the customized options
T = readtable('Components.xlsx', optsComp);

% Create dictionary (map) for Component objects
componentDict = containers.Map('KeyType', 'char', 'ValueType', 'any');

% Loop through rows and create Component objects
for i = 1:height(T)
    comp = Component(T(i,:));
    key = char(comp.ID);
    componentDict(key) = comp;
end


%% ===== Import Internal Standards =====
% Detect import options for InternalStandards.xlsx
optsIS = detectImportOptions('InternalStandards.xlsx');

% Set variable types explicitly
optsIS = setvartype(optsIS, 'ID', 'string');
optsIS = setvartype(optsIS, 'Name', 'string');
optsIS = setvartype(optsIS, 'IS_pos', 'logical');
optsIS = setvartype(optsIS, 'IS_neg', 'logical');
optsIS = setvartype(optsIS, 'Formula', 'string');
optsIS = setvartype(optsIS, 'Adduct_pos', 'string');
optsIS = setvartype(optsIS, 'Adduct_neg', 'string');
optsIS = setvartype(optsIS, 'RT', 'double');
optsIS = setvartype(optsIS, 'mz_pos', 'double');
optsIS = setvartype(optsIS, 'mz_neg', 'double');

% Add additional fields for Internal Standards, if present
if any(strcmp(optsIS.VariableNames, 'Concentration'))
    optsIS = setvartype(optsIS, 'Concentration', 'double');
end
if any(strcmp(optsIS.VariableNames, 'Unit'))
    optsIS = setvartype(optsIS, 'Unit', 'string');
end

% Read the internal standards table
T2 = readtable('InternalStandards.xlsx', optsIS);

% Create dictionary (map) for InternalStandard objects
ISdict = containers.Map('KeyType', 'char', 'ValueType', 'any');

% Loop through rows and create InternalStandard objects
for i = 1:height(T2)
    is = InternalStandard(T2(i,:));
    ISdict(char(is.ID)) = is;
end
