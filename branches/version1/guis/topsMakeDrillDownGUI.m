% GUI for "drilling down" into elements, fields, and properties of an item.
% @param item any item
% @param itemName string name to display for @a item
% @details
% Opens a new GUI figure for summarizing the given @a item and "driling
% down" to explore any elements, fields, and properties, to arbitrary
% depth.  If @a itemName is provided, displays @a itemName to represent @a
% item.
function fig = topsMakeDrillDownGUI(item, itemName)

if nargin < 2
    itemName = 'item';
end

% make a top-level figure with standard appearance and buttons
fig = topsFigure(sprintf('drill down for %s', itemName));

% make a panel to explore various sub-items
drillDownPan = topsDrillDownPanel(fig);

% make a panel to describe each selected sub-item
infoPan = topsInfoPanel(fig);

% add the panels to the GUI figure
fig.setPanels({drillDownPan, infoPan});

% show the given item
drillDownPan.setBaseItem(item, itemName);