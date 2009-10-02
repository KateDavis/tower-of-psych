classdef TestTopsDataLog < TestCase
    
    properties
        mnemonics;
        data;
    end
    
    methods
        function self = TestTopsDataLog(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.mnemonics = {'animals', 'pizzas', 'phone books'};
            self.data = {1, {'elephant', 'sauce'}, []};
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            topsDataLog.flushAllData;
        end
        
        function logSomeData(self)
            % add data, redundant under each mnemonic
            for m = self.mnemonics
                for d = self.data
                    topsDataLog.logMnemonicWithData(m{1}, d{1});
                end
            end
        end
        
        function testSingleton(self)
            log1 = topsDataLog.theDataLog;
            log2 = topsDataLog.theDataLog;
            assertTrue(log1==log2, 'topsDataLog should be a singleton');
        end
        
        function testBasicAccounting(self)
            self.logSomeData;
            
            % should get mxn log entries
            theLog = topsDataLog.theDataLog;
            assertEqual(theLog.count, length(self.mnemonics)*length(self.data), ...
                'failed to count log entries');
            
            % should get each mnemonic, exactly once
            loggedMnemnics = topsDataLog.getAllMnemonics;
            assertEqual(sort(loggedMnemnics), sort(self.mnemonics), 'failed to account for unique mnemonics')
        end
        
        function testDataFlush(self)
            % log should arrive flushed, from setUp()
            theLog = topsDataLog.theDataLog;
            assertEqual(theLog.count, 0, 'failed to setUp log with 0 entries')
            assertTrue(isempty(topsDataLog.getAllMnemonics), 'failed to get log with no mnemonics')
            
            self.logSomeData;
            topsDataLog.flushAllData;
            assertEqual(theLog.count, 0, 'failed to clear log entries after adding')
            assertTrue(isempty(topsDataLog.getAllMnemonics), 'failed to clear log mnemonics after adding')
        end
        
        function testDataRetrievalByMnemonic(self)
            self.logSomeData;
            
            % get the same data back out
            for m = self.mnemonics
                dataStruct = topsDataLog.getDataForMnemonic(m{1});
                loggedData = {dataStruct.data};
                for d = self.data
                    count = 0;
                    for ld = loggedData
                        count = count + isequal(ld, d);
                    end
                    assertEqual(count, 1, 'failed to retrieve exactly one of each datum');
                end
                
                loggedMnemonics = {dataStruct.mnemonic};
                assertTrue(all(strcmp(loggedMnemonics, m{1})), 'data retrieved for wrong mnemonic')
            end
        end
        
        function testDataRetrievalAllSorted(self)
            self.logSomeData;
            
            % should get data, sorted by time
            allLogged = topsDataLog.getAllDataSorted;
            allMnemonics = {allLogged.mnemonic};
            for m = self.mnemonics
                assertEqual(sum(strcmp(m{1}, allMnemonics)), length(self.data), 'wrong number entries for each mnemonic')
            end
            
            allData = {allLogged.data};
            for d = self.data
                count = 0;
                for ld = allData
                    count = count + isequal(ld, d);
                end
                assertEqual(count, length(self.mnemonics), 'wrong number entries for each datum')
            end
            
            allTimes = [allLogged.time];
            assertTrue(all(diff(allTimes) >=0), 'data log entries not sorted by time')
        end
    end
end
