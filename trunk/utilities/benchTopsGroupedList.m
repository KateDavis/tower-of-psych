function benchTopsGroupedList(n, useStrings)
% Measure add, get, and remove times for topsDataLog
%   The type of item added matters a lot.
%   Access times for objects--even "value" objects are terrible and
%   increase with n.  The equivalent structs perform more like primitives.

if ~nargin || isempty(n)
    n = 1000;
end

if nargin > 1 && useStrings
    item = 'a';
    group = 'a';
    many = cell(1,n);
    for ii = 1:n
        many{ii} = sprintf('%d', ii);
    end
    label = 'using strings';
else
    item = 1;
    group = 1;
    many = num2cell(1:n);
    label = 'using numbers';
end


% add new groups
l = topsGroupedList;
times.groupAdd = zeros(1,n);
for ii = 1:n
    tic;
    l.addItemToGroupWithMnemonic(item, many{ii}, many{1});
    times.groupAdd(ii) = toc;
end

% access a whole group
times.groupAccess = zeros(1,n);
for ii = 1:n
    tic;
    [g,m] = l.getAllItemsFromGroup(many{ii});
    times.groupAccess(ii) = toc;
end

% remove a group
times.groupRemove = zeros(1,n);
for ii = 1:n
    tic;
    l.removeGroup(many{ii});
    times.groupRemove(n-ii+1) = toc;
end

% add items to a group
l = topsGroupedList;
times.itemAdd = zeros(1,n);
for ii = 1:n
    tic;
    l.addItemToGroupWithMnemonic(item, group, many{ii});
    times.itemAdd(ii) = toc;
end

% replace items in a group
l = topsGroupedList;
times.itemReplace = zeros(1,n);
for ii = 1:n
    tic;
    l.addItemToGroupWithMnemonic(item, group, many{ii});
    times.itemReplace(ii) = toc;
end

% access an item
times.itemAccess = zeros(1,n);
for ii = 1:n
    tic;
    i = l.getItemFromGroupWithMnemonic(group, many{ii});
    times.itemAccess(ii) = toc;
end

% remove an item by mnemonic
times.itemRemoveByMnemonic = zeros(1,n);
for ii = 1:n
    tic;
    l.removeMnemonicFromGroup(many{ii}, group);
    times.itemRemoveByMnemonic(n-ii+1) = toc;
end

% remove an item by value
for ii = 1:n
    l.addItemToGroupWithMnemonic(item, group, many{ii});
end
times.itemRemoveByValue = zeros(1,n);
for ii = 1:n
    tic;
    l.removeItemFromGroup(many{ii}, group);
    times.itemRemoveByValue(n-ii+1) = toc;
end

timeCell = struct2cell(times);
timeMat = cat(1, timeCell{:});
plot(timeMat');
%ylim([0, .005]);
xlabel(label);
legend(fieldnames(times), 'Location', 'NorthWest');