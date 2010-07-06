classdef topsRunnable < topsFoundation
    % @class topsRunnable
    % Superclass for flow-control classes.
    % @details
    % The topsRunnable superclass provides a common interface for Tower
    % of Psych classes that manage flow control.  They organize function
    % calls and log what they call.  Some also "link up" with each other to
    % make complex control structures.
    % @details
    % Any topsRunnable can be run(), to begin executing a Tower of Psych
    % program.
    % @details
    % @ingroup foundation
    
    properties (SetObservable)
        % optional fevalable cell array to invoke just before running
        startFevalable = {};
        
        % optional fevalable cell array to invoke just after running
        finishFevalable = {};
        
        % true or false, whether this object is currently busy running
        isRunning = false;
    end
    
    events
        % notifyication just before run()
        RunStart;
        
        % notifyication just after run()
        RunFinish;
    end
    
    properties (Hidden)
        % string used for topsDataLog entry just before run()
        startString = 'start';
        
        % string used for topsDataLog entry just after run()
        finishString = 'finish';
    end
    
    methods
        % Constructor takes no arguments.
        % @details
        % Uses the class of this topsRunnable as the default name.
        function self = topsRunnable
            self.name = class(self);
        end
        
        % Do flow control.
        % @details
        % run() should take over flow-control from the caller and do custom
        % behaviors.  When it's done doing custom behaviors, the object
        % should set its isRunning property to false.
        % @details
        % Subclasses should redefine run() to do custom behaviors.
        function run(self)
        end
        
        % Launch a graphical interface for this runnable.
        function g = gui(self)
            g = [];
            disp(sprintf('make a gui for %s!', class(self)))
        end
        
        % Log an event of interest with topsDataLog.
        % @param actionName string name for any event of interest
        % @param actionData optional data to log along with @a actionName
        % @details
        % logAction is a convenient way to note in topsDataLog that some
        % event of interest has occurred.  The log entry will contain the
        % name of this topsRunnable object, concatenated with @a
        % actionName.  It will store @a actionData, if given.
        function logAction(self, actionName, actionData)
            if nargin < 3 || isempty(actionData)
                actionData = [];
            end
            group = sprintf('%s:%s', self.name, actionName);
            data = struct( ...
                'runnableClass', class(self), ...
                'runnableName', self.name, ...
                'actionName', actionName, ...
                'actionData', actionData);
            topsDataLog.logDataInGroup(data, group);
        end
        
        % Log a function call with topsDataLog.
        % @param fevalName string name to give to a function call
        % @param fevalable fevalable cell array specifying a function call
        % @details
        % logFeval is a convenient way to note in topsDataLog that some
        % funciton call of interest has occurred, and then call the
        % function.  The log entry will contain the name of this
        % topsRunnable object, concatenated with @a fevalName.  It will
        % store the function handle from the first element of @a fevalable.
        % @details
        % The log entry will not store any of the arguments from the second
        % or later elements of @a fevalable.  This is because the arguments
        % may be handle objects, and Matlab does a bad job of storing large
        % collections of handle objects--both in memory and in .mat files.
        % @details
        % After making a new entry in topsDataLog, logFeval also invokes @a
        % fevalable with the feval() function.
        function logFeval(self, fevalName, fevalable)
            if ~isempty(fevalable)
                group = sprintf('%s:%s', self.name, fevalName);
                data = struct( ...
                    'runnableClass', class(self), ...
                    'runnableName', self.name, ...
                    'fevalName', fevalName, ...
                    'fevalFunction', fevalable{1});
                topsDataLog.logDataInGroup(data, group);
                feval(fevalable{:});
            end
        end
    end
end
