function benchWriteMatFiles
% Time how .mat file overwriting time depends on double variable size.
%
% With Matlab 7.11.0.584 (R2010b) on a MACI64, overwrite time was quite
% linear.  This is not surprising.

filename = 'benchMat.mat';

sizes = floor(linspace(0, 1e8, 10));
n = numel(sizes);
times = zeros(1,n);
for ii = [1 1:n]
    clear('d');
    d = zeros(1,sizes(ii));
    tic;
    save(filename, 'd');
    times(ii) = toc;
    sizes(ii) = numel(d);
end

f = figure(543);
clf(f)
ax = axes( ...
    'Parent', f, ...
    'XLim', [min(sizes)-1, max(sizes) + 1], ...
    'XGrid', 'on', ...
    'YGrid', 'on');
xlabel(ax, 'numel of a double');
ylabel(ax, 'tic-toc save() time (s)');
line(sizes, times, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', '.');

delete(filename)