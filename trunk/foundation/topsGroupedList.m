classdef topsGroupedList < handle
    % @class topsGroupedList
    % A structured container for values and objects.
    % topsGroupedList is a general-purpose container for holding Matlab
    % values and objects, which it calls "items".  It has a two-tiered
    % structure: you must add items to "groups" of related items, and you
    % must give each item its own "mnemonic" which identifies it within a
    % group.
    % <br><br>
    % Groups and mnemonics can be strings or numbers.  So a topsGroupedList
    % is something like a struct (which uses strings) or cell array (which
    % uses numbers) that contains a bunch of other structs or cell arrays.
    % But it's more flexible and better organized than that. 
    % <br><br>
    % One way it's more flexible is in the values that a group or mnemonic
    % is allowed to have.  Groups and mnemonics can use arbitrary strings,
    % whereas structs cannot use strings that contain dots or spaces.
    % Similarly, groups and mnemonics can have arbitrary numeric values,
    % where as cell arrays must use positive integers.
    % <br><br>
    % There is one important constriant on groups and mnemonics: for each
    % instance of topsGroupedList, all groups must be identified by 
    % @a either strings @a or numbers, but not a mixture of the
    % two.  Likewise, the mnemonics used in each group must be all strings
    % or all numbers.
    % <br><br>
    % One way in which topsGroupedList is better organized than a random
    % collection of structs and cell arrays is that you can always "ask" it
    % what groups, mnemonics, and items it contains, and it knows where to
    % look for them.  You can also ask it @a if it contains a certain
    % group, mnemonic, or item.
    % <br><br>
    % The big idea is that you can neatly list whatever data and objects
    % you need for an experiment.  As long as you give the list to your
    % other functions and objects (as an argument, for example), they can
    % access all of your stuff.  Moreover, you can always view what's in
    % your list by using its gui() method.
    % @ingroup foundation
    
    properties (SetObservable)
        % Cell array of strings or numbers identifying all the groups in
        % the list.
        groups;
        
        % The number of items contained among all groups.
        length;
    end
    
    properties(Hidden)
        allGroupsMap;
    end
    
    events
        % Notifies any listeners after a new group was created.
        NewGroup;
        
        % Notifies any listeners after a new Mnemonic was added to a group,
        % and what group is was.
        NewMnemonic;
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsGroupedList
            self.length = 0;
        end
        
        % Launch a graphical interface for this list.
        % Returns a handle to the new topsGroupedListGUI
        function g = gui(self)
            g = topsGroupedListGUI(self);
        end
        
        % Add a new item to the list.
        % @param item any Matlab value or object
        % @param group a string or number that identifies a group of
        % related items
        % @param mnemonic a string or number to identify this new item
        % @details
        % If @a group and @a mnemonic are already in the list,
        % then @a item will overwrite an older item.  Otherwise,
        % after adding @a item, the list will send a NewGroup and/or
        % NewMnemonic notification to any listeners.
        % <br><br>
        % Note: for each topsGroupedList, group values must be all strings or
        % all numbers.  Likewise, for each group, mnemonics must be all
        % strings or all numbers.
        function addItemToGroupWithMnemonic(self, item, group, mnemonic)
            notifyGroup = true;
            notifyMnemonic = true;
            if isempty(self.allGroupsMap)
                % start from scratch
                groupMap = containers.Map(mnemonic, item, 'uniformValues', false);
                self.allGroupsMap = containers.Map(group, groupMap, 'uniformValues', false);
                self.groups = {group};
                self.length = 1;
            elseif self.containsGroup(group)
                % routine addition
                isNew = ~self.containsMnemonicInGroup(mnemonic, group);
                groupMap = self.allGroupsMap(group);
                groupMap(mnemonic) = item;
                self.length = self.length + isNew;
                
                notifyGroup = false;
                notifyMnemonic = isNew;
            else
                % new group
                groupMap = containers.Map(mnemonic, item, 'uniformValues', false);
                self.allGroupsMap(group) = groupMap;
                self.groups = self.allGroupsMap.keys;
                self.length = self.length + 1;
            end
            
            if notifyGroup
                self.notify('NewGroup', EventWithData(group));
            end
            
            if notifyMnemonic
                ed.item = item;
                ed.group = group;
                ed.mnemonic = mnemonic;
                self.notify('NewMnemonic', EventWithData(ed));
            end
        end
        
        % Remove all instances of an item from a group.
        % @param item the item to remove
        % @param group the group from which @a item should be removed
        % @details
        % Searches @a group for items that isequal() to
        % @a item.  Removes all such items, along with their
        % mnemonics.
        function removeItemFromGroup(self, item, group)
            if self.containsItemInGroup(item, group)
                groupMap = self.allGroupsMap(group);
                keys = groupMap.keys;
                isItem = logical(zeros(size(keys)));
                for ii = 1:length(keys)
                    isItem(ii) = isequal(groupMap(keys{ii}), item);
                end
                groupMap.remove(keys(isItem));
                self.length = self.length - sum(isItem);
            end
        end
        
        % Remove a mnemonic and its item from a group.
        % @param mnemonic the string or number identifying an item
        % @param group the group from which @a mnemonic, and its
        % item, should be removed
        % @details
        % Removes @a mnemonic and its item from @a group.
        function removeMnemonicFromGroup(self, mnemonic, group)
            if self.containsMnemonicInGroup(mnemonic, group)
                groupMap = self.allGroupsMap(group);
                groupMap.remove(mnemonic);
                self.length = self.length - 1;
            end
        end
        
        % Remove a whole group from the list.
        % @param group the string or number identifying the group to
        % remove
        % @details
        % Removes all mnemonics and items from @a group, then removes
        % @a group itself from the list.
        function removeGroup(self, group)
            if self.containsGroup(group)
                groupMap = self.allGroupsMap(group);
                n = length(groupMap);
                groupMap.remove(groupMap.keys);
                self.allGroupsMap.remove(group);
                self.length = self.length - n;
                self.groups = self.allGroupsMap.keys;
            end
        end
        
        % Combine multiple groups into another group.
        % @param sourceGroups cell array of strings or numbers identifying
        % groups to be merged.
        % @param destinationGroup string or number identifying a group that
        % will receive all the mnemonics and items from all of the source
        % groups.  @a destinationGroup may exist already, or not.
        % @details
        % Merging groups will probably result in redundant items being
        % stored in the list.  For example, imagine merging source groups A
        % and B into a new destination group C.  All of the original items
        % in A and B will then be held redundantly in C.  The length of the
        % list will increase, even though no new items were added.  So you
        % might wish to remove A and B after the merge.
        % <br><br>
        % An exception is when the destination group already exists and
        % uses some of the same mnemonics as the source groups.  In that
        % case, an item from a source group will overwrite any item in the
        % destination group that has the same mnemonic.  Thus, meging group
        % A into group A (itself) should have no effect.
        % <br><br>
        % Another exception is when the source groups share some mnemonics
        % among them.  In that case, groups listed later in
        % @a soureGroups will win out, and their items will overwrite
        % items from other groups that share the same mnemonics.
        function mergeGroupsIntoGroup(self, sourceGroups, destinationGroup)
            % could potentially do this in group-sized batches
            %   which would require additional accounting
            %   but might be faster
            for ii = 1:length(sourceGroups)
                if self.containsGroup(sourceGroups{ii})
                    sourceMap = self.allGroupsMap(sourceGroups{ii});
                    mnemonics = sourceMap.keys;
                    for jj = 1:length(mnemonics)
                        self.addItemToGroupWithMnemonic( ...
                            sourceMap(mnemonics{jj}), ...
                            destinationGroup, ...
                            mnemonics{jj});
                    end
                end
            end
        end
        
        % Get an item out of the list.
        % @param group the group containing the desired item
        % @param mnemonic the menemonic identifying the desired item
        % @details
        % Returns the item listed under @a group and
        % @a mnemonic.  If @a group isn't in the list, or
        % doesn't contain @a mnemonic, returns [].
        function item = getItemFromGroupWithMnemonic(self, group, mnemonic)
            if self.containsMnemonicInGroup(mnemonic, group)
                groupMap = self.allGroupsMap(group);
                item = groupMap(mnemonic);
            else
                item = [];
            end
        end
        
        % Get all mnemonics from a group.
        % @param group the group to get mnemonics for
        % @details
        % Returns a cell array containing all mnemonics from
        % @a group, or {} if @a group isn't in the list. The
        % mnemonics will be sorted alphabetically or numerically.
        function mnemonics = getAllMnemonicsFromGroup(self, group)
            if self.containsGroup(group)
                groupMap = self.allGroupsMap(group);
                mnemonics = groupMap.keys;
            else
                mnemonics = {};
            end
        end
        
        % Get all items (and optionally all mnemonics) from a group.
        % @param group the group to get items for
        % @details
        % Returns a cell array of all items from @a group.  If
        % @a group isn't in the list, returns {}.  Items will be
        % sorted  alphabetically or numerically, by mnemonic.
        % <br><br>
        % Optionally returns all mnemonics from @a group, as well.
        function [items, mnemonics] = getAllItemsFromGroup(self, group)
            if self.containsGroup(group)
                groupMap = self.allGroupsMap(group);
                items = groupMap.values;
                if nargout > 1
                    mnemonics = groupMap.keys;
                end
            else
                items = {};
                mnemonics = {};
            end
        end
        
        % Get all items from a group, as a struct array
        % @param group the group to get items for
        % @details
        % Returns a struct array with one element per item in
        % @a group.  Each struct element has three fields:
        %  - item -- the item itself
        %  - mnemonic -- the mnemonic for the item
        %  - group -- the string or number equal to @a group
        % .
        % If @a group isn't in the list, the struct array will have
        % zero length.
        function groupStruct = getAllItemsFromGroupAsStruct(self, group)
            if self.containsGroup(group)
                [items, mnemonics] = self.getAllItemsFromGroup(group);
                groupStruct = struct( ...
                    'item', items, ...
                    'mnemonic', mnemonics, ...
                    'group', group);
            else
                groupStruct = struct( ...
                    'item', {}, ...
                    'mnemonic', {}, ...
                    'group', {});
            end
        end
        
        % Does the list contain the given group?
        % @param group a string or number for a group that might be in the
        % list
        % @details
        % Returns true if the list contains @a group.  Otherwise
        % returns false. 
        function isContained = containsGroup(self, group)
            if ischar(group)
                isContained = any(strcmp(self.groups, group));
            else
                isContained = any(group == [self.groups{:}]);
            end
        end
        
        % Does the list contain the given group and mnemonic?
        % @param mnemonic a string or number for a menemonic that might be in
        % @a group
        % @param group a string or number for a group that might be in the
        % list
        % @details
        % Returns true if the list contains @a group and
        % @a group contains @a mnemonic.  Otherwise returns
        % false. 
        function isContained = containsMnemonicInGroup(self, mnemonic, group)
            isContained = self.containsGroup(group) ...
                && topsGroupedList.mapContainsKey(self.allGroupsMap(group), mnemonic);
        end
        
        % Does the list contain the given group and item?
        % @param item a value or object that might be in @a group
        % @param group a string or number for a group that might be in the
        % list
        % @details
        % Searches @a group for any occurence of @a item.
        % Returns true if the list contains @a group and
        % @a group contains at least on item that isequal() to 
        % @a item. Otherwise returns false.
        function isContained = containsItemInGroup(self, item, group)
            isContained = self.containsGroup(group) ...
                && topsGroupedList.mapContainsItem(self.allGroupsMap(group), item);
        end
    end
    
    methods(Static)
        
        % Does the containers.Map contain the given key?
        % @param map an instance of containers.Map
        % @param key string or number that might be a key in the map
        % @details
        % Returns true if the map contains the @a key. Otherwise
        % returns false.
        function isContained = mapContainsKey(map, key)
            if ischar(key)
                isContained = any(strcmp(map.keys, key));
            else
                keyCell = map.keys;
                isContained = any(key == [keyCell{:}]);
            end
        end
        
        % Does the containers.Map contain the given item?
        % @param map an instance of containers.Map
        % @param item a value or object that might be in the map
        % @details
        % Searches the map for the @a item.  Returns true if any
        % value in @a map isequal() to @a item.  Otherwise
        % returns false.
        function isContained = mapContainsItem(map, item)
            isContained = false;
            items = map.values;
            for ii = 1:length(items)
                if isequal(items{ii}, item)
                    isContained = true;
                    break
                end
            end
        end
    end
end