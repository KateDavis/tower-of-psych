%% should not behave like a singleton
clear
clc
loop1 = topsFunctionLoop;
loop2 = topsFunctionLoop;
assert(loop1~=loop2, 'failed to get unique instances')

%% should add and preview functions
clear
clc
loop = topsFunctionLoop;
printMode = 'printouts';
printFunctions = {{@disp, 'display'}, {@sprintf, 'sprintf %d', 3}, {@warning, 'warn'}};
for ii = 1:length(printFunctions)
    loop.addFunctionToModeWithPrecedence(printFunctions{ii}, printMode, -ii);
end

mathMode = 'maths';
mathFunctions = {{@eye, 77}, {@mod, 6, 3}};
for ii = 1:length(mathFunctions)
    loop.addFunctionToModeWithPrecedence(mathFunctions{ii}, mathMode, -ii);
end

functionLoop = loop.getFunctionListForMode(printMode);
for ii = 1:length(functionLoop)
    assert(isequal(functionLoop{ii}, printFunctions{ii}), ...
        'failed to add and preview function')
end

functionLoop = loop.getFunctionListForMode(mathMode);
for ii = 1:length(functionLoop)
    assert(isequal(functionLoop{ii}, mathFunctions{ii}), ...
        'failed to add and preview function')
end

%% Should run functions in order of precedence
clear
clc
loop = topsFunctionLoop;
tic
loop.clockFcn = @toc;
mathMode = 'maths';
mathFunctions = {{@eye, 77}, {@mod, 6, 3}, {@rand}};
for ii = 1:length(mathFunctions)
    loop.addFunctionToModeWithPrecedence(mathFunctions{ii}, mathMode, -ii);
end

% run once through loop
[when, functionRun] = loop.runInModeForDuration(mathMode, 0);
for ii = 2:length(mathFunctions)
    assert(isequal(functionRun{ii}, mathFunctions{ii}), ...
        'wrong function run');
    assert(when(ii) >= when(ii-1), 'function run out of order');
end

%% Should run dummy functions in preview mode
clear
clc
loop = topsFunctionLoop;
tic
loop.clockFcn = @toc;
mathMode = 'maths';
mathFunctions = {{@eye, 77}, {@mod, 6, 3}, {@rand}};
for ii = 1:length(mathFunctions)
    loop.addFunctionToModeWithPrecedence(mathFunctions{ii}, mathMode, -ii);
end

% run once through loop
[when, functionRun] = loop.runInModeForDuration(mathMode, 0);
[previewWhen, previewRun] = loop.previewForMode(mathMode);

% should at least get same number of function calls
assert(isequal(size(when), size(previewWhen)), 'wrong number of preview timestamps')
assert(isequal(size(functionRun), size(previewRun)), 'wrong number of preview functions')