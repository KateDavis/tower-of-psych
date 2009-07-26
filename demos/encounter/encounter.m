function [gameTree, gameList] = encounter
%Test/Demonstrate the Tower of Psych (tops) foundation classes in a game
%
%   Some goals for this demonstration:
%   - Should use all of the tops foundation classes
%   - Should be re-runnable with gameTree.run().
%   - Should live in as few files as possible (hmmm...)
%   - Should be a fun(ish) game to play
%   - Should produce a science-worthy, reproduceable record of conditions
%   and user/player responses.
%   - Should depend only on Matlab (i.e. not Psychtoolbox)
%
%   The game is somewhat like the battle sequences in the Final Fantasy
%   video games.  These sequences are good demonstrations of random
%   repeated conditions (c.f. topsBlockTree, topsModalList), and event
%   loops (c.f. topsFunctionLoop).  They also demonstrate a GUI and control
%   branching, which are left up to this program to define.
%
%   The user/player should control a set of characters through several
%   randomly selected battle sequences.  The game should end when the
%   player completes all the sequences (win) or all of the player's
%   characters die (lose).
%
%   For each battle sequence, there should be some number player-controled
%   characters vs. some number of monsters.  All characters and monsters
%   should have limited hit points and should damage each other by
%   attacking. A character or monster should die and leave play when its
%   hit points reach zero.  A battle sequence should end when either all
%   the monsters or all the players have died.
%
%   Each battle should begin with a consistent set of characters vs. a set
%   of monsters which was previously defined but randomly selected.
%   Character states should be preserved between encounters (i.e. they
%   should never get healed up) but monsters should be created fresh for
%   each encounter.
%
%   Each character and each monster should be inactive during most of each
%   sequence.  Each should periodically wake up.  When a monster wakes up,
%   it should randomly selct a character to attack and deal damage to, from
%   a random variable.  When a character wakes up, the user/player should
%   be able to select a monster for that character to attack.  Then the
%   character should attack that monster and deal it damage from a random
%   variable.
%
%   Monsters should be able to wake up and attack while the user/player is
%   performing selections.
%
%   When a character or monster is dealt damage, the damage amount should
%   be displayed for a short, controllable duration near the graphical
%   representation of the character or monster in the GUI.
%
%   The maximum and remining hit points of all the characters should always
%   be displayed.  The monster's hit points should be hidden.
%
%   Copyright 2009 by benjamin.heasly@gmail.com

% TOP-LEVEL CONCEPTS
%   figure with widgets in it (GUI)
%   character objects, in a set
%   Matlab figure mouse events
%       Need to serialize when multiple characters wake up at once...
%       separate queue: lock on character wake-up, unlock on mouse selection
%   It seems like the major currency is the fevalable cell array {@, ...}
%   The design habit is to define functions for narrow behaviors and let
%   the tree and loop integreate them and the list communicate for them

% BATTLE-LEVEL CONCEPTS
%   monster objects, in various sets
%   concurrent behaviors
%   user interaction
%   random conditions
%   resetting of battle sequence state

% EVENT LOOP
%   drawnow
%   tick battle timers
%   dispatch next queued battle event
%   check for battle sequence exit contitions

% TOP-LEVEL-BLOCK
%   create GUI
%   create event loop
%
%   create character group
%   load character group into GUI
%   create battle timer for each character, enqueue
%
%   create several groups of monsters
%   create several battle blocks

% BATTLE BLOCK
%   load monster group into GUI
%   create battle timer for each monster, enqueue
%   start event loop
%   clear monster group form gui
%   dequeue battle timer for each monster, destroy


% top-level data object, add arbitrary parameters
gameList = topsModalList;
nCharacters = 4;
nMonsterTypes = 3;
nMonsterGroups = 5;
maxMonsterGroupSize = nCharacters.^2;
gameList.addItemToModeWithMnemonicWithPrecedence(nCharacters, 'game', 'nCharacters');
gameList.addItemToModeWithMnemonicWithPrecedence(nMonsterTypes, 'game', 'nMonsterTypes');
gameList.addItemToModeWithMnemonicWithPrecedence(nMonsterGroups, 'game', 'nMonsterGroups');
gameList.addItemToModeWithMnemonicWithPrecedence(maxMonsterGroupSize, 'game', 'maxMonsterGroupSize');


% top-level control object
%   with functions defined below
gameTree = topsBlockTree;
gameTree.name = 'encounter';
gameTree.blockBeginFcn = {@gameSetup, gameList};
gameTree.blockEndFcn = {@gameTearDown, gameList};
gameList.addItemToModeWithMnemonicWithPrecedence(gameTree, 'game', 'gameTree');

% create characters, add to top-level data object
for ii = 1:nCharacters
    characters(ii) = battler;
    characters(ii).restoreHp;
    characters(ii).name = sprintf('nameless%d', ii);
end
gameList.addItemToModeWithMnemonicWithPrecedence(characters, 'game', 'characters');

% invent several types of monster
for ii = 1:nMonsterTypes
    monsters(ii) = battler(true);
    monsters(ii).attackMean = .1;
    monsters(ii).name = sprintf('evil%d', ii);
    monsters(ii).restoreHp;
end

% group monsters into several overlapping groups, add groups top-level data object
%   create a game subblock for each group, add to top-level control object
for ii = 1:nMonsterGroups
    nInGroup = ceil(rand*5);
    groupName = sprintf('baddies%d', ii);
    group = battler.empty;
    for jj = 1:nInGroup
        group(jj) = monsters(ceil(rand*nMonsterTypes)).copy;
    end
    gameList.addItemToModeWithMnemonicWithPrecedence(group, 'monsters', groupName);
    
    battleBlock = topsBlockTree;
    battleBlock.name = groupName;
    battleBlock.blockBeginFcn = {@battleSetup, battleBlock, gameList};
    battleBlock.blockActionFcn = {@battleGo, battleBlock, gameList};
    battleBlock.blockEndFcn = {@battleTearDown, battleBlock, gameList};
    gameTree.addChild(battleBlock);
end


function gameSetup(gameList)
% create the GUI
f = figure('MenuBar', 'none', 'ToolBar', 'none', ...
    'Name', 'Encounter!', 'NumberTitle', 'off');
gameList.addItemToModeWithMnemonicWithPrecedence(f, 'game', 'figure');

ax = axes('Parent', f, ...
    'Box', 'on', ...
    'XTick', [], 'YTick', [], ...
    'XLim', [0 1], 'YLim', [0 1], ...
    'Units', 'normalized', ...
    'Position', [.05 .475, .9, .5]);
gameList.addItemToModeWithMnemonicWithPrecedence(ax, 'game', 'axes');

% add characters to GUI
nChars = gameList.getItemFromModeWithMnemonic('game', 'nCharacters');
characters = gameList.getItemFromModeWithMnemonic('game', 'characters');
for ii = 1:nChars    
    axesPos = subposition([0 0 1 1], nChars, nChars+1, ii, nChars+1);
    characters(ii).makeGraphicsForAxesAtPositionWithCallback(ax, axesPos, []);
    
    figurePos = subposition([.05 .025, .9, .4], 2, ceil(nChars/2), ceil(ii/2), mod(ii-1, 2)+1);
    observeProperties(characters(ii), f, figurePos);
end


function battleSetup(battleBlock, gameList)
% position monsters in axes
groupName = battleBlock.name;
monsterGroup = gameList.getItemFromModeWithMnemonic('monsters', groupName);
nChars = gameList.getItemFromModeWithMnemonic('game', 'nCharacters');
ax = gameList.getItemFromModeWithMnemonic('game', 'axes');
for ii = 1:length(monsterGroup)
    monsterGroup(ii).restoreHp;
    axesPos = subposition([0 0 1 1], nChars, nChars+1, mod(ii-1, nChars)+1, ceil(ii/nChars));
    monsterGroup(ii).makeGraphicsForAxesAtPositionWithCallback(ax, axesPos, []);
end


function battleGo(battleBlock, gameList)
waitforbuttonpress


function battleTearDown(battleBlock, gameList)
% clear monster group from axes
groupName = battleBlock.name;
monsterGroup = gameList.getItemFromModeWithMnemonic('monsters', groupName);
for ii = 1:length(monsterGroup)
    monsterGroup(ii).deleteGraphics;
end


function gameTearDown(gameList)
characters = gameList.getItemFromModeWithMnemonic('game', 'characters');
nChars = gameList.getItemFromModeWithMnemonic('game', 'nCharacters');
for ii = 1:length(nChars)
    characters(ii).deleteGraphics;
end

f = gameList.getItemFromModeWithMnemonic('game', 'figure');
close(f)