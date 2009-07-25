function testTopsModalList

%% highest precedence should be at beginning of list
clear
list = topsModalList;
mode = 'regularInsert';
items = {1, 2, 3, 4, 5};
mnemonics = {'one', 'two', 'three', 'four', 'five'};
precedences = [-2 0 2 5 77];
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end
gotItems = list.getAllItemsFromModeSorted(mode);
expectedItems = {5, 4, 3, 2, 1};
assert(isequal(gotItems, expectedItems), 'unexpected insert order')

%% insertion order should not matter
clear
list = topsModalList;
mode = 'regularInsert';
items = {5, 4, 3, 2, 1};
mnemonics = {'five', 'four', 'three', 'two', 'one'};
precedences = [50 40 30 20 10];
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end
gotItems = list.getAllItemsFromModeSorted(mode);
expectedItems = {5, 4, 3, 2, 1};
assert(isequal(gotItems, expectedItems), 'unexpected insert order')

%% should handle nan and inf precedence
clear
list = topsModalList;
mode = 'crazyInsert';
items = {1, 2, 3, 4, 5};
mnemonics = {'one', 'two', 'three', 'four', 'five'};
precedences = [-inf 0 2 inf nan];
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end
gotItems = list.getAllItemsFromModeSorted(mode);
expectedItems = {4, 3, 2, 1, 5};
assert(isequal(gotItems, expectedItems), 'unexpected crazy insert order')

%% should get single items
clear
list = topsModalList;
mode = 'mnemonics';
items = {@disp, 'thingy', 443, nan, struct};
mnemonics = {'function', 'char', 'number', 'nan', 'struct'};
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii});
end
gotItems = list.getAllItemsFromModeByMnemonic(mode);

for ii = 1:length(items)
    item = list.getItemFromModeWithMnemonic(mode, mnemonics{ii});
    assert(isequalwithequalnans(item, items{ii}), ...
        'unexpected mnemonic structure field')
end

%% should generate mnemonic structure
clear
list = topsModalList;
mode = 'mnemonics';
items = {@disp, 'thingy', 443, nan, struct};
mnemonics = {'function', 'char', 'number', 'nan', 'struct'};
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii});
end
gotItems = list.getAllItemsFromModeByMnemonic(mode);

for ii = 1:length(items)
    assert(isequalwithequalnans(gotItems.(mnemonics{ii}), items{ii}), ...
        'unexpected mnemonic structure field')
end

%% should delete items by object or mnemonic
clear
list = topsModalList;
mode = 'delete';
items = {1, 2, 3, 4, 5};
mnemonics = {'one', 'two', 'three', 'four', 'five'};
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii});
end

% redundant should be OK
list.removeItemFromMode(items{1}, mode);
list.removeItemByMnemonicFromMode(mnemonics{1}, mode);
list.removeItemByMnemonicFromMode(mnemonics{2}, mode);
list.removeItemFromMode(items{2}, mode);

gotItems = list.getAllItemsFromModeSorted(mode);
expectedItems = {5, 4, 3};
assert(isequal(gotItems, expectedItems), 'failed remove items from mode')

%% should merge existing modes into new mode
clear
list = topsModalList;
mode = 'mode_one';
items = {1, 2, 3, 4, 5};
mnemonics = {'one', 'two', 'three', 'four', 'five'};
precedences = [-2 0 2 5 77];
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end

mode = 'mode_two';
items = {6 7 8 9 10};
mnemonics = {'six', 'seven', 'eight', 'nine', 'ten'};
precedences = [-2 0 2 5 77]+100;
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end

mergedMode = 'big_mode';
list.mergeModesIntoMode({'mode_one', 'mode_two'}, 'big_mode');

gotItems = list.getAllItemsFromModeSorted(mergedMode);
expectedItems = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
assert(isequal(gotItems, expectedItems), 'failed merge modes')

%% should post event when modes struct changes
clear
global eventCount
eventCount = 0;
list = topsModalList;
list.addlistener('modes', 'PostSet', @hearEvent);

mode = 'postEvents';
items = {1, 2, 3, 4, 5};
mnemonics = {'one', 'two', 'three', 'four', 'five'};
precedences = 1:5;
for ii = 1:length(items)
    list.addItemToModeWithMnemonicWithPrecedence ...
        (items{ii}, mode, mnemonics{ii}, precedences(ii));
end
assert(eventCount==ii, 'heard wrong number of set events')
clear global eventCount

function hearEvent(metaProp, event)
global eventCount
eventCount = eventCount + 1;