classdef topsFunctionLoop < topsGroupedList
    % @class topsFunctionLoop
    % A loop of functions doing concurrent behaviors.
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
    % Besides the runForGroupForDuration() method, which actually executes
    % functions, topsFunctionLoop relies heavily on its superclass,
    % topsGroupedList.  For example, you may wish to build several groups
    % of functions, and then combine them in various ways.  To do this, you
    % would use the topsGroupedList method mergeGroupsIntoGroup().
    % <br><br>
    % topsFunctionLoop also has no graphical interface of its own (for
    % now).  Instead, the gui() method for a loop allows you to browse
    % through fevalables by group and rank, just as you would browse
    % through a list by group and mnemonic.
    
    properties (SetObservable)
        % true or false, wheher the loop should keep running.
        proceed = true;
        
        % Any function that returns the current time as a number.
        clockFcn = @topsTimer;
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
        % though you provided an <em>alternateFlag</em> with the value
        % 'asList' (see below).  In the future, gui() may launch a
        % different interface by default.
        % <br><br>
        % If you provide <em>alternateFlag</em> and it has the value
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
        % @param rank a number used to sort the functions in <em>group</em>
        % @details
        % inserts <em>fcn</em> among among other functions in
        % <em>group</em> based on <em>rank</em>.
        % <br><br>
        % Since topsFunctionLoop is a subclass of topsGroupedList,
        % adding functions to a loop is a lot like adding items to a list.
        % <em>group</em> is treated just like the groups in
        % topsGroupedList.  <em>rank</em> is treated as a numeric mnemonic
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
        % <em>group</em>, sorted by their ranks.
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
        
        % Start looping through functions
        % @param group a string identifying a group of functions to be run
        % concurrently
        % @param duration the length of time to loop through functions, in
        % the same units as clockFcn.
        % @details
        % Gets the list of functions for <em>group</em> and calls feval()
        % on each funcion in the list, in order, over and over again, until
        % <em>duration</em> expires.
        % <br><br>
        % Always makes complete passes through the function list.  So if
        % <em>duration</em> expires in the middle of the loop, won't return
        % until reaching the bottom of the list.
        % <br><br>
        % If <em>duration</em> is missing or not finite, defaults to
        % duration = 0.  As long as duration >= 0, will make at least one
        % pass through the loop.
        % <br><br>
        % When the loop starts running, sets its proceed to true.  If a
        % functions in the list sets this flag to false, the loop will
        % abort immediately, without completing the current pass through
        % the function list.  To set the proceed flag, a function would
        % need to have access to this loop object, perhaps as an input
        % argument.
        function runForGroupForDuration(self, group, duration)
            if nargin < 3 || isempty(duration) || ~isfinite(duration)
                duration = 0;
            end
            
            functionList = self.getFunctionListForGroup(group);
            n = length(functionList);
            
            self.proceed = true;
            nowTime = feval(self.clockFcn);
            endTime = nowTime + duration;
            while (nowTime <= endTime)
                for ii = 1:n
                    feval(functionList{ii}{:});
                    if ~self.proceed
                        return
                    end
                end
                nowTime = feval(self.clockFcn);
            end
        end
    end
end