function didPass = runAllTopsTests
%Invoke mtest's runtests() for all of the tops directories
%
%   didPass = runAllTopsTests
%
%   didPass is a boolean, whether all tests passed.  runAllTopsTests
%   returns as soon as it encounters a failure.
%
%   See also, runtests

% 2009 benjamin.heasly@gmail.com
%   Seattle, WA

% locate the tops code tree
[p, f] = fileparts(mfilename('fullpath'));
topsRoot = fullfile(p, '..');

initialDir = pwd;

disp(sprintf('RUNNING ALL TESTS FOR TOPS'));
tic;
didPass = runTestsInDir(topsRoot);
cd(initialDir)

if didPass
    disp(sprintf('\nTOPS PASSED ALL TESTS in %f seconds', toc));
end

function didPass = runTestsInDir(d)
cd(d);
absPath = pwd;
directoryList = dir(absPath);

disp(sprintf('\n\n%s', absPath));
didPass = runtests(absPath);

if didPass
    for ii = 1:length(directoryList)
        if directoryList(ii).isdir && isempty(regexp(directoryList(ii).name, '^\.'))
            % recursive: into subdirectories (ignore ".svn", etc)
            fullPath = fullfile(absPath, directoryList(ii).name);
            didPass = runTestsInDir(fullPath);
            if ~didPass
                break
            end
        end
    end
end