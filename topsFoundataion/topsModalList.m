classdef topsModalList < handle
    properties
        modes = struct();
    end
    
    methods
        function self = topsModalList

        end
        
        function addItemToModeWithMnemonicWithPrecedence(self, ...
                item, mode, mnemonic, precedence);
            if nargin < 5
                precedence = 0;
            end
            newModeItem = self.newModeItem(item, mnemonic, precedence);
            
            if isfield(self.modes, mode)
                % insert-sort into existing mode list
                %   need to do better than one-at-a time growth?
                modeItems = self.modes.(mode);
                for ii = length(modeItems):-1:1
                    if modeItems(ii).precedence <= precedence
                        modeItems(ii+1) = modeItems(ii);
                    else
                        modeItems(ii+1) = newModeItem;
                        break;
                    end
                end
                if modeItems(1).precedence <= precedence
                    modeItems(1) = newModeItem;
                end
                self.modes.(mode) = modeItems;
            else
                self.modes.(mode) = newModeItem;
            end
        end
        
        function mergeModesIntoNewMode(self, modes, newMode)
            for m = modes
                modeItems = self.modes.(m{1});
                for ii = 1:length(modeItems)
                    self.addItemToModeWithMnemonicWithPrecedence ...
                        (modeItems(ii).data, ...
                        newMode, ...
                        modeItems(ii).mnemonic, ...
                        modeItems(ii).precedence);
                end
            end
        end
        
        function removeItemFromMode(self, item, mode)
            if isfield(self.modes, mode)
                modeItems = self.modes.(mode);
                selector = logical(ones(1, length(modeItems)));
                for ii = 1:length(modeItems)
                    if isequal(modeItems(ii).data, item)
                        selector(ii) = false;
                        modeItems = modeItems(selector);
                        break;
                    end
                end
                self.modes.(mode) = modeItems;
            end
        end
        
        function removeItemByMnemonicFromMode(self, mnemonic, mode)
            if isfield(self.modes, mode)
                modeItems = self.modes.(mode);
                selector = logical(ones(1, length(modeItems)));
                for ii = 1:length(modeItems)
                    if strcmp(modeItems(ii).mnemonic, mnemonic)
                        selector(ii) = false;
                        modeItems = modeItems(selector);
                        break;
                    end
                end
                self.modes.(mode) = modeItems;
            end
            
        end
        
        function modeItem = newModeItem(self, item, mnemonic, precedence)
            modeItem.data = item;
            modeItem.mnemonic = mnemonic;
            modeItem.precedence = precedence;
        end
        
        function items = getSortedItemsForMode(self, mode)
            modeItems = self.modes.(mode);
            items = {modeItems.data};
        end
        
        function items = getItemsByMnemonicForMode(self, mode)
            modeItems = self.modes.(mode);
            items = cell2struct({modeItems.data}, {modeItems.mnemonic}, 2);
        end
    end
end