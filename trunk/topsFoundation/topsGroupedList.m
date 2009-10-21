classdef topsGroupedList < handle
    properties (SetObservable)
        groups;
        length;
    end
    
    properties(Hidden)
        allGroupsMap;
    end
    
    events
        NewGroup;
        NewMnemonic;
    end
    
    methods
        function self = topsGroupedList
            self.length = 0;
        end
        
        function addItemToGroupWithMnemonic(self, item, group, mnemonic)
            % item is any Matlab variable
            % group is a string or number for grouping related items
            % mnemonic is a string or number to identifying the item
            %
            % For each topsGroupedList, group values must be all strings or
            % all numbers.  Likewise, for each group, mnemonics must be all
            % strings or all numbers.
            %
            % topsGroupedList posts NewGroup and NewMnemonic notifications
            % after new items are added.
            
            notifyGroup = true;
            notifyMnemonic = true;
            if isempty(self.allGroupsMap)
                % start from scratch
                groupMap = containers.Map(mnemonic, item, 'uniformValues', false);
                self.allGroupsMap = containers.Map(group, groupMap, 'uniformValues', false);
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
        
        function removeItemFromGroup(self, item, group)
            % removes all instances of item from group, along with
            % mnemonics
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
        
        function removeMnemonicFromGroup(self, mnemonic, group)
            % remove mnemonic from group, along with stored item
            if self.containsMnemonicInGroup(mnemonic, group)
                groupMap = self.allGroupsMap(group);
                groupMap.remove(mnemonic);
                self.length = self.length - 1;
            end
        end
        
        function removeGroup(self, group)
            % remove all items from the group, remove the group itself
            if self.containsGroup(group)
                groupMap = self.allGroupsMap(group);
                n = length(groupMap);
                groupMap.remove(groupMap.keys);
                self.allGroupsMap.remove(group);
                self.length = self.length - n;
            end
        end
        
        function mergeGroupsIntoGroup(self, sourceGroups, destinationGroup)
            % sourceGroups is a cell array of strings or numbers for
            % existing groups, to be merged together.
            % destinationGroup is a string or number for the group that
            % will contain the merger of sourceGroups.  destinationGroup
            % may or may not exist already.
            
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
        
        function item = getItemFromGroupWithMnemonic(self, group, mnemonic)
            % returns item stored in the given group, with the given
            % mnemonic
            if self.containsMnemonicInGroup(mnemonic, group)
                groupMap = self.allGroupsMap(group);
                item = groupMap(mnemonic);
            else
                item = [];
            end
        end
        
        function mnemonics = getAllMnemonicsFromGroup(self, group)
            % returns all mnemonics used in given group, sorted.
            if self.containsGroup(group)
                groupMap = self.allGroupsMap(group);
                mnemonics = groupMap.keys;
            else
                mnemonics = {};
            end
        end
        
        function [items, mnemonics] = getAllItemsFromGroup(self, group)
            % returns all items stored in given group, sorted by mnemonic
            % optionally returns corresponding sorted mnemonics
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
        
        function groupStruct = getAllItemsFromGroupAsStruct(self, group)
            % returns all items stored in a given group, in a struct array
            %
            %   groupStruct has one element per item in the given group.
            %   It has three fields: item, menemonic, and group.
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
        
        function isContained = containsGroup(self, group)
            isContained = isobject(self.allGroupsMap) ...
                && topsGroupedList.mapContainsKey(self.allGroupsMap, group);
        end
        
        function isContained = containsMnemonicInGroup(self, mnemonic, group)
            isContained = self.containsGroup(group) ...
                && topsGroupedList.mapContainsKey(self.allGroupsMap(group), mnemonic);
        end
        
        function isContained = containsItemInGroup(self, item, group)
            % searches group for item
            isContained = self.containsGroup(group) ...
                && topsGroupedList.mapContainsItem(self.allGroupsMap(group), item);
        end
        
        function g = get.groups(self)
            if isempty(self.allGroupsMap)
                g = {};
            else
                g = self.allGroupsMap.keys;
            end
        end
    end
    
    methods(Static)
        
        function isContained = mapContainsKey(map, key)
            if strcmp(map.KeyType, 'char')
                isContained = any(strcmp(map.keys, key));
            else
                keyCell = map.keys;
                k = [keyCell{:}];
                isContained = any(key==k);
            end
        end
        
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