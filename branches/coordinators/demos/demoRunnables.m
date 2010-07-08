% Demonstrate some key behaviors of topsRunnable and topsSteppable objects

%% First, define some arbitrary behaviors in "fevalable" cell arrays
% Using feval() for each of these cell arrays will print a message to the
% command window.
clear
clc

hello = {@disp, 'Hello.'};
goodbye = {@disp, 'Goodbye.'};
pardon = {@disp, 'Pardon me?'};

howdy = {@disp, '  How do you do?'};
fine = {@disp, '  Fine, thanks.'};

%% topsCallList
% A "call list" can call a bunch of functions as a batch.  For example:
calls = topsCallList;
calls.addCall(hello);
calls.addCall(pardon);
calls.addCall(goodbye);

clc
calls.run;

%% topsStateMachine
% A "state machine" can combine behaviors in more complex ways, for example
% by adding timing.
machine = topsStateMachine;
stateList = { ...
    'name',     'entry',	'timeout',  'next'; ...
    'first',    hello,      0.1,        'second'; ...
    'second',	pardon,     0.1,        'third'; ...
    'third',    goodbye,    0.0,        ''; ...
    };
machine.addMultipleStates(stateList);

clc
machine.run;

%% topsSergeant
% A "sergeant" can compose other objects and make them run() together.
% Actually, it tells its components to step() one at a time, over and over
% again, which is a lot like running.  Thus, topsSergeant only works with
% objects of the topsSteppable class and its subclasses, which include
% topsCallList and topsStateMachine.
replies = topsCallList;
replies.addCall(howdy);
replies.addCall(fine);

sergeant = topsSergeant;
sergeant.addChild(replies);
sergeant.addChild(machine);

% The sergeant will keep running until any one of its components is done.
% For this example, we want to keep running until the state machine is
% done, so we tell the "replies" call list to keep running forever.
replies.alwaysRunning = true;

clc
sergeant.run;

%% topsTreeNode
% A "tree node" is a building block.  You can put many nodes together to
% make a tree structure which organizes flow through various parts of an
% experiment.  Each node can have children, which may be other topsRunnable
% objects, including other tree nodes.  Each node will tell its children to
% run(), allowing them to do interesting behaviors, or just delegating to
% other tree nodes for the sake of organizaion.
topNode = topsTreeNode;

% Add the same "calls" as above to the tree
callsNode = topNode.newChildNode;
callsNode.addChild(calls);

% Add the same state machine as above to the tree
machineNode = topNode.newChildNode;
machineNode.addChild(machine);

% Add the same "sergeant" as above to the tree
sergeantNode = topNode.newChildNode;
sergeantNode.addChild(sergeant);

% Run the tree, which will run all of the examples above.
clc
topNode.run

%% startFevalable and finishFevalable
% Any of the objects demonstrated above can call a function just before or
% after it runs.  This allows you to set things up and clean things up as
% you go.   Or, for this example, we can make the command line output
% easier to read.

space = {@disp, ' '};
callsNode.finishFevalable = space;
machineNode.finishFevalable = space;
sergeantNode.finishFevalable = space;

calls.startFevalable = {@disp, 'Calling some functions:'};
machine.startFevalable = {@disp, 'Running some states:'};
sergeant.startFevalable = {@disp, 'Mixing call list and state machine:'};

clc
topNode.run

%% graphical user interface
% You can also visualize the tree structure in a figure.
topNode.gui;