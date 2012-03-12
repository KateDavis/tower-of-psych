% Try graphing the output of the Matlab profiler.
clear
clear classes
clc

% Create the grapher object.
%   tell it to generate profiler data with the "encounter" demo game
%   configuraiton.
pg = ProfilerGrapher();
pg.toDo = 'encounter();';

% Generate the profiler data and graph it!
pg.run();
pg.writeDotFile();
pg.generateGraph();