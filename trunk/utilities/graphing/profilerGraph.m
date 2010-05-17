clear
clear classes
clc

pg = ProfilerGrapher;
pg.toDo = 'runAllTopsTests';

pg.runProfiler;
pg.writeDotFile;
% pg.generateGraph;