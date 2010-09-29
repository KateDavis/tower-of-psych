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
    % to launch topsDataLogGUI, which plots a raster of all logged data
    % over time, with data groups as rows.
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
        
        % the most recent time when the log was flushed
        % @details
        % flushAllData() sets lastFlushTime to the current time, as
        % reported by clockFunction.
        lastFlushTime;
    end
    
    events
        % notifies any listeners when all data are cleared from the log
        FlushedTheDataLog;
    end
    
    methods (Access = private)
        function self = topsDataLog
            self.earliestTime = nan;
            self.latestTime = nan;
            self.lastFlushTime = nan;
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
        
        % Launch the graphical interface for topsDataLog.
        function g = gui(self)
            g = topsDataLogGUI;
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
            self.lastFlushTime = feval(self.clockFunction);
            self.notify('FlushedTheDataLog');
        end
        
        % Add some data to the log.
        % @param data a value or object to store in the log (but not an
        % object of the handle type).
        % @param group a string for grouping related data, such as the name
        % of a recurring event.
        % @param timestamp optional time marker to use for @a data, instead
        % of the current time.
        % @details
        % If @a data is a handle object, converts it to a struct.  This is
        % because Matlab does a bad job of dealing with large numbers of
        % handles to the same object, and a worse job of writing and
        % reading them to disk.  Better to keep the data log out of that
        % mess.
        % @details
        % Adds @a data to @a group, under the given @a timestamp, in the
        % current instance of topsDataLog.  If @a timestamp is omitted,
        % uses the current time reported by clockFunction.
        % @details
        % Updates earliestTime and latestTime to account for the the time
        % of this log entry.
        % @details
        % Since topsDataLog is a subclass of topsGroupedList, logging data
        % is a lot like adding items to a list. @a group is treated just
        % like the groups in topsGroupedList.  The data log uses a
        % @a timestamp as the mnemonic for each data item.
        function logDataInGroup(data, group, timestamp)
            self = topsDataLog.theDataLog;
            
            if nargin < 3 || isempty(timestamp) || ~isnumeric(timestamp)
                timestamp = feval(self.clockFunction);
            end
            
            if isa(data, 'handle')
                warning('%s converting handle object %s to struct', ...
                    mfilename, class(data));
                data = struct(data);
            end
            self.addItemToGroupWithMnemonic(data, group, timestamp);
            
            if self.printLogging
                disp(sprintf('topsDataLog: %s', group))
            end
            
            self.earliestTime = min(self.earliestTime, timestamp);
            self.latestTime = max(self.latestTime, timestamp);
        end
        
        % Get all data from the log.
        % @param timeRange optional time limits for data, of the form
        % [laterThan asLateAs]
        % @details
        % Gets all data items from the current instance of topsDataLog, as
        % a struct array, using getAllItemsFromGroupAsStruct().  Sorts the
        % struct array by the time values stored in its mnemonics field.
        function logStruct = getSortedDataStruct(timeRange)
            self = topsDataLog.theDataLog;
            if nargin < 1
                timeRange = [-inf inf];
            end
            
            % grow a struct array, group by group
            logStruct = self.getAllItemsFromGroupAsStruct('');
            for g = self.groups
                groupStruct = self.getAllItemsFromGroupAsStruct(g{1});
                if ~isempty(groupStruct)
                    groupTimes = [groupStruct.mnemonic];
                    isInRange = groupTimes > timeRange(1) ...
                        & groupTimes <= timeRange(2);
                    if any(isInRange)
                        logStruct = cat(2, logStruct, groupStruct(isInRange));
                    end
                end
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
                disp(sprintf('%s wrote %s', mfilename, fileWithPath))
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
