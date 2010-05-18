classdef StateDiagramGrapher < handle
    % @class StateDiagramGrapher
    % Make topsStateMachine state diagrams with the Graphviz tool.
    % @details
    % StateDiagramGrapher summarizes states, actions, inputs, and
    % transitions for a topsStateMachine object.  It allows for input
    % "hints" that specify possible transitions without having to run the
    % state machine.  It configures a DataGrapher to graph which states may
    % transition to which.
    % @ingroup utilities
    
    properties
        % a topsStateMachine object to summarize
        stateMachine;
        
        % struct of state data and input "hints" to graph
        stateInfo;
        
        % struct of state names and representative input values
        inputHints;
        
        % a DataGrapher object for graphing the profiler output
        dataGrapher;
    end
    
    methods
        % Constructor takes no arguments.
        function self = StateDiagramGrapher()
            self.dataGrapher = DataGrapher;
            self.inputHints = struct('stateName', {}, 'inputValue', {});
            
            self.dataGrapher.nodeDescriptionFunction = ...
                @StateDiagramGrapher.statePropertySummary;
            
            self.dataGrapher.edgeFunction = ...
                @StateDiagramGrapher.edgeFromNextAndInputHints;
        end
        
        function addInputHint(self, stateName, inputValue)
            hint.stateName = stateName;
            hint.inputValue = inputValue;
            self.inputHints(end+1) = hint;
        end
        
        function parseStates(self)
            info = self.stateMachine.allStates;
            [info.inputHint] = deal({});
            stateNames = {info.name};
            
            for ii = 1:length(self.inputHints)
                whichState = strcmp(stateNames, self.inputHints(ii).stateName);
                if any(whichState)
                    iv = self.inputHints(ii).inputValue;
                    if iscell(iv)
                        info(whichState).inputHint = cat(2, ...
                            info(whichState).inputHint, iv);
                    else
                        info(whichState).inputHint{end+1} = iv;
                    end
                end
            end
            
            n = length(info) + 1;
            info(n).name = '*START*';
            info(n).timeout = 0;
            info(n).next = info(1).name;
            
            self.stateInfo = info;
            self.dataGrapher.inputData = info;
        end
        
        function writeDotFile(self)
            self.dataGrapher.writeDotFile;
        end
        
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods (Static)
        function description = statePropertySummary(inputData, index)
            id = inputData(index);
            description = {};
            funs = {'entry', 'input', 'exit'};
            for ii = 1:length(funs)
                funName = funs{ii};
                fun = id.(funName);
                if ~isempty(fun)
                    description{end+1} = sprintf('%s: %s', ...
                        funName, stringifyValue(fun{1}));
                end
            end
            
            if id.timeout > 0
                description{end+1} = sprintf('timeout: %f', id.timeout);
            end
            
            if isempty(id.next)
                description{end+1} = '*END*';
            end
        end
        
        function [edgeIndexes, edgeNames] = edgeFromNextAndInputHints(inputData, index)
            id = inputData(index);
            stateNames = {inputData.name};
            edgeIndexes = [];
            edgeNames = {};
            
            if ~isempty(id.next)
                edgeIndexes(end+1) = find(strcmp(stateNames, id.next), 1);
                edgeNames{end+1} = 'next';
            end
            
            for ii = 1:length(id.inputHint)
                hintName = id.inputHint{ii};
                if ~isempty(hintName)
                    edgeIndexes(end+1) = find(strcmp(stateNames, hintName), 1);
                    edgeNames{end+1} = hintName;
                end
            end
        end
    end
end