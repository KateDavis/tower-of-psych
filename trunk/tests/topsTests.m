function topsTests
% run all test*.m in this folder

[path, file] = fileparts(mfilename('fullpath'));
d = dir(path);
for ii = 1:length(d)
    if ~isempty(regexp(d(ii).name, 'test\w+\.m$'))
        run(fullfile(path, d(ii).name))
    end
end