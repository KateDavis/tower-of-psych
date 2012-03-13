% Get the absolute path to the Tower of Psych project root.
%
% @ingroup utilities
function topsPath = topsRoot()
utilitiesPath = fileparts(which('TowerOfPsych'));
topsPath = fullfile(utilitiesPath, '..');