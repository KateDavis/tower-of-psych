classdef (Sealed) topsDataLog < handle
    %Singleton to log events, data with time stamps
    
    properties
        clockFcn = @now;
    end
    
    properties (SetAccess=private)
        mnemonicMap;
        count = 0;
        earliestTime = nan;
        latestTime = nan;
    end
    
    events
        NewMnemonic;
        NewData;
        FlushedTheDataLog;
    end
    
    methods (Access = private)
        function self = topsDataLog
            self.mnemonicMap = containers.Map;
            self.count = 0;
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
        
        function logStruct = newLogStruct(data, time, mnemonic)
            % cell array of times -> struct array
            %   else, scalar struct
            if iscell(data) && ~iscell(time)
                logStruct = struct( ...
                    'data', {data}, ...
                    'time', time, ...
                    'mnemonic', mnemonic);
            else
                logStruct = struct( ...
                    'data', data, ...
                    'time', time, ...
                    'mnemonic', mnemonic);
            end
        end
        
        function flushAllData
            self = topsDataLog.theDataLog;
            
            for m = self.mnemonicMap.keys
                timeMap = self.mnemonicMap(m{1});
                for t = timeMap.keys
                    timeMap.remove(t{1});
                end
                self.mnemonicMap.remove(m{1});
            end
            self.earliestTime = nan;
            self.latestTime = nan;
            self.count = 0;
            notify(self, 'FlushedTheDataLog');
        end
        
        function logMnemonicWithData(mnemonic, data)            
            self = topsDataLog.theDataLog;
            
            nowTime = feval(self.clockFcn);
            self.earliestTime = min(self.earliestTime, nowTime);
            self.latestTime = max(self.latestTime, nowTime);

            if nargin < 2
                data = nowTime;
            end
            
            if self.mnemonicMap.isKey(mnemonic)
                % add data to existing Map
                %   increment count when not replacing a Map entry
                timeMap = self.mnemonicMap(mnemonic);
                oldCount = timeMap.length;
                timeMap(nowTime) = data;
                self.count = self.count + timeMap.length - oldCount;
            else
                % create new Map with numeric key, increment count
                self.mnemonicMap(mnemonic) = ...
                    containers.Map(nowTime, data, 'uniformValues', false);
                self.count = self.count + 1;
                notify(self, 'NewMnemonic', EventWithData(mnemonic));
            end
            
            dataStruct = topsDataLog.newLogStruct(data, nowTime, mnemonic);
            notify(self, 'NewData', EventWithData(dataStruct));
        end
        
        function allMnemonics = getAllMnemonics
            self = topsDataLog.theDataLog;
            allMnemonics = self.mnemonicMap.keys;
        end
        
        function logStruct = getAllDataSorted
            self = topsDataLog.theDataLog;
            
            logStruct = topsDataLog.newLogStruct({}, {}, {});
            for m = self.mnemonicMap.keys
                % growing the log struct may be too slow
                logStruct = cat(2, logStruct, self.getDataForMnemonic(m{1}));
            end
            
            % sorting from scratch may be too slow
            %   may be able to improve since keys
            %   from each timeMap should be sorted--merge k sorted lists
            [a, order] = sort([logStruct.time]);
            logStruct = logStruct(order);
        end
        
        function logStruct = getDataForMnemonic(mnemonic)
            self = topsDataLog.theDataLog;
            
            if self.mnemonicMap.isKey(mnemonic)
                timeMap = self.mnemonicMap(mnemonic);
                logStruct = topsDataLog.newLogStruct(timeMap.values, timeMap.keys, mnemonic);
            else
                logStruct = topsDataLog.newLogStruct({}, {}, {});
            end
        end
    end
end
