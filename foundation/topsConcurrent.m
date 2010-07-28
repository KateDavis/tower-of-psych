classdef topsConcurrent < topsRunnable
    % @class topsConcurrent
    % Superclass for flow-control classes that may operate concurrently.
    % @details
    % The topsConcurrent superclass provides a common interface for Tower
    % of Psych classes that manage flow control, and may work concurrently
    % with one another.
    % @details
    % In addition to being able to run(), topsConcurrent objects can also
    % runBriefly(), which means to carry out a small part of their normal run()
    % behavior and then return as soon as possible.  runBriefly() behaviors can
    % be interleaved to acheive concurrent operation of multiple
    % topsConcurrent objects within Matlab's single user-controled thread.
    % See the topsConcurrentComposite class for interleaving topsConcurrent 
    % objects.
    % @ingroup foundation
    
    properties (Hidden)
        % string used for topsDataLog entry just before runBriefly()
        runBrieflyString = 'runBriefly';
    end
    
    methods
        % Do flow control.
        % @details
        % topsConcurrent redefines the run() method of topsRunnable.  It
        % uses start(), finish(), and repeated calls to runBriefly() to
        % accomplish run() behaviors.  run() takes over flow-control from
        % the caller until isRunning becomes false.  It does not attempt to
        % return quickly.
        function run(self)
            self.start;
            while self.isRunning
                self.runBriefly;
            end
            self.finish;
        end
        
        % Do a little flow control and return as soon as possible.
        % @details
        % Subclasses should redefine runBriefly() to do specific run() behaviors,
        % a little at a time, and return as soon as possible.
        function runBriefly(self)
            self.isRunning = false;
        end
    end
end