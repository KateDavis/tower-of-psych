function sm = stateMachineSandbox

sm = topsStateMachine;

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

% similar appearance to cell array definition from dotsx
%   - function call does internal accounting
%   - but I'm not married to this syntax
%   - I'd love to find a syntax that speaks for itself
%       - i.e, doesn't require user to memorize the order 
%           and meanings of arguments or cell columns
%       - verbose function name?  clutter?  accepts cell?
%       - field names included in first row of cell array?
%           - dynamic, potentially less code maintainance
sm.addState('beginning',    0,	'middle',   entryFcn, {}, exitFcn);
sm.addState('middle',       .1,	'end',      {}, inputFcn, {});
sm.addState('end',          0,  '',         entryFcn, {}, exitFcn);
sm.addState('surprise!',    0,  '',         entryFcn, {}, exitFcn);

% traverse from topmost state to an end
sm.run;

% same as run(), but amenable to concurrency
sm.begin;
while isempty(sm.endTime)
    sm.step;
end

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