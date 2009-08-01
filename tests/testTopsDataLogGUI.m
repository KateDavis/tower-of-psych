function testTopsDataLogGUI


%% should automatically update list boxes with dataLog mnemonics
clear all
close all hidden
clear classes
clc

topsDataLog.flushAllData;
gui = topsDataLogGUI;

gotShown = get(gui.shownMnemonicsList, 'String');
assert(isempty(gotShown), 'list box should be empty')

gotTrigger = get(gui.shownMnemonicsList, 'String');
assert(isempty(gotTrigger), 'list box should be empty')

mnemonics = {'aaaa', 'bbbb', 'cccc'};
for m = mnemonics
    topsDataLog.logMnemonicWithData(m{1}, 1);
    drawnow;
end

gotShown = get(gui.shownMnemonicsList, 'String');
assert(isequal(gotShown, mnemonics'), 'list box should match mnemonics')

gotTrigger = get(gui.shownMnemonicsList, 'String');
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
set(gui.shownMnemonicsList, 'Value', [1 2 3]);
drawnow
topsDataLog.logMnemonicWithData('cccc', 1);
drawnow
selections = get(gui.shownMnemonicsList, 'Value');

delete(gui)
assert(isequal(selections, [1 2 4]), 'gui failed to manage selctions with new mnemonic')

%% drive the gui for a while
clear all
close all hidden
clear classes
clc

topsDataLog.flushAllData;
gui = topsDataLogGUI;

mnemonics = {'aaaa', 'bbbb', 'cccc'};
for m = repmat(mnemonics, 1, 10)
    topsDataLog.logMnemonicWithData(m{1}, 1);
    pause(1);
end

delete(gui)
