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
        startFevalable;
        
        % optional fevalable cell array to invoke just after running
        finishFevalable;
        
        % true or false, whether this object is currently busy running
        isRunnning;
    end
    
    properties (Hidden)
        % string used for topsDataLog entry just before run()
        startString = 'start';
        
        % string used for topsDataLog entry just after run()
        finishString = 'finish';
    end
    
    methods
        % Do flow control.
        % @details
        % run() should take over flow-control from the caller and do custom
        % behaviors until isRunning becomes false.  It need not attempt to
        % return quickly.
        % @details
        % Subclasses should redefine run() to do custom behaviors.
        function run(self)
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
            topsDataLog.logDataInGroup(actionData, group);
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
                topsDataLog.logDataInGroup(fevalable{1}, group);
                feval(fevalable{:});
            end
        end
    end
end
