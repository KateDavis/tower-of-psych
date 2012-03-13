% A clock function based on Matlab's built in tic() and toc().
%
% t = topsClock
%
% @details
% Returns the time in seconds since topsClock() was first called.
% topsClock() uses a private instance of Matlab's builtin tic()-toc()
% stopwatch.
%
% See also, tic, toc
%
% @ingroup utilities
function t = topsClock

persistent topsTic
if isempty(topsTic)
    topsTic = tic;
end

t = toc(topsTic);