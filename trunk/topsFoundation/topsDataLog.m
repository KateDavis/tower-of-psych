classdef (Sealed) topsDataLog < topsGroupedList
    %Singleton to log events, data with time stamps
    
    properties
        clockFcn = @topsTimer;
    end
    
    properties (SetAccess=private)
        earliestTime;
        latestTime;
    end
    
    events
        FlushedTheDataLog;
    end
    
    methods (Access = private)
        function self = topsDataLog
            self.earliestTime = nan;
            self.latestTime = nan;
        end
    end
    
    methods (Static)
        function log = theDataLog
            persistent theLog
            if isempty(theLog) || ~isvalid(theLog)
                theLog = topsDataLog;
            end
            log = theLog;
        end
        
        function g = gui(alternateFlag)
            if nargin && strcmp(alternateFlag, 'asList')
                g = topsGroupedListGUI(topsDataLog.theDataLog);
            else
                g = topsDataLogGUI;
            end
        end
        
        function flushAllData
            self = topsDataLog.theDataLog;
            for g = self.groups
                self.removeGroup(g{1});
            end
            self.earliestTime = nan;
            self.latestTime = nan;
            self.notify('FlushedTheDataLog');
        end
        
        function logDataInGroup(data, group)
            self = topsDataLog.theDataLog;
            
            assert(~isa(data, 'handle'), 'Sorry, but Matlab stinks at keeping handle objects in data files')
            
            nowTime = feval(self.clockFcn);
            self.addItemToGroupWithMnemonic(data, group, nowTime);
            
            self.earliestTime = min(self.earliestTime, nowTime);
            self.latestTime = max(self.latestTime, nowTime);
        end
        
        function logStruct = getSortedDataStruct
            self = topsDataLog.theDataLog;
            
            % grow a struct array, group by group
            logStruct = self.getAllItemsFromGroupAsStruct('');
            for g = self.groups
                groupStruct = self.getAllItemsFromGroupAsStruct(g{1});
                logStruct = cat(2, logStruct, groupStruct);
            end
            
            % sorting from scratch may be too slow
            %   may be able to improve since keys
            %   from each group should be already sorted--merge k lists
            [a, order] = sort([logStruct.mnemonic]);
            logStruct = logStruct(order);
        end
    end
end
