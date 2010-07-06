classdef (Sealed) topsDataLog < topsGroupedList
    % @class topsDataLog
    % One central place to log data on the fly.
    % topsDataLog makes it easy to log data as you go.  It's a "singleton"
    % class, which means that only one can exist at a time, and you never
    % have to create one yourself.  You just call topsDataLog methods from
    % any code that needs to use the log.
    % @details
    % topsDataLog is a subclass of topsGroupedList, which means it
    % has all the organization and capabilities of topsGroupedList, plus
    % more.
    % @details
    % Thus, you must log each piece of data in a "group" of related
    % data.  The group might correspond to a recuurring event, such as
    % 'trial start'. You don't have to supply a "mnemonic" for each piece
    % of data because topsDataLog uses timestamps to identify pieces of
    % data in each group.
    % @details
    % In your experiment code, you can add to the log as many times as you
    % like.  If you're not sure whether some piece of data will turn out to
    % be important, you can go ahead and log it anyway.  You don't have to
    % worry about the log filling up, how to allcate space for more data,
    % or even how the data are ultimately stored.  That's the log's job.
    % @details
    % Other topsFoundataion classes will also add data to the log, to help
    % you keep track of details that aren't specific to your experiment.
    % For example, topsRunnable objects make log entries as they start and
    % finish running.
    % @details
    % With your log entries and the entries made automatically by
    % topsFoundataion classes, it should be straightforward to look at the
    % log after an experiment and get a sense of "what happened, when".
    % The log's gui() method should make this even easier.  You can use it
    % to launch one of two graphical interfaces:
    %   - topsDataLog.gui launches topsDataLogGUI, which plots a summary of
    %   all logged data, sorted by timestamps.
    %   - topsDataLog.gui('asList') launches the generic topsGroupedListGUI,
    %   which breaks down the data by groups and timestamps, and gives a
    %   detailed look at each piece of data.
    %   .
    % You can also use topsDataLogGUI online, to see data as they arrive in
    % the log.
    % @ingroup foundation
    
    properties
        % any function that returns the current time as a number
        clockFunction = @topsClock;
        
        % true or false, wether to pring log info as data are logged
        printLogging = false;
    end
    
    properties (SetAccess=private)
        % the time of the first logged data, as reported by clockFunction
        earliestTime;
        
        % the time of the last logged data, as reported by clockFunction
        latestTime;
    end
    
    events
        % notifies any listeners when all data are cleared from the log
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
        % @details
        % For most log operations, you don't need this method.  You can
        % just use the static methods below and they will access the
        % current data log for you.
        % @details
        % For a few operations it makes sense to get at the log itself,
        % using this method.  For example, you might wish to change the
        % log's clockFunction, to use some custom timer.  In that case you would
        % get the log using this method, and set the value of log.clockFunction
        % just like you would set the value of any object property.
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
        % By default, gui() launches the topsDataLogGUI graphical
        % interface, which plots a sumary of all logged data, sorted by
        % time.  You can use this interface online, to see data as they
        % arrive in the log.
        % @details
        % If you provide @a alternateFlag and it has the value
        % 'asList', then gui() will launch the generic topsGroupedListGUI,
        % which lets you browse the log by groups and timestamps, and shows
        % details about each piece of data.
        % @details
        % Returns a handle to the new graphical interface, either
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
        % You can't create new instances of topsDataLog, but you can
        % always clear out the existing instance.  You probably should do
        % this before starting an experiment.
        % @details
        % Removes all data from all groups, then removes the groups
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
        
        % Add some data to the log.
        % @param data a value or object to store in the log (but not an
        % object of the handle type).
        % @param group a string for grouping related data, such as the name
        % of a recurring event.
        % @details
        % If @a data is a handle object, converts it to a struct.  This is
        % because Matlab does a bad job of dealing with large numbers of
        % handles to the same object, and a worse job of writing and
        % reading them to disk.  Better to keep the data log out of that
        % mess.
        % @details
        % Otherwise, adds @a data along with the current time
        % reported by clockFunction to @a group, in the current instance
        % of topsDataLog.  Then updates earliestTime and latestTime to
        % account for the the time of this log entry.
        % @details
        % Since topsDataLog is a subclass of topsGroupedList,
        % logging data is a lot like adding items to a list.
        % @a group is treated just like the groups in
        % topsGroupedList.  The data log uses a timestamp as the mnemonic
        % for each data item.
        function logDataInGroup(data, group)
            self = topsDataLog.theDataLog;
            nowTime = feval(self.clockFunction);
            
            if isa(data, 'handle')
                warning('converting handle object %s to struct', ...
                    class(data));
                data = struct(data);
            end
            self.addItemToGroupWithMnemonic(data, group, nowTime);
            
            if self.printLogging
                disp(sprintf('topsDataLog: %s', group))
            end
            
            self.earliestTime = min(self.earliestTime, nowTime);
            self.latestTime = max(self.latestTime, nowTime);
        end
        
        % Get all data from the log.
        % @details
        % Gets all data items from the current instance of topsDataLog, as
        % a struct array, using getAllItemsFromGroupAsStruct().  Sorts the
        % struct array by the time values stored in its mnemonics field.
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
        
        % Write logged data to a file.
        % @param fileWithPath optional .mat filename, which may include a
        % path, in which to save logged data.
        % @details
        % Converts currently logged data to a standard Matlab struct using
        % topsDataLog.getSortedDataStruct() and saves the struct to the
        % given file.
        % @details
        % If @a fileWithPath is omitted, opens a dialog for chosing a file.
        function writeDataFile(fileWithPath)
            self = topsDataLog.theDataLog;
            
            if nargin < 1 || isempty(fileWithPath) || ~ischar(fileWithPath)
                suggestion = '~/*';
                [f, p] = uiputfile( ...
                    {'*.mat'}, ...
                    'Save data log to which .mat file?', ...
                    suggestion);
                
                if ischar(f)
                    fileWithPath = fullfile(p, f);
                else
                    fileWithPath = '';
                end
            end
            
            if ~isempty(fileWithPath)
                data.logStruct = topsDataLog.getSortedDataStruct;
                data.clockFunction = self.clockFunction;
                data.earliestTime = self.earliestTime;
                data.latestTime = self.latestTime;
                save(fileWithPath, '-struct', 'data');
            end
        end
        
        
        % Read previously logged data from a file.
        % @param fileWithPath optional .mat filename, which may include a
        % path, from which to load logged data.
        % @details
        % Expects @a fileWithPath to contain previously logged data in a
        % Matlab struct, as written by topsDataLog.writeDataFile().
        % Populates the topsDataLog singleton with the data from the
        % loaded struct.
        % @details
        % If @a fileWithPath is omitted, opens a dialog for chosing a file.
        function readDataFile(fileWithPath)
            self = topsDataLog.theDataLog;
            
            if nargin < 1 || isempty(fileWithPath) || ~ischar(fileWithPath)
                suggestion = '~/*';
                [f, p] = uigetfile( ...
                    {'*.mat'}, ...
                    'Load data log from which .mat file?', ...
                    suggestion, ...
                    'MultiSelect', 'off');
                
                if ischar(f)
                    fileWithPath = fullfile(p, f);
                else
                    fileWithPath = '';
                end
            end
            
            if ~isempty(fileWithPath)
                data = load(fileWithPath);
                if isstruct(data) && isfield(data, 'logStruct');
                    topsDataLog.flushAllData;
                    for ii = 1:length(data.logStruct)
                        self.addItemToGroupWithMnemonic( ...
                            data.logStruct(ii).item, ...
                            data.logStruct(ii).group, ...
                            data.logStruct(ii).mnemonic);
                    end
                    self.clockFunction = data.clockFunction;
                    self.earliestTime = data.earliestTime;
                    self.latestTime = data.latestTime;
                end
            end
        end
    end
end
