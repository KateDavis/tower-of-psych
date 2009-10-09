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
        
        function testUpdateMnemonicsListBoxes(self)
            assertTrue(isempty(self.logGui.mnemonics), 'gui mnemonics list should start out empty')
            
            newMnemonics = {'aaaa', 'bbbb', 'cccc'};
            for m = newMnemonics
                topsDataLog.logMnemonicWithData(m{1}, 1);
            end
            assertEqual(self.logGui.mnemonics, newMnemonics, 'gui mnemonics list should match mnemonics just added')
            assertEqual(sort(self.logGui.mnemonics), sort(topsDataLog.getAllMnemonics), 'gui mnemonics list should contain same values as topsDataLog')
        end
    end
end