classdef topsFunctionLoop < topsGroupedList
    properties (SetObservable)
        proceed = true;
        clockFcn = @topsTimer;
    end
    
    methods
        function self = topsFunctionLoop
        end
        
        function addFunctionToGroupWithRank(self, fcn, group, rank)
            % add a function to be called while loop is runnung.
            %   fcn is an fevalable cell array
            %   group is a string for grouping related functions
            %   rank is a number for sorting function in the same group
            assert(ischar(group), 'group argument should be a string');
            assert(isnumeric(rank), 'rank argument should be numeric');
            self.addItemToGroupWithMnemonic(fcn, group, rank);
        end
        
        function removeFunctionFromGroup(self, fcn, group)
            % search given group for function to remove
            %   fcn is an fevalable cell array
            %   group is a string for grouping related functions
            self.removeItemFromGroup(fcn, group);
        end
        
        function [functionList, ranks] = getFunctionListForGroup(self, group)
            if nargout > 1
                [functionList, ranks] = self.getAllItemsFromGroup(group);
            else
                functionList = self.getAllItemsFromGroup(group);
            end
        end
        
        function runForGroupForDuration(self, group, duration)
            if nargin < 3 || isempty(duration) || ~isfinite(duration)
                duration = 0;
            end
            
            % run whole passes through loop, until duration
            functionLoop = self.getFunctionListForGroup(group);
            n = length(functionLoop);
            
            self.proceed = true;
            nowTime = feval(self.clockFcn);
            endTime = nowTime + duration;
            while (nowTime <= endTime)
                for ii = 1:n
                    feval(functionLoop{ii}{:});
                    if ~self.proceed
                        return
                    end
                end
                nowTime = feval(self.clockFcn);
            end
        end
    end
end