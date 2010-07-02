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
list = topsCallList;
list.name = 'calls';
list.fevalables.add({@disp, 'Hello runnable'});
list.fevalables.add({@disp, 'Hello steppable'});
list.alwaysRunning = false;

sarg = topsSergeant;
sarg.name = 'sarg';
sarg.components.add(list);
sarg.components.add(list);
bottom(1).addChild(sarg);

bottom(2).addChild(list);

top.run

