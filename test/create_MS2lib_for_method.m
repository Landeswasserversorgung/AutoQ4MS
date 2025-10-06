

methodPath = fullfile(Parameters.path.program,'data','Import', 'methods', 'TEST.mat'); 
load

loaded = load(methodPath, 'Parameters');
if ~isfield(loaded, 'Parameters')
    error('The file does not contain a variable named "Parameters".');
end
    Parameters = loaded.Parameters;

createMS2lib(Parameters)