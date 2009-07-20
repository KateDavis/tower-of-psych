clear
clc

duration = 1;
fl = topsFunctionLoop;
fl.clockFcn = @GetSecs;

fl.addFunctionWithPriorityToMode({@nothing}, 0);

fl.addFunctionWithPriorityToMode({@eye, 100}, 1);
fl.addFunctionWithPriorityToMode({@eye, 6}, 3);
fl.addFunctionWithPriorityToMode({@eye, 33}, 2);
fl.addFunctionWithPriorityToMode({@eye, 9}, 1.5, 'ham');
fl.addFunctionWithPriorityToMode({@eye, 2}, 2.5, 'ham');

%%
preview = fl.previewForModes;
tic
summary = fl.runForDurationForModes(duration, {'default', 'ham'});
%summary = fl.runForIterationsForModes(10, {'default', 'ham'});
toc
times = [summary{:,1}];
times(end) - times(1)
hist(diff(times))