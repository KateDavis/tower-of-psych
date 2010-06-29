classdef TestTopsDataLogGUI < TestCase
    
    properties
        logGui;
    end
    
    methods
        function self = TestTopsDataLogGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            topsDataLog.flushAllData;
            self.logGui = topsDataLogGUI;
        end
        
        function tearDown(self)
            delete(self.logGui);
            self.logGui = [];
            topsDataLog.flushAllData;
        end
        
        function testSingleton(self)
            newGui = topsDataLogGUI;
            assertFalse(self.logGui==newGui, 'topsDataLogGUI should not be a singleton');
            delete(newGui);
        end
        
        function testUpdateGroupsList(self)
            assertTrue(isempty(self.logGui.groups), 'gui groups list should start out empty')
            
            newGroups = {'aaaa', 'bbbb', 'cccc'};
            for g = newGroups
                topsDataLog.logDataInGroup(1, g{1});
            end
            assertEqual(self.logGui.groups, newGroups, 'gui groups list should match groups just added')
            theLog = topsDataLog.theDataLog;
            assertEqual(sort(self.logGui.groups), sort(theLog.groups), 'gui groups list should contain same values as topsDataLog')
        end
        
        function testReplayData(self)
            newGroups = {'aaaa', 'bbbb', 'cccc'};
            for g = newGroups
                topsDataLog.logDataInGroup(1, g{1});
            end
            self.logGui.replayDataLog;
        end
    end
end