function testTopsFunctionLoop

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
mathMode = 'maths';
mathFunctions = {{@eye, 77}, {@mod, 6, 3}, {@rand}};
for ii = 1:length(mathFunctions)
    loop.addFunctionToModeWithPrecedence(mathFunctions{ii}, mathMode, -ii);
end

% run once through loop
loop.runInModeForDuration(mathMode, 0);
functionList = loop.getFunctionListForMode(mathMode);
for ii = 1:length(mathFunctions)
    assert(isequal(functionList{ii}, mathFunctions{ii}), ...
        'wrong function in list');
end

%% Should run dummy functions in preview mode
clear
clc
loop = topsFunctionLoop;
mathMode = 'maths';
mathFunctions = {{@eye, 77}, {@mod, 6, 3}, {@rand}};
for ii = 1:length(mathFunctions)
    loop.addFunctionToModeWithPrecedence(mathFunctions{ii}, mathMode, -ii);
end

% run once through loop
loop.previewForMode(mathMode);

%% should post event when props change
clear
clc
global eventCount
eventCount = 0;
loop = topsFunctionLoop;
loop.addlistener('clockFcn', 'PostSet', @hearEvent);
for ii = 1:10
    loop.clockFcn = @now;
end
assert(eventCount==ii, 'heard wrong number of set events')
clear global eventCount

function hearEvent(metaProp, event)
global eventCount
eventCount = eventCount + 1;