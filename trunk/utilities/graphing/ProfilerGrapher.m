classdef ProfilerGrapher < handle
    % @class ProfilerGrapher
    % Graphs output from the Matlab profiler with the Graphviz tool.
    % @ details
    % ProfilerGrapher evaluates a given "toDo" expression under the Matlab
    % profiler and gathers function call data.  It confugures a DataGrapher
    % to graph which functions called which, and how many times.
    % @ingroup utilities
    
    properties
        % string, a Matlab expression to eval() under the Matlab profiler
        toDo = '';
        
        % output from the Matlab profiler
        profilerInfo;
        
        % a DataGrapher object for graphing the profiler output
        dataGrapher;
    end
    
    methods
        % Constructor takes no arguments.
        function self = ProfilerGrapher()
            self.dataGrapher = DataGrapher;
            self.dataGrapher.nodeNameFunction = ...
                @ProfilerGrapher.shortNameOfFunction;
            self.dataGrapher.edgeFunction = ...
                @ProfilerGrapher.edgeFromChildren;
        end
        
        function info = runProfiler(self)
            profile('on');
            try
                eval(self.toDo);
            catch err
                profile('off');
                rethrow(err);
            end
            profile('off');
            info = profile('info');
            self.profilerInfo = info;
            self.dataGrapher.inputData = info.FunctionTable;
        end
        
        function writeDotFile(self)
            self.dataGrapher.writeDotFile;
        end
        
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods (Static)
        function nodeName = shortNameOfFunction(inputData, index)
            id = inputData(index);
            shortName = ProfilerGrapher.getShortFunctionName(id.FunctionName);
            nodeName = sprintf('%s (%d)', shortName, id.NumCalls);
        end
        
        function [edgeIndexes, edgeNames] = edgeFromChildren(inputData, index)
            id = inputData(index);
            edgeIndexes = [];
            edgeNames = {};
            for ii = 1:length(id.Children)
                edgeIndexes(ii) = id.Children(ii).Index;
                edgeNames{ii} = sprintf('%.4fs (%d)', ...
                    id.Children(ii).TotalTime, ...
                    id.Children(ii).NumCalls);
            end
        end
        
        function shortName = getShortFunctionName(longName)
            if all(isstrprop(longName, 'alphanum'))
                shortName = longName;
            else
                % Need to scrape out ugly names like these:
                %
                % topsGroupedList>topsGroupedList.mapContainsItem
                % TestTopsGroupedList>@()self.groupedList.mergeGroupsIntoGroup(self.stringGroups(1:2),bigGroup)
                % @dataset/private/checkduplicatenames
                % ObjectGrapher>@(object,depth,path,objFcn)edgeFromNodeToObject(name,p,path,object,dotFile,keysMap)
                % ObjectGrapher>ObjectGrapher.writeDotFile/nodeLabelForObject
                %
                % I don't know the actual spec that genereates these, so I
                % hope they're representative
                scopeExp = '(\w+)';
                scopeTokens = regexp(longName, scopeExp, 'tokens');
                if isempty(scopeTokens)
                    scopeName = '';
                else
                    scopeName = scopeTokens{1}{1};
                end
                
                funExp = { ...
                    '[\.\>\/](\w+)', ...
                    '(\w+)[\(]'};
                funTokens = {};
                for ii = 1:length(funExp)
                    funTokens = regexp(longName, funExp{ii}, 'tokens');
                    if ~isempty(funTokens)
                        break;
                    end
                end
                if isempty(funTokens)
                    funName = '';
                else
                    funName = funTokens{1}{end};
                end
                
                shortName = sprintf('%s:%s', scopeName, funName);
                
                disp(' ')
                disp(longName)
                disp(shortName)
            end
        end
    end
end