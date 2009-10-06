classdef topsModalList < handle
    properties (SetObservable)
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
                % insert-sort into mode list by precedence
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
        
        function replaceItemInModeWithMnemonicWithPrecedence(self, ...
                item, mode, mnemonic, precedence);
            
            if isfield(self.modes, mode)
                modeItems = self.modes.(mode);
                selector = strcmp({modeItems.mnemonic}, mnemonic);
                if any(selector)
                    if nargin >= 5
                        modeItems(selector).precedence = precedence;
                    end
                    modeItems(selector).data = item;
                    self.modes.(mode) = modeItems;
                else
                    if nargin >= 5
                        self.addItemToModeWithMnemonicWithPrecedence( ...
                            item, mode, mnemonic, precedence);
                    else
                        self.addItemToModeWithMnemonicWithPrecedence( ...
                            item, mode, mnemonic);
                    end
                end
            else
                if nargin >= 5
                    self.addItemToModeWithMnemonicWithPrecedence( ...
                        item, mode, mnemonic, precedence);
                else
                    self.addItemToModeWithMnemonicWithPrecedence( ...
                        item, mode, mnemonic);
                end
                
            end
        end
        
        function mergeModesIntoMode(self, sourceModes, destinationMode)
            for m = sourceModes
                sourceItems = self.modes.(m{1});
                for ii = 1:length(sourceItems)
                    self.addItemToModeWithMnemonicWithPrecedence ...
                        (sourceItems(ii).data, ...
                        destinationMode, ...
                        sourceItems(ii).mnemonic, ...
                        sourceItems(ii).precedence);
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
        
        function item = getItemFromModeWithMnemonic(self, mode, mnemonic);
            if isfield(self.modes, mode)
                modeItems = self.modes.(mode);
                selector = strcmp({modeItems.mnemonic}, mnemonic);
                if any(selector)
                    item = modeItems(selector).data;
                else
                    item = [];
                end
            else
                item = [];
            end
        end
        
        function items = getAllItemsFromModeWithMnemonics(self, mode)
            modeItems = self.modes.(mode);
            items = cell2struct({modeItems.data}, {modeItems.mnemonic}, 2);
        end
        
        function items = getAllItemsFromModeSorted(self, mode)
            modeItems = self.modes.(mode);
            items = {modeItems.data};
        end
    end
end