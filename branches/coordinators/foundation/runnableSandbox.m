clear
clear classes
clc
topsDataLog.flushAllData;
theLog = topsDataLog.theDataLog;
theLog.printLogging = true;

% make some call lists
helloList = topsCallList;
helloList.name = 'hellos';
helloList.fevalables.add({@disp, 'Hello runnable'});
helloList.fevalables.add({@disp, 'Hello steppable'});
helloList.alwaysRunning = false;

goodbyeList = topsCallList;
goodbyeList.name = 'goodbyes';
goodbyeList.fevalables.add({@disp, 'Goodbye runnable'});
goodbyeList.fevalables.add({@disp, 'Goodbye steppable'});
goodbyeList.alwaysRunning = false;

% make a state machine
machine = topsStateMachine;
machine.name = 'state machine';

% make a sergeant that composes all of the above
sarg = topsSergeant;
sarg.name = 'sarg';
sarg.components.add(helloList);
sarg.components.add(machine);
sarg.components.add(goodbyeList);

% make a runnable tree
top = topsTreeNode;
top.name = 'top';

middle = top.newChild;
middle.name = 'middle';

bottom(1) = middle.newChild;
bottom(1).name = 'I have a call list';
bottom(1).addChild(helloList);

bottom(2) = middle.newChild;
bottom(2).name = 'I have a state machine';
bottom(2).addChild(machine);

bottom(3) = middle.newChild;
bottom(3).name = 'I have a sergeant';
bottom(3).addChild(sarg);

top.run
