classdef TestTopsModalList < TestCase
    
    properties
        mList;
        items;
        mnemonics;
        eventCount;
    end
    
    methods
        function self = TestTopsModalList(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.mList = topsModalList;
            self.items = {1, 2, 3, 4, 5};
            self.mnemonics = {'one', 'two', 'three', 'four', 'five'};
        end
        
        function tearDown(self)
            delete(self.mList);
            self.mList = [];
        end
        
        function testSingleton(self)
            newList = topsModalList;
            assertFalse(self.mList==newList, 'topsModalList should not be a singleton');
        end
        
        function testInsertByPrecedence(self)
            mode = 'precedence_test';
            precedences = [-2 0 2 5 77];
            for ii = 1:length(self.items)
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, precedences(ii));
            end
            
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            expectedItems = {5, 4, 3, 2, 1};
            assertEqual(storedItems, expectedItems, 'unexpected insert order');
        end
        
        function testInsertOrderNotMatter(self)
            mode = 'insert_order_test';
            precedences = [-2 0 2 5 77];
            for ii = length(self.items):-1:1
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, precedences(ii));
            end
            
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            expectedItems = {5, 4, 3, 2, 1};
            assertEqual(storedItems, expectedItems, 'insert order should not have mattered');
        end
        
        function testReplaceByMnemonic(self)
            mode = 'replacements';
            for ii = 1:length(self.items)
                self.mList.replaceItemInModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, -ii);
            end
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            assertEqual(storedItems, self.items, 'unexpected insert order');
            
            replacements = {10, 20, 30, 40, 50};
            for ii = 1:length(replacements)
                % omit precedence argument
                self.mList.replaceItemInModeWithMnemonicWithPrecedence ...
                    (replacements{ii}, mode, self.mnemonics{ii});
            end
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            assertEqual(storedItems, replacements, 'unexpected replacements')
        end
        
        function testCrazyPrecedenceValues(self)
            mode = 'crazy_insert';
            precedences = [-inf 0 2 inf nan];
            for ii = 1:length(self.items)
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, precedences(ii));
            end
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            expectedItems = {4, 3, 2, 1, 5};
            assertEqual(storedItems, expectedItems, 'unexpected crazy insert order')
        end
        
        function testRetrieveItemByMnemonic(self)
            mode = 'retrieval';
            for ii = 1:length(self.items)
                % omit precedence argument
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii});
            end
            
            for ii = 1:length(self.items)
                storedItem = self.mList.getItemFromModeWithMnemonic(mode, self.mnemonics{ii});
                assertEqual(storedItem, self.items{ii}, 'unexpected item retrieved');
            end
        end
        
        function testGenerateMnemonicStruct(self)
            mode = 'mnemonics';
            for ii = 1:length(self.items)
                % omit precedence argument
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, -ii);
            end
            
            storedMode = self.mList.getAllItemsFromModeWithMnemonics(mode);
            storedMnemonics = fieldnames(storedMode);
            assertEqual(storedMnemonics', self.mnemonics, 'unexpected struct mnemonics');
            storedItems = struct2cell(storedMode);
            assertEqual(storedItems', self.items, 'unexpected struct items');
        end
        
        function testRemoveByMnemonic(self)
            mode = 'remove';
            for ii = 1:length(self.items)
                % omit precedence argument
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, -ii);
            end
            
            % redundant removes should be safe
            self.mList.removeItemByMnemonicFromMode(self.mnemonics{1}, mode);
            self.mList.removeItemByMnemonicFromMode(self.mnemonics{2}, mode);
            self.mList.removeItemByMnemonicFromMode(self.mnemonics{2}, mode);
            self.mList.removeItemByMnemonicFromMode(self.mnemonics{1}, mode);
            
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            expectedItems = {3, 4, 5};
            assertEqual(storedItems, expectedItems, 'failed remove items by mnemonic');
        end
        
        function testRemoveByObject(self)
            mode = 'remove';
            for ii = 1:length(self.items)
                % omit precedence argument
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, -ii);
            end
            
            % redundant removes should be safe
            self.mList.removeItemFromMode(self.items{1}, mode);
            self.mList.removeItemFromMode(self.items{2}, mode);
            self.mList.removeItemFromMode(self.items{2}, mode);
            self.mList.removeItemFromMode(self.items{1}, mode);
            
            storedItems = self.mList.getAllItemsFromModeSorted(mode);
            expectedItems = {3, 4, 5};
            assertEqual(storedItems, expectedItems, 'failed remove items by object');
        end
        
        function testMergeModes(self)
            mode = 'merge_test';
            precedences = [1 2 3 4 5];
            for ii = 1:length(self.items)
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (self.items{ii}, mode, self.mnemonics{ii}, precedences(ii));
            end
            
            newMode = 'new_mode';
            newItems = {6 7 8 9 10};
            newMnemonics = {'six', 'seven', 'eight', 'nine', 'ten'};
            newPrecedences = [6 7 8 9 10];
            for ii = 1:length(newItems)
                self.mList.addItemToModeWithMnemonicWithPrecedence ...
                    (newItems{ii}, newMode, newMnemonics{ii}, newPrecedences(ii));
            end
            
            mergedMode = 'big_mode';
            self.mList.mergeModesIntoMode({mode, newMode}, mergedMode);
            
            storedItems = self.mList.getAllItemsFromModeSorted(mergedMode);
            expectedItems = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
            assertEqual(storedItems, expectedItems, 'failed merge modes in with correct order')
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.mList);
            n = length(props);
            for ii = 1:n
                self.mList.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.mList.(props{ii}) = self.mList.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end