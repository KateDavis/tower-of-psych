clear
clc

t = topsBlockTree;
t.iterations = 1;
t.iterationMethod = 'sequential';
t.name = 'experiment session';
t.blockBeginFcn = {@disp, 'configure the session'};
t.blockActionFcn = {@disp, 'run the session'};
t.blockEndFcn = {@disp, 'finish the session'};
for ii = 1:3
    c = topsBlockTree;
    c.iterations = 2;
    t.iterationMethod = 'random';
    c.name = sprintf('task #%d', ii);
    c.blockBeginFcn = {@disp, sprintf('setup task "%s"', c.name)};
    c.blockActionFcn = {@disp, 'run task'};
    c.blockEndFcn = {@disp, 'finished task'};
    t.addChild(c);
    
    for ii = 1:2
        g = topsBlockTree;
        g.iterations = 10;
        t.iterationMethod = 'random';
        g.name = sprintf('trial type %d', ii);
        g.blockBeginFcn = {@disp, sprintf('setup trials for "%s"', g.name)};
        g.blockActionFcn = {@eye, 5};
        g.blockEndFcn = {@disp, 'did trials'};
        c.addChild(g);
    end
end


%%
summary = t.preview;
unrolled = t.unrollSummary(summary)



%%
summary = t.run;
unrolled = t.unrollSummary(summary);