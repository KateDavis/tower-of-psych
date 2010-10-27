
function sm = stateMachineSandbox

sm = topsStateMachine;
sm.name = 'sandbox machine';

% each accepts state information as first input
%   apply to all states
sm.beginFevalable = {@beginning};
sm.transitionFevalable = {@transitioning};
sm.endFevalable = {@ending};

% each accepts only user inputs (if any)
%   may be unique to each state
%   input may return a state name
entry = {@disp, ' entering state'};
input = {@getStateInput};
exit = {@disp, ' exiting state'};

% similar to cell array definition from dotsx
%   but explicit about field/column names
%   allows shuffling and omission of fields/columns
statesInfo = { ...
    'name',     'timeout',  'next',     'entry', 'input',   'exit'; ...
    'beginning',0,          'middle',   entry,   {},        exit; ...
    'middle',   0.1,        'end',      {},      input,     {}; ...
    'end',      0,          '',         entry,   {},        exit; ...
    };
sm.addMultipleStates(statesInfo);

% alternative specification method
%   states can be added in bunches, one at a time, etc.
surp.name = 'surprise!';
surp.timeout = 0;
surp.next = '';
surp.entry = entry;
surp.input = {};
surp.exit = exit;
sm.addState(surp);

% traverse from topmost state to an end
sm.run;

% % same as run(), but amenable to concurrency
% sm.begin;
% while isempty(sm.endTime)
%     sm.runBriefly;
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