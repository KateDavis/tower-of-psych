classdef TestTopsDataLog < TestCase
    
    properties
        groups;
        data;
        eventCount;
        filename;
    end
    
    methods
        function self = TestTopsDataLog(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.groups = {'animals', 'pizzas', 'phone books'};
            self.data = {1, {'elephant', 'sauce'}, []};
            self.eventCount = 0;
            [p,f] = fileparts(mfilename('fullpath'));
            self.filename = fullfile(p, 'dataLogTest.mat');
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            topsDataLog.flushAllData;
            if exist(self.filename)
                delete(self.filename)
            end
        end
        
        function logSomeData(self)
            % add data, redundant under each group
            for g = self.groups
                for d = self.data
                    topsDataLog.logDataInGroup(d{1}, g{1});
                end
            end
        end
        
        function hearEvent(self, obj, event)
            self.eventCount = self.eventCount + 1;
        end
        
        function testSingleton(self)
            log1 = topsDataLog.theDataLog;
            log2 = topsDataLog.theDataLog;
            assertTrue(log1==log2, 'topsDataLog should be a singleton');
        end
        
        function testDataRetrievalSortedStruct(self)
            self.logSomeData;
            
            % should get data, sorted by time
            logStruct = topsDataLog.getSortedDataStruct;
            logGroups = {logStruct.group};
            for g = self.groups
                assertEqual(sum(strcmp(g{1}, logGroups)), length(self.data), 'wrong number log entries per group')
            end
            
            logTimes = [logStruct.mnemonic];
            assertTrue(all(diff(logTimes) >= 0), 'log entries should be sorted by time')
        end
        
        function testDataFlush(self)
            % log should arrive flushed, from setUp()
            theLog = topsDataLog.theDataLog;
            assertEqual(theLog.length, 0, 'data log should start with 0 entries')
            assertTrue(isempty(theLog.groups), 'data log should start with no groups')
            
            self.logSomeData;
            topsDataLog.flushAllData;
            assertEqual(theLog.length, 0, 'failed to clear log entries after adding')
            assertTrue(isempty(theLog.groups), 'failed to clear log groups after adding')
        end
        
        function testDataFlushNotification(self)
            theLog = topsDataLog.theDataLog;
            listener = theLog.addlistener('FlushedTheDataLog', @self.hearEvent);
            n = 5;
            for ii = 1:n
                topsDataLog.flushAllData;
            end
            assertEqual(self.eventCount, n, 'heard wrong number of FlushedTheDataLog events');
            delete(listener);
        end
        
        function testToFromFile(self)
            theLog = topsDataLog.theDataLog;
            self.logSomeData;
            expectedLength = theLog.length;
            
            topsDataLog.writeDataFile(self.filename);
            assertTrue(exist(self.filename) > 0, ...
                'should have created data file')
            
            topsDataLog.flushAllData;
            assertEqual(theLog.length, 0, ...
                'failed to clear log after saving file')
            
            topsDataLog.readDataFile(self.filename);
            assertEqual(theLog.length, expectedLength, ...
                'read wrong number of data from file')
            
            delete(self.filename);
        end
    end
end
