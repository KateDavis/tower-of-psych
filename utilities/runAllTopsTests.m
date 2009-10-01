function topsTests
% run all test*.m in tops folders

clear all
clear classes
initialDir = pwd;

% visit all tops folders and run files named "test*.m"
[p, f] = fileparts(mfilename('fullpath'));
topsRoot = fullfile(p, '..');
try
    runTestsInDir(topsRoot)
catch testError
    cd(initialDir)
    rethrow(testError)
end
cd(initialDir)


function runTestsInDir(d)
cd(d)
wd = pwd;
directoryList = dir(wd);
for ii = 1:length(directoryList)
    fullPath = fullfile(wd, directoryList(ii).name);

    if directoryList(ii).isdir && isempty(regexp(directoryList(ii).name, '^\.'))
        % recursive: drill into subdirectory
        runTestsInDir(fullPath);
    elseif ~isempty(regexp(directoryList(ii).name, 'test\w+\.m$'))
        % base case: execute test funtion
        disp(sprintf('Testing: %s', fullPath))
        run(fullPath)
    end
end