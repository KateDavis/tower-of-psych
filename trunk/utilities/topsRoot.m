% Get the absolute path to the Tower of Psych project root.
function topsPath = topsRoot()
utilitiesPath = fileparts(which('TowerOfPsych'));
topsPath = fullfile(utilitiesPath, '..');