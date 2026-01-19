% ========================= AutoQ4MS HEADER START =========================
% Copyright © 2026 Zweckverband Landeswasserversorgung
% Author   : Linus Straehle
% Project  : AutoQ4MS
% License  : % License: GNU General Public License v3.0 (GPL-3.0) or later.
%          See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for details.
% ========================== AutoQ4MS HEADER END ==========================

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
