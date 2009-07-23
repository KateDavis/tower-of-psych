function table = observeProperties(object)
%Observe properties of an object in a uitable
%
%   table = observeProperties(object)
%
%   table is a new uitable object that summarizes properties of the given
%   handle object.
%
%   object is any handle object whose public properties are
%   "SetObservable".
%
%   % should automatically update table with new tree name
%   tree = topsBlockTree;
%   table = observeProperties(tree);
%   tree.name = 'new name';

% 2009 by benjamin.heasly@gmail.com
%   Seattle, WA

props = properties(object);
n = length(props);
data = cell(n,2);
table = uitable;
for ii = 1:length(props)
    data(ii,1) = props(ii);
    data{ii,2} = makeTableReady(object.(props{ii}));
    callback = @(metaProp, event) updatePropTable(metaProp, event, table);
    object.addlistener(props(ii), 'PostSet', callback);
end
set(table, ...
    'Data', data, ...
    'Units', 'normalized', ...
    'Position', [.05, .05, .9, .9], ...
    'ColumnEditable', false, ...
    'ColumnName', {'property', 'value'}, ...
    'RowName', []);
set(get(table, 'Parent'), ...
    'ResizeFcn', {@tableResize, table}, ...
    'MenuBar', 'none', ...
    'ToolBar', 'none');
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

function tableResize(figure, event, table)
set(table, 'Units', 'pixels');
pix = get(table, 'Position');
set(table, 'ColumnWidth', {pix(3)*.45, pix(3)*.45});
set(table, 'Units', 'normalized');