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
helloList.addCall({@disp, 'Hello concurrent'});
helloList.alwaysRunning = false;

goodbyeList = topsCallList;
goodbyeList.name = 'goodbyes';
goodbyeList.addCall({@disp, 'Goodbye runnable'});
goodbyeList.addCall({@disp, 'Goodbye concurrent'});
goodbyeList.alwaysRunning = false;

% make a state machine
machine = topsStateMachine;

% compose all of the above to run concurrently
concurrents = topsConcurrentComposite;
concurrents.name = 'concurrently:';
concurrents.addChild(helloList);
concurrents.addChild(machine);
concurrents.addChild(goodbyeList);

% make a runnable tree
top = topsTreeNode;
top.name = 'top';

middle = top.newChildNode;
middle.name = 'middle';

bottom(1) = middle.newChildNode;
bottom(1).name = 'list:';
bottom(1).addChild(helloList);

bottom(2) = middle.newChildNode;
bottom(2).name = 'state machine:';
bottom(2).addChild(machine);

middle.addChild(concurrents);

top.gui
