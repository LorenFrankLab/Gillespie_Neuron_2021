function [bincentertimes, muatrace] = getMUAtrace(spikestruct, eptimerange, varargin)
% 
% OLD: used an eegtrace for geteegtimes to calculate timebins and to take into account any nan periods 
% NEW: pass in timerange of the ep and and nan inds (this eliminates the big eeg requirement; can get this info from ripplekons instead

% compiles spike times across tetrodes 
% bins and counts events per bin
% smooths with 15ms gaussian kernel

timebin = .002;
smoothingwidth = .005; % 15ms kernel width

if (~isempty(varargin))
    assign(varargin{:});
end

kernel = gaussian(smoothingwidth/timebin, 100);  
naninds = [];

spiketimes = cellfun(@(x) x.times,spikestruct,'UniformOutput',0);
% concatenate times from all tetrodes, then reorder
spiketimes = sort(vertcat(spiketimes{:}));

% generate histogram
%eegtimes = geteegtimes(eegtrace);
%edges = eegtimes(1):timebin:eegtimes(end);
edges = eptimerange(1):timebin:eptimerange(2);
spikecounts = histcounts(spiketimes,edges);

% smooth the resultant histogram
smoothed = smoothvect(spikecounts, kernel);

% strategy below doesnt work bs eegtimes not same inds as muatimes
% % identify any nan times
% %naninds = find(isnan(eegtrace.data));
% [lo,hi]= findcontiguous(naninds);  %find contiguous NaNs
% if ~isempty(lo)
%     warning('nans in MUA!')
%     lo = lo-smoothingwidth;
%     hi = hi+smoothingwidth; % get rid of times where smoothing edge effects will be
%     nonans = logical(list2vec([lo hi],edges(1:end-1)));
% else
%     nonans = logical(ones(length(edges)-1,1));
% end
% 
% %if there are any nans, nan out the smoothing edge effects they will have had
% smoothed(~nonans) = nan;

bincentertimes = edges(1:end-1) + timebin/2;
muatrace = smoothed;

end