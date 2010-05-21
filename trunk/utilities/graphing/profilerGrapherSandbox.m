clear
clear classes
clc

pg = ProfilerGrapher;
pg.toDo = 'encounter;';

pg.runProfiler;
pg.writeDotFile;
pg.generateGraph;
