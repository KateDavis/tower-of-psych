clear
clear classes
clc

[tree, list] = configureSpotsTasks;

og = ObjectGrapher;
og.dataGrapher.floatingEdgeNames = false;

og.addSeedObject(list);

og.traceLinksForEdges;
og.writeDotFile;
og.generateGraph;