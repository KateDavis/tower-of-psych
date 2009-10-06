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
            ignoredMnemonics = get(self.logGui.ignoredMnemonicsList, 'String');
            assertTrue(isempty(ignoredMnemonics), 'ignored mnemonics list should start out empty')
            
            triggerMnemonics = get(self.logGui.triggerMnemonicsList, 'String');
            assertTrue(isempty(triggerMnemonics), 'trigger mnemonics list should start out empty')
            
            newMnemonics = {'aaaa', 'bbbb', 'cccc'};
            for m = newMnemonics
                topsDataLog.logMnemonicWithData(m{1}, 1);
            end
            
            ignoredMnemonics = get(self.logGui.ignoredMnemonicsList, 'String');
            assertEqual(ignoredMnemonics', newMnemonics, 'ignored mnemonics list should match new mnemonics')
            
            triggerMnemonics = get(self.logGui.triggerMnemonicsList, 'String');
            assertEqual(triggerMnemonics', newMnemonics, 'trigger mnemonics list should match new mnemonics')
        end
        
        function testFixListSelectionsOnInsert(self)
            topsDataLog.logMnemonicWithData('aaaa', 1);
            topsDataLog.logMnemonicWithData('bbbb', 1);
            topsDataLog.logMnemonicWithData('dddd', 1);
            
            % set a multi-selection
            set(self.logGui.ignoredMnemonicsList, 'Value', [1 2 3]);
            
            % insert a new mnemonic inside the selection
            topsDataLog.logMnemonicWithData('cccc', 1);
            newSelection = get(self.logGui.ignoredMnemonicsList, 'Value');
            
            assertEqual(newSelection, [1 2 4], 'failed to manage selctions with inserted mnemonic')
        end
    end
end