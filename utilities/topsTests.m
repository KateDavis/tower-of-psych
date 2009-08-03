function topsTests
% run all test*.m in this folder

clear classes

[path, file] = fileparts(mfilename('fullpath'));

directoryList = dir(path);
for ii = 1:length(directoryList)
    if ~isempty(regexp(directoryList(ii).name, 'test\w+\.m$'))
        run(fullfile(path, directoryList(ii).name))
    end
end