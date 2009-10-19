classdef TestTopsGroupedList < TestCase
    
    properties
        groupedList;
        items;
        stringGroups;
        numberGroups;
        stringMnemonics;
        numberMnemonics;
        eventCount;
    end
    
    methods
        function self = TestTopsGroupedList(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.groupedList = topsGroupedList;
            self.items = {@disp, 'some item', 55.3, containers.Map};
            self.stringGroups = {'a', 'b', 'c d e'};
            self.numberGroups = {-3.45, 1, 2};
            self.stringMnemonics = {'function handle', 'string', 'number', 'object'};
            self.numberMnemonics = {0, 2, -4, 66.567};
            self.eventCount = 0;
        end
        
        function tearDown(self)
            delete(self.groupedList);
            self.groupedList = [];
        end
        
        function addItemsToGroupWithMnemonics(self, items, group, mnemonics)
            for ii = 1:length(items)
                self.groupedList.addItemToGroupWithMnemonic(items{ii}, group, mnemonics{ii});
            end
        end
        
        function testSingleton(self)
            newList = topsGroupedList;
            assertFalse(self.groupedList==newList, 'topsGroupedList should not be a singleton');
        end
        
        function testAddStringGroupsStringMnemonics(self)
            % add same items to each group
            groups = self.stringGroups;
            mnemonics = self.stringMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            n = length(groups) * length(mnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            assertEqual(groups, self.groupedList.groups, 'wrong group identifiers');
        end
        
        function testAddNumberGroupsNumberMnemonics(self)
            % add same items to each group
            groups = self.numberGroups;
            mnemonics = self.numberMnemonics;
            for g = groups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, mnemonics);
            end
            n = length(groups) * length(mnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            assertEqual(groups, self.groupedList.groups, 'wrong group identifiers');
        end
        
        function testAddStringGroupsHeterogeneousMnemonics(self)
            % add string mnemonics to one group
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            % add number mnemonics to another group
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            n = length(self.stringMnemonics) + length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
        end
        
        function testRedundantAddDoesNoting(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'redundant add should have done nothing');
        end
        
        function testRemoveItem(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeItemFromGroup(self.items{1}, g);
            assertEqual(n-1, self.groupedList.length, 'should have removed 1 item');
        end
        
        function testRemoveMnemonic(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeMnemonicFromGroup(self.stringMnemonics{1}, g);
            assertEqual(n-1, self.groupedList.length, 'should have removed 1 item');
        end
        
        function testRemoveGroup(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            n = 2*length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            self.groupedList.removeGroup(self.stringGroups{1});
            n = length(self.stringMnemonics);
            assertEqual(n, self.groupedList.length, 'should have removed half the items');
            
            self.groupedList.removeGroup(self.stringGroups{1});
            assertEqual(n, self.groupedList.length, 'redundant remove should be OK');
            
            self.groupedList.removeGroup(self.stringGroups{2});
            assertEqual(0, self.groupedList.length, 'should have removed all items');
            
            assertTrue(isempty(self.groupedList.groups), 'should have removed all groups')
        end
        
        function testMergeGroups(self)
            % add same items to each group
            for g = self.numberGroups
                self.addItemsToGroupWithMnemonics(self.items, g{1}, self.numberMnemonics);
            end
            n = length(self.numberGroups) * length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'wrong number of items added');
            
            bigGroup = 100;
            self.groupedList.mergeGroupsIntoGroup(self.numberGroups, bigGroup);
            groups = self.groupedList.groups;
            assertEqual(sum([groups{:}]==bigGroup), 1, 'should have new, big group')
            n = n + length(self.numberMnemonics);
            assertEqual(n, self.groupedList.length, 'merge should have added items');
        end
        
        function testCantMergeHeterogeneousGroups(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            g = self.stringGroups{2};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            bigGroup = 'strings and numbers';
            f = @()self.groupedList.mergeGroupsIntoGroup(self.stringGroups(1:2), bigGroup);
            assertExceptionThrown(f, 'MATLAB:Containers:TypeMismatch');
        end
        
        function testContainsItems(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics( ...
                self.items, g, self.stringMnemonics);
            
            assertTrue(self.groupedList.containsGroup(g), ...
                'grouped list should contain group for newly added item');
            
            noG = self.stringGroups{2};
            assertFalse(self.groupedList.containsGroup(noG), ...
                'grouped list should not think it has bogus group');
            
            noM = 'bogus mnemonic';
            for m = self.stringMnemonics
                assertTrue(self.groupedList.containsMnemonicInGroup(m{1}, g), ...
                    'group should contain mnemonic for newly added item');
                
                assertFalse(self.groupedList.containsMnemonicInGroup(noM, g), ...
                    'group should not contain bogus mnemonic');
                
                assertFalse(self.groupedList.containsMnemonicInGroup(m{1}, noG), ...
                    'group should not contain mnemonic in bogus group');
            end
            
            noItem = 'bogus item';
            for item = self.items
                assertTrue(self.groupedList.containsItemInGroup(item{1}, g), ...
                    'group should contain newly added item');
                
                assertFalse(self.groupedList.containsItemInGroup(noItem, g), ...
                    'group should contain bogus item');
                
                assertFalse(self.groupedList.containsItemInGroup(item{1}, noG), ...
                    'group should not contain item in bogus group');
            end
        end
        
        function getItem(self)
            g = self.numberGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.numberMnemonics);
            
            for ii = 1:length(self.items)
                item = self.groupedList.getItemFromGroupWithMnemonic(...
                    g, self.numberMnemonics{ii});
                assertEqual(self.items{ii}, item, 'should get same item that was added');
            end
            
            noM = 'bogus mnemonic';
            item = self.groupedList.getItemFromGroupWithMnemonic(g, noM);
            assertEqual(isempty(item), 'should not get item for bogus mnemonic');
        end
        
        function testGetAllItems(self)
            g = self.stringGroups{1};
            self.addItemsToGroupWithMnemonics(self.items, g, self.stringMnemonics);
            
            items = self.groupedList.getAllItemsFromGroup(g);
            assertEqual(size(self.items), size(items), 'should get same number of items added to group')
            
            [items, mnemonics] = self.groupedList.getAllItemsFromGroup(g);
            assertEqual(size(self.items), size(items), 'should get same number of items added to group')
            assertEqual(size(self.stringMnemonics), size(mnemonics), 'should get same number of mnemonics added to group')
            
            for ii = 1:length(self.stringMnemonics)
                % look up returned items by mnemonics
                jj = strcmp(mnemonics, self.stringMnemonics{ii});
                assertEqual(sum(jj), 1, 'added and returned mnemonics should be 1:1')
                assertEqual(self.items{ii}, items{jj}, 'added and returned items should be 1:1')
            end
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.groupedList);
            n = length(props);
            for ii = 1:n
                self.groupedList.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.groupedList.(props{ii}) = self.groupedList.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end