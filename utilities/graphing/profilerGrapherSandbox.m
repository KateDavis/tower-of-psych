clear
clear classes
clc

pg = ProfilerGrapher;
pg.toDo = 'configureSquaresTask;';

pg.dataGrapher.floatingEdgeNames = false;
pg.dataGrapher.listedEdgeNames = true;

% "dot", "neato", "twopi", "circo", or "fdp"
pg.dataGrapher.graphVisAlgorithm = 'dot';

pg.runProfiler;
pg.writeDotFile;
pg.generateGraph;
