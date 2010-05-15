clear
clear classes
clc

dg = DataGrapher;

data(1).name = 'a or A';
data(1).edge = 2;

data(2).name = 'b';
data(2).edge = 3;

data(3).name = 'c';
data(3).edge = [1 2];

dg.inputData = data;
dg.listedEdgeNames = true;
dg.floatingEdgeNames = true;
dg.graphIsDirected = true;

dg.writeDotFile;
dg.generateGraph;