classdef (Sealed) topsDataLog < topsGroupedList
    % @class topsDataLog
    % One central place to log data on the fly.
    % topsDataLog makes it easy to log data as you go.  It's a "singleton"
    % class, which means that only one can exist at a time, and you never
    % have to create one yourself.  You just call topsDataLog methods from
    % any code that needs to use the log.
    % <br><br> topsDataLog is a subclass of topsGroupedList, which means it
    % has all the organization and capabilities of topsGroupedList, plus
    % more.
    % <br><br>
    % 

    properties
        % Any function that returns the current time as a number.
        clockFcn = @topsTimer;
    end
    
    properties (SetAccess=private)
        % The time of the first logged data, as reported by clockFcn
        earliestTime;
        
        % The time of the last logged data, as reported by clockFcn
        latestTime;
    end
    
    events
        % Notifies any listeners when all data are cleared from the log
        FlushedTheDataLog;
    end
    
    methods (Access = private)
        function self = topsDataLog
            self.earliestTime = nan;
            self.latestTime = nan;
        end
    end
    
    methods (Static)
        % Access the current data log "singleton"
        % @details
        % Returns the current instance of topsDataLog.  Use this method
        % instad of a class constructor.  This method will create a new
        % data log the first time it's called, and return the same data log
        % subsequently.
        % <br><br>
        % To get a like-new data log, call the flushAllData() method, which
        % will erase everything in the log.
        function log = theDataLog
            persistent theLog
            if isempty(theLog) || ~isvalid(theLog)
                theLog = topsDataLog;
            end
            log = theLog;
        end
        
        % Launch a graphical interface for the data log.
        % @param alternateFlag an optional hint for picking which interface
        % to use.
        % @details
        % By default, gui() launches the topsDataLogGUI interface, which
        % shows a scrolling view of all logged data, sorted by time.  If
        % you provide an alternateFlag which is the string 'asList', then
        % gui() will instead launch the generic topsGroupedListGUI, which
        % lets you browse the log group by group.
        % <br><br>
        % Returns a handle to the new graphical interface either
        % topsDataLogGUI or topsGroupedListGUI.
        function g = gui(alternateFlag)
            if nargin && strcmp(alternateFlag, 'asList')
                g = topsGroupedListGUI(topsDataLog.theDataLog);
            else
                g = topsDataLogGUI;
            end
        end
        
        % Clear out all data from the log
        % @details
        % You can's create a fresh instance of topsDataLog, but you can
        % always clear out the existing instance.  You probably should do
        % this before starting an experiment.
        % <br><br>
        % Removes all items from all groups, then removes the groups
        % themselves.  Then sets earliestTime and latestTime to nan.  Then
        % sends a FlushedTheDataLog notification to any listeners.
        function flushAllData
            self = topsDataLog.theDataLog;
            for g = self.groups
                self.removeGroup(g{1});
            end
            self.earliestTime = nan;
            self.latestTime = nan;
            self.notify('FlushedTheDataLog');
        end
        
        % 
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
