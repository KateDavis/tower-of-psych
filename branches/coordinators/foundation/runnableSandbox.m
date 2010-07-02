clear
clear classes
clc
topsDataLog.flushAllData;
theLog = topsDataLog.theDataLog;
theLog.printLogging = true;

% make a runnable tree
top = topsTreeNode;
middle = top.newChild;
bottom(1) = middle.newChild;
bottom(2) = middle.newChild;

top.name = 'top';
middle.name = 'middle';
[bottom.name] = deal('bottom1', 'bottom2');

% make some noise at the bottom
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

sarg = topsSergeant;
sarg.name = 'sarg';
sarg.components.add(helloList);
sarg.components.add(goodbyeList);
bottom(1).addChild(sarg);

bottom(2).addChild(helloList);

top.run
