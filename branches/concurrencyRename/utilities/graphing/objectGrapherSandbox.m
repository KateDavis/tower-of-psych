clear
clear classes
clc

[tree, list] = configureSpotsTasks;

og = ObjectGrapher;
og.dataGrapher.listedEdgeNames = true;
og.dataGrapher.floatingEdgeNames = false;
og.dataGrapher.graphVisAlgorithm = 'dot';

og.addSeedObject(list);

og.traceLinksForEdges;
og.writeDotFile;
og.generateGraph;