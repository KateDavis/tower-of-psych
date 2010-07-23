clear
clear classes
clc
topsDataLog.flushAllData;
theLog = topsDataLog.theDataLog;
theLog.printLogging = true;

% make some call lists
helloList = topsCallList;
helloList.name = 'hellos';
helloList.addCall({@disp, 'Hello runnable'});
helloList.addCall({@disp, 'Hello steppable'});
helloList.alwaysRunning = false;

goodbyeList = topsCallList;
goodbyeList.name = 'goodbyes';
goodbyeList.addCall({@disp, 'Goodbye runnable'});
goodbyeList.addCall({@disp, 'Goodbye steppable'});
goodbyeList.alwaysRunning = false;

% make a state machine
machine = topsStateMachine;

% make a sergeant that composes all of the above
sarg = topsSergeant;
sarg.addChild(helloList);
sarg.addChild(machine);
sarg.addChild(goodbyeList);

% make a runnable tree
top = topsTreeNode;
top.name = 'top';

middle = top.newChildNode;
middle.name = 'middle';

bottom(1) = middle.newChildNode;
bottom(1).name = 'I have a call list';
bottom(1).addChild(helloList);

bottom(2) = middle.newChildNode;
bottom(2).name = 'I have a state machine';
bottom(2).addChild(machine);

bottom(3) = middle.newChildNode;
bottom(3).name = 'I have a sergeant';
bottom(3).addChild(sarg);

top.run