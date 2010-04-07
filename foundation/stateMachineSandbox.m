function sm = stateMachineSandbox

sm = topsStateMachine;
sm.name = 'sandbox machine';

% each accepts state information as first input
%   apply to all states
sm.beginFcn = {@beginning};
sm.transitionFcn = {@transitioning};
sm.endFcn = {@ending};

% each accepts only user inputs (if any)
%   may be unique to each state
%   inputFcn may return a state name
entryFcn = {@disp, ' entering state'};
inputFcn = {@getStateInput};
exitFcn = {@disp, ' exiting state'};

% similar to cell array definition from dotsx
%   but explicit about field/column names
%   allows shuffling and omission of fields/columns
statesInfo = { ...
    'name',     'timeout',  'next',     'entryFcn', 'inputFcn', 'exitFcn'; ...
    'beginning',0,          'middle',   entryFcn,   {},         exitFcn; ...
    'middle',   0.1,        'end',      {},         inputFcn,	{}; ...
    'end',      0,          '',         entryFcn,   {},         exitFcn; ...
    };
sm.addMultipleStates(statesInfo);

% alternative specification method
%   states can be added in bunches, one at a time, etc.
surp.name = 'surprise!';
surp.timeout = 0;
surp.next = '';
surp.entryFcn = entryFcn;
surp.inputFcn = {};
surp.exitFcn = exitFcn;
sm.addState(surp);

% traverse from topmost state to an end
sm.run;

% % same as run(), but amenable to concurrency
% sm.begin;
% while isempty(sm.endTime)
%     sm.step;
% end

function beginning(firstState)
disp(sprintf('beginning with %s', firstState.name));

function transitioning(transitionStates)
disp(sprintf('transitioning from %s to %s', ...
    transitionStates(1).name, transitionStates(2).name));

function ending(lastState)
disp(sprintf('ended with %s', lastState.name));

function stateName = getStateInput
disp (' ---')
stateName = input(' which state next? ', 's');
disp (' ---')