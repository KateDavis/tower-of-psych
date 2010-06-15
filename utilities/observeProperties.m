% Visualize properties of a Matlab object
%
%   table = observeProperties(object, fig, position)
%
%   @param object a Matlab object whose properties are SetObservable
%   @param fig an optional Matlab figure for the visualization, default is
%   gcf().
%   @param position an optional [x y w h] rectangle within @a fig, for the
%   visualization
%
%   @details
%   Returns a handle to a new uitable that summarizes the properties of
%   the @a object.
%
%   Uses listeners to automatically update the visualization when the
%   properties of @a object change.  For example:
%
%   @code
%   tree = topsBlockTree;
%   table = observeProperties(tree);
%   tree.name = 'new name';
%   @endcode
%
%   The table should display the value 'new name'.
%   @ingroup utilities

function table = observeProperties(object, fig, position)
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
    value = summarizeValue(value);
end

function tableResize(fig, event, table)
set(table, 'Units', 'pixels');
pix = get(table, 'Position');
set(table, 'ColumnWidth', {pix(3)*.45, pix(3)*.45});
set(table, 'Units', 'normalized');