classdef ProfilerGrapher < handle
    % @class ProfilerGrapher
    % Graphs output from the Matlab profiler with the Graphviz tool.
    % @ details
    % ProfilerGrapher evaluates a given "toDo" expression under the Matlab
    % profiler and gathers function call data.  It confugures a DataGrapher
    % to graph which functions called which, and how many times.
    % @ingroup utilities
    
    % @todo
    % DataGrapher can ignore and not write nodes empty names.
    % ProfilerGrapher can go through and blank out function names that
    % match or fail some criteria (whatever they be).  It can also clear
    % out Children references for those nodes parents.  That way some
    % profiler results can be ignored.
    %
    % So the question is, what are the criteria?  Positive or negative?
    
    properties
        % string, a Matlab expression to eval() under the Matlab profiler
        toDo = '';
        
        % output from the Matlab profiler
        profilerInfo;
        
        % cell array of strings of absolute paths containing functions to
        % ignore
        ignoredPaths = {};
        
        % cell array of strings of absolute paths containing the only
        % functions to include
        includePaths = {};
        
        % a DataGrapher object for graphing the profiler output
        dataGrapher;
    end
    
    methods
        % Constructor takes no arguments.
        function self = ProfilerGrapher()
            self.dataGrapher = DataGrapher;
            self.dataGrapher.workingFileName = 'profilerGraph';
            self.dataGrapher.nodeNameFunction = ...
                @ProfilerGrapher.shortNameWithType;

            self.dataGrapher.nodeDescriptionFunction = ...
                @ProfilerGrapher.totalCallsAndTime;

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
        end
        
        function info = appplyFunctionFilter(self, info)
            names = {info.FileName};

            isIncluded = true(size(names));
            for ii = 1:length(self.includePaths)
                include = self.includePaths{ii};
                n = length(include);
                isIncluded = strncmp(include, names, n);
            end
            
            isIgnored = false(size(names));
            for ii = 1:length(self.ignoredPaths)
                ignore = self.ignoredPaths{ii};
                n = length(ignore);
                isIgnored = strncmp(ignore, names, n);
            end
            
            failed = isIgnored | ~isIncluded;
            [info(failed).FunctionName] = deal('');
        end
        
        function writeDotFile(self)
            info = self.profilerInfo.FunctionTable;
            info = self.appplyFunctionFilter(info);
            self.dataGrapher.inputData = info;
            self.dataGrapher.writeDotFile;
        end
        
        function generateGraph(self)
            self.dataGrapher.generateGraph;
        end
    end
    
    methods (Static)
        function nodeName = shortNameWithType(inputData, index)
            id = inputData(index);
            if isempty(id.FunctionName)
                nodeName = '';
            else
                shortName = ProfilerGrapher.getShortFunctionName(id.FunctionName);
                typeName = id.Type;
                nodeName = sprintf('%s(%s)', shortName, typeName);
            end
        end

        function description = totalCallsAndTime(inputData, index)
            id = inputData(index);
            description{1} = sprintf('called %d times (%fs)', ...
                id.NumCalls, id.TotalTime);
        end
        
        function [edgeIndexes, edgeNames] = edgeFromChildren(inputData, index)
            id = inputData(index);
            edgeIndexes = [];
            edgeNames = {};
            for ii = 1:length(id.Children)
                edgeIndexes(ii) = id.Children(ii).Index;
                edgeNames{ii} = sprintf('%d calls (%fs) to', ...
                    id.Children(ii).NumCalls, ...
                    id.Children(ii).TotalTime);
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
                
                funExp = {'[\\\/\>\)\.](\w+)'};
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
                    funName = funTokens{end}{1};
                end
                
                shortName = sprintf('%s:%s', scopeName, funName);
            end
        end
    end
end