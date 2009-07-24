function encounter
%Test/Demonstrate the Tower of Psych (tops) foundation classes in a game
%
%   Some goals for this demonstration:
%   - Should use all of the tops foundation classes
%   - Should live in as few files as possible
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
%   The remining hit points of all the characters should always ne
%   displayed.  The monster's hit points should be hidden.
%
%   Copyright 2009 by benjamin.heasly@gmail.com

% TOP-LEVEL CONCEPTS
% figure with widgets in it (GUI)
% character objects, in a set
% mouse or keyboard events

% BATTLE-LEVEL CONCEPTS
% monster objects, in various sets
% concurrent behaviors
% user interaction
% random conditions
% resetting of battle sequence state