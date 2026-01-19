clear
clc
load('data\Import\methods\Parameters.mat');
% new meth
% meth1 = method(Parameters);
%%
% Processing 
%methodPath = fullfile(Parameters.path.program,'data','Import', 'methods', ['anr125_60d_p005_bf_override_ischeck_bothways', '.mat']);
methodPath = fullfile(Parameters.path.program,'data','Import', 'methods', 'test07.mat');
processing(methodPath); 

