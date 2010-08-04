close all
clear
clear classes
clc

%%
dataPath = '/Users/ben/Desktop/Labs/Gold/testData';
dataFile = '2afcDemoData.mat';
data = fullfile(dataPath, dataFile);

topsDataLog.readDataFile(data)
log = topsDataLog.theDataLog;

g = topsDataLogGUI;