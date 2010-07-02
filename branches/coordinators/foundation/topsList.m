classdef topsList < handle
    % Simple list of items with indexes.
    % @details
    % The job of topsList is to hold items.  The user can add and remove
    % items and check whether items are already in the list.  The user may
    % deal item indexes or not.
    
    properties
        % cell array where list items are stored
        allItems;
        
        % number of items in the list
        length;
    end
    
    methods
        % Constructor takes no arguments.
        function self = topsList
            self.length = 0;
            self.allItems = {};
        end
        
        % Add an item to the list.
        % @param item any item to add to the list
        % @param index optional index where to insert @a item
        % @details
        % add() inserts @a item into the list at the given @a index.  If no
        % @a index is add() given, appends @a item to the end of the list.
        % @details
        % Returns the index into list array where @a item was inserted.
        function index = add(self, item, index)
            l = length(self.allItems) + 1;
            if nargin < 3 || isempty(index)
                index = l;
            end
            
            items = cell(1, l);
            selector = false(1, l);
            selector(index) = true;
            items{selector} = item;
            items(~selector) = self.allItems;
            
            self.allItems = items;
            self.length = length(self.allItems);
        end
        
        % Does the list conatin an item?
        % @param item any item that might be in the list
        % @details
        % Returns an array of list indexes for items that are
        % equal to the given @a item.  If no list items are equal to @a
        % item, returns [].
        % @details
        % Also returns, as an optional second output, a logical array which
        % is true where list items are equal to @a item.
        % @details
        % contains() compares items for equality using Matlab's built-in
        % eq() or isequal(), as appropriate.
        function [indexes, selector] = contains(self, item)
            if ismethod(item, 'eq')
                comparison = @eq;
            else
                comparison = @isequal;
            end
            
            selector = false(1, self.length);
            for ii = 1:self.length
                selector(ii) = feval(comparison, item, self.allItems{ii});
            end
            indexes = find(selector);
        end
        
        % Remove an item from the list.
        % @param item an item to remove from the list
        % @details
        % Removes all list items that are equal to the given @a item.
        % remove() uses contains() check for equality.
        function remove(self, item)
            [indexes, selector] = self.contains(item);
            self.allItems = self.allItems(~selector);
            self.length = length(self.allItems);
        end
    end
end