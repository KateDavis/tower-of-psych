classdef topsFunctionLoop < topsGroupedList
    % @class topsFunctionLoop
    % Groups of functions doing concurrent behaviors.
    % topsFunctionLoop manages groups of functions that need to be called
    % over and over again.  This situation may come up when you need to do
    % things like draw graphics and check for inputs at the same time.
    % <br><br>
    % topsFunctionLoop is a subclass of topsGroupedList, which means it
    % has all the organization and capabilities of topsGroupedList, plus
    % more.
    % <br><br>
    % Thus, you must add each function to a "group" of functions that will
    % be run concurrently.  A group might correspond to a mode of
    % operatinon, such as 'reaction time trial'.  Instead of a mnemonic,
    % you must assign a "rank" to each function so that functions in each
    % group can be sorted.
    % <br><br>
    % topsFunctionLoop expects functions of a particular form, which it
    % calls "fevalable".  fevalables are cell arrays with a function handle
    % as the first element.  Any additional elements are treated as
    % arguments to the function.  Fevalables are executed with Matlab's
    % built-in feval() function--hence the name--so a cell array called foo
    % would be an fevalable if it could be executed with feval(foo{:}).
    % <br><br>
    % Besides the runForGroup() method, which actually executes
    % functions, topsFunctionLoop relies heavily on its superclass,
    % topsGroupedList.  For example, you may wish to build several groups
    % of functions, and then combine them in various ways.  To do this, you
    % would use the topsGroupedList method mergeGroupsIntoGroup().
    % <br><br>
    % topsFunctionLoop also has no graphical interface of its own (for
    % now).  Instead, the gui() method for a loop allows you to browse
    % through fevalables by group and rank, just as you would browse
    % through a list by group and mnemonic.
    % @ingroup foundation
    
    properties (SetObservable)
        % Any function that returns true (keep running functions) or false
        % (stop immediately).
        proceedFevalable = {};
        
        % Any function that returns the current time as a number.
        clockFunction = @topsTimer;
    end
    
    methods
        
        % Constructor takes no arguments
        function self = topsFunctionLoop
        end
        
        % Launch a graphical interface for this loop.
        % @param alternateFlag an optional hint for picking which interface
        % to use.
        % @details
        % For now, gui() always launches the generic topsGroupedListGUI, as
        % though you provided an @a alternateFlag with the value
        % 'asList' (see below).  In the future, gui() may launch a
        % different interface by default.
        % <br><br>
        % If you provide @a alternateFlag and it has the value
        % 'asList', then gui() will launch the generic topsGroupedListGUI,
        % which lets you browse functions in the loop by groups and ranks,
        % and shows details about each function.
        % <br><br>
        % Returns a handle to the new graphical interface,
        % topsGroupedListGUI.
        function g = gui(self, alternateFlag)
            if nargin > 1 && strcmp(alternateFlag, 'asList')
                g = topsGroupedListGUI(self);
            else
                g = topsGroupedListGUI(self);
            end
        end
        
        % Insert a function into the loop.
        % @param fcn a "fevalable" cell array containing a function handle
        % and arguments
        % @param group a string identifying a group of functions to be run
        % concurrently.
        % @param rank a number used to sort the functions in @a group
        % @details
        % inserts @a fcn among among other functions in
        % @a group based on @a rank.
        % <br><br>
        % Since topsFunctionLoop is a subclass of topsGroupedList,
        % adding functions to a loop is a lot like adding items to a list.
        % @a group is treated just like the groups in
        % topsGroupedList.  @a rank is treated as a numeric mnemonic
        % for the function item.
        function addFunctionToGroupWithRank(self, fcn, group, rank)
            assert(iscell(fcn), 'fcn argument should be a cell array');
            assert(ischar(group), 'group argument should be a string');
            assert(isnumeric(rank), 'rank argument should be numeric');
            self.addItemToGroupWithMnemonic(fcn, group, rank);
        end
        
        % Get all the functions for a loop group
        % @param group a string identifying a group of functions to be run
        % concurrently
        % @details
        % Returns all the "fevalable" cell arrays contained in
        % @a group, sorted by their ranks.
        % <br><br>
        % Optionally returns the ranks, as well.
        % <br><br>
        % Since topsFunctionLoop is a subclass of topsGroupedList,
        % getting a function list for a loop group is just like getting all
        % the items from a list group.  In fact, getAllItemsFromGroup is
        % equivalent to getFunctionListForGroup.  This method just provides
        % a name consistent with function loop terminology.
        function [functionList, ranks] = getFunctionListForGroup(self, group)
            if nargout > 1
                [functionList, ranks] = self.getAllItemsFromGroup(group);
            else
                functionList = self.getAllItemsFromGroup(group);
            end
        end
        
        % Loop through functions.
        % @param group a string identifying a group of functions to be run
        % concurrently
        % @param timeout optional maximum time to loop through functions,
        % in the same units as clockFunction.  Default is 0.
        % @details
        % Gets the list of functions for @a group and calls feval()
        % on each funcion in the list, in order, over and over again, until
        % @a timeout expires.
        % <br><br>
        % Makes complete passes through the function list.  So if @a
        % timeout expires in the middle of the loop, runForGroup() won't
        % return until reaching the bottom of the list.
        % <br><br>
        % As long as timeout is nonnegative, runForGroup() makes at least
        % one pass through the loop.
        % <br><br>
        % After each pass through the loop, runForGroup() checks the value
        % returned by proceedFevalable.  If the value is false, runForGroup()
        % returns immediately.
        function runForGroup(self, group, timeout)
            if nargin < 3 || isempty(timeout)
                timeout = 0;
            end
            
            functionList = self.getFunctionListForGroup(group);
            n = length(functionList);
            
            cf = self.clockFunction;
            if isempty(self.proceedFevalable)
                pf = {@true};
            else
                pf = self.proceedFevalable;
            end
            
            proceed = true;
            nowTime = feval(cf);
            endTime = nowTime + timeout;
            while (nowTime <= endTime) && proceed
                for ii = 1:n
                    feval(functionList{ii}{:});
                end
                nowTime = feval(cf);
                proceed = feval(pf{:});
            end
        end
    end
end