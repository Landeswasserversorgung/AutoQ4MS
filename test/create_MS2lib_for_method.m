

methodPath = fullfile(Parameters.path.program,'data','Import', 'methods', 'std.mat'); 


loaded = load(methodPath, 'Parameters');
if ~isfield(loaded, 'Parameters')
    error('The file does not contain a variable named "Parameters".');
end
    Parameters = loaded.Parameters;

createMS2lib(Parameters)