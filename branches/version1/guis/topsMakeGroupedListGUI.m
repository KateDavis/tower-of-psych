% GUI for browsing groups, mnemonics, and items of a topsGroupedList.
% @param groupedList a topsGroupedList object
% @details
% Opens a new GUI figure for summarizing the given @a gropedList.  Users
% can select a group and a mnemonic in order to view each item.
function fig = topsMakeGroupedListGUI(groupedList)

% make a top-level figure with standard appearance and buttons
fig = topsFigure(sprintf('browse %s', groupedList.name));
listPan = topsGroupedListPanel(fig);
infoPan = topsInfoPanel(fig);
fig.setPanels({infoPan; listPan}, [1 2], 1);

listPan.setGroupedList(groupedList);