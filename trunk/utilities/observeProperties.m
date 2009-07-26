function table = observeProperties(object, fig, position)
%Observe properties of an object in a uitable
%
%   table = observeProperties(object, fig, position)
%
%   table is a new uitable object that summarizes properties of the given
%   handle object.
%
%   object is any handle object whose public properties are
%   "SetObservable".
%
%   fig is an optional figure that should be the 'Parent' of table.
%
%   position is an optional [x,y,w,h] array where to place table instide
%   its parent, with 'normalized' units.
%
%   % should automatically update table with new tree name
%   tree = topsBlockTree;
%   table = observeProperties(tree);
%   tree.name = 'new name';

% 2009 by benjamin.heasly@gmail.com
%   Seattle, WA

if nargin < 2 || isempty(fig)
    fig = figure('MenuBar', 'none', 'ToolBar', 'none');
end

if nargin < 3 || isempty(position)
    position = [.05, .05, .9, .9];
end

table = uitable('Parent', fig, ...
    'Units', 'normalized', ...
    'Position', position, ...
    'ColumnEditable', false, ...
    'ColumnName', {'property', 'value'}, ...
    'RowName', []);

props = properties(object);
n = length(props);
data = cell(n,2);
for ii = 1:length(props)
    data(ii,1) = props(ii);
    data{ii,2} = makeTableReady(object.(props{ii}));
    callback = @(metaProp, event) updatePropTable(metaProp, event, table);
    object.addlistener(props(ii), 'PostSet', callback);
end
set(table, 'Data', data);
set(fig, 'ResizeFcn', {@tableResize, table});
tableResize([], [], table);

function updatePropTable(metaProp, event, table)
data = get(table, 'Data');
rowSelector = strcmp(data(:,1), metaProp.Name);
if any(rowSelector)
    data{rowSelector,2} = makeTableReady(event.AffectedObject.(metaProp.Name));
end
set(table, 'Data', data);

function value = makeTableReady(value)
if ~isnumeric(value) && ~islogical(value) && ~ischar(value)
    value = stringifyValue(value);
end

function tableResize(fig, event, table)
set(table, 'Units', 'pixels');
pix = get(table, 'Position');
set(table, 'ColumnWidth', {pix(3)*.45, pix(3)*.45});
set(table, 'Units', 'normalized');