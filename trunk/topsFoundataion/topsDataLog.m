classdef (Sealed) topsDataLog < handle
    %Singleton to log events, data with time stamps
    
    properties
        mnemonicMap;
        clockFcn = @now;
    end
    
    properties (SetAccess=private)
        count=0;
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
    end
    
    methods (Access = private, Static)
        function logStruct = newLogStruct(datas, times, mnemonics)
            logStruct = struct( ...
                'data', datas, ...
                'time', times, ...
                'mnemonic', mnemonics);
        end
    end
    
    methods
        function flushAllData(self)
            keys = self.mnemonicMap.keys;
            for ii = 1:length(keys)
                self.mnemonicMap.remove(keys{ii});
            end
            self.count = 0;
        end
        
        function flushDataForMnemonic(self, mnemonic)
            if self.mnemonicMap.isKey(mnemonic)
                timeMap = self.mnemonicMap(mnemonic);
                keys = timeMap.keys;
                for ii = 1:length(keys)
                    timeMap.remove(keys{ii});
                end
                self.mnemonicMap.remove(mnemonic);
            end
        end
        
        function logMnemonicWithData(self, mnemonic, data)
            nowTime = feval(self.clockFcn);
            if nargin < 3
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
            end
        end
        
        function allMnemonics = getAllMnemonics(self)
            allMnemonics = self.mnemonicMap.keys;
        end
        
        function logStruct = getAllDataSorted(self)
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
        
        function logStruct = getDataForMnemonic(self, mnemonic)
            if self.mnemonicMap.isKey(mnemonic)
                timeMap = self.mnemonicMap(mnemonic);
                logStruct = topsDataLog.newLogStruct(timeMap.values, timeMap.keys, mnemonic);
            else
                logStruct = topsDataLog.newLogStruct({}, {}, {});
            end
        end
    end
end
