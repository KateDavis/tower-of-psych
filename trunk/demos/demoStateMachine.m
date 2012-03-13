% Demonstrate some key behaviors of the topsStateMachine class.
% @details
% Returns a the topsStateMachine object used in the demo.  The gui() method
% of the object will let you visualize its state data.
% @code
% sm = demoStateMachine;
% ...
% sm.gui
% @endcode
%
% @ingroup demos
function sm = demoStateMachine

% Create a state machine object and give it a name
sm = topsStateMachine;
sm.name = 'sandbox machine';

% chose functions to call before and after doing state traversal
sm.startFevalable = {@disp, 'starting state traversal'};
sm.finishFevalable = {@disp, 'finished state traversal'};

% choose a function to call when transitioning between states
%   should expect a 1x2 struct array of "to" and "from" state data
sm.transitionFevalable = {@transitioning};

% define some functions to be called when entering or exiting a state
entry = {@disp, ' entering state'};
exit = {@disp, ' exiting state'};

% define a function which returns a value from user input
%   if the returned value is a state name, it will cause a transitions to
%   the named state.
input = {@getStateInput};

% define four states with cell array syntax.
%   Each row specifies a state, each column specifies values for a property
%   of the states.
statesInfo = { ...
    'name',     'timeout',  'next',     'entry', 'input',   'exit'; ...
    'beginning',0,          'middle',   entry,   {},        exit; ...
    'middle',   0.1,        'end',      {},      input,     {}; ...
    'end',      0,          '',         entry,   {},        exit; ...
    };
sm.addMultipleStates(statesInfo);

% define a fifth state with struct syntax.  The struct specifies a single
% state.  The struct fields specify property valus for the state.
surp.name = 'surprise!';
surp.timeout = 0;
surp.next = '';
surp.entry = entry;
surp.input = {};
surp.exit = exit;
sm.addState(surp);

% traverse the five states, or a subset of them.
sm.run;

% An arbitrary function to call between states.
function transitioning(transitionStates)
disp(sprintf('transitioning from %s to %s', ...
    transitionStates(1).name, transitionStates(2).name));

% A function to get user input for one state.
function stateName = getStateInput
disp (' ---')
stateName = input(' which state next? ', 's');
disp (' ---')