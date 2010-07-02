classdef topsSteppable < topsRunnable
    % @class topsSteppable
    % Superclass for flow-control classes that may operate concurrently.
    % @details
    % The topsSteppable superclass provides a common interface for Tower
    % of Psych classes that manage flow control, and may work concurrently
    % with one another.
    % @details
    % In addition to being able to run(), topsSteppable objects can also
    % step(), which means to carry out a small part of their normal run()
    % behavior and then return as soon as possible.  Stepping behaviors can
    % be interleaved to acheive concurrent operation of multiple
    % topsSteppable objects within Matlab's single user-controled thread.
    % @ingroup foundation
    
    properties (Hidden)
        % string used for topsDataLog entry just before step()
        stepString = 'step';
    end
    
    methods
        % Do flow control.
        % @details
        % topsSteppable redefines the run() method of topsRunnable.  It
        % uses start(), finish(), and repeated calls to step() to
        % accomplish run() behaviors.  run() takes over flow-control from
        % the caller until isRunning becomes false.  It does not attempt to
        % return quickly.
        function run(self)
            self.start;
            while self.isRunning
                self.step;
            end
            self.finish;
        end
        
        % Do a little flow control and return as soon as possible.
        % @details
        % Subclasses redefine step to do specific run() behaviors, a little
        % at a time, and return as soon as possible.
        function step(self)
        end
        
        % Prepare to do flow control.
        % @details
        % Subclasses should extend start() to do initialization before
        % running.
        function start(self)
            self.logAction(self.startString);
            self.logFeval(self.startString, self.startFevalable);
            self.isRunning = true;
        end
        
        % Finish doing flow control.
        % @details
        % Subclasses should extend finish() to do clean up after running.
        function finish(self)
            self.logAction(self.finishString);
            self.logFeval(self.finishString, self.finishFevalable);
            self.isRunning = false;
        end
    end
end