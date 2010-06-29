% A stopwatch for Tower of Psych, based on tic() and toc().
%
% t = topsClock
%
% @details
% Returns the time in seconds since topsClock() was first called.
% topsClock() uses a private instance of Matlab's builtin tic()-toc()
% stopwatch.
%
% See also, tic, toc, now, cputime
% @ingroup utilities

function t = topsClock

persistent topsTic
if isempty(topsTic)
    topsTic = tic;
end
t = toc(topsTic);

% I'd like to just use the built-in @now as the timer, for tops.  But @now
% returns very large values, in units of days.  The days are not a problem
% per se, since tops is supposed to handle any timer function.  But the
% very large values cause Matlab to to idiotic plotting: it sometimes
% ignores 'YLim' axes values that I set and instead squish my plots.  Which
% is idiotic.
end