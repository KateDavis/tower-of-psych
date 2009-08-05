function testTopsDataLogGUI


%% should automatically update list boxes with dataLog mnemonics
clear all
close all hidden
clear classes
clc

topsDataLog.flushAllData;
gui = topsDataLogGUI;

gotShown = get(gui.ignoredMnemonicsList, 'String');
assert(isempty(gotShown), 'list box should be empty')

gotTrigger = get(gui.ignoredMnemonicsList, 'String');
assert(isempty(gotTrigger), 'list box should be empty')

mnemonics = {'aaaa', 'bbbb', 'cccc'};
for m = mnemonics
    topsDataLog.logMnemonicWithData(m{1}, 1);
    drawnow;
end

gotShown = get(gui.ignoredMnemonicsList, 'String');
assert(isequal(gotShown, mnemonics'), 'list box should match mnemonics')

gotTrigger = get(gui.ignoredMnemonicsList, 'String');
assert(isequal(gotTrigger, mnemonics'), 'list box should match mnemonics')

delete(gui)


%% should fix list box selections when new mnemonics inserted
clear all
close all hidden
clear classes
clc

topsDataLog.flushAllData;
gui = topsDataLogGUI;

topsDataLog.logMnemonicWithData('aaaa', 1);
topsDataLog.logMnemonicWithData('bbbb', 1);
topsDataLog.logMnemonicWithData('dddd', 1);
set(gui.ignoredMnemonicsList, 'Value', [1 2 3]);
drawnow
topsDataLog.logMnemonicWithData('cccc', 1);
drawnow
selections = get(gui.ignoredMnemonicsList, 'Value');

delete(gui)
assert(isequal(selections, [1 2 4]), 'gui failed to manage selctions with new mnemonic')