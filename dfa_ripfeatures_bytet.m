function out = dfa_ripfeatures_bytet(index, excludeperiods, ripple, ripdecodes, marks, varargin)
% part 1 of ripfeatures: compute instantaneous ripple band frequency and # spikes during event per tetrode 
% output: per-tet riptsz equivalent [time instfreq numspikes]

%  Options:
%       appendindex-- Determines whether index is included in output vector
%           Default: 1

%parse the options
Fs = 1500;
appendindex = 1;
ripthresh = 2;

% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);
t = index(3); % use for indexing into the appropriate marks cell

if isempty(ripdecodes) || length(ripdecodes{d})< e || isempty(ripdecodes{d}{e})
    out.riptsz = [];
else
    
    q = ripdecodes{d}{e};
    
    % exclude events during mobility, calc instfreq of each
    immoevents = ~isExcluded(q.riptimes(:,1), excludeperiods) & ~isExcluded(q.riptimes(:,2), excludeperiods);
    overthresh = q.ripsizes>ripthresh;
    ripstarttimes = q.riptimes(immoevents & overthresh,1);
    ripendtimes = q.riptimes(immoevents & overthresh,2);
    
    eegtimesvec = geteegtimes(ripple{d}{e}{index(3)});
    startinds = lookup(ripstarttimes,eegtimesvec);
    endinds = lookup(ripendtimes,eegtimesvec);

    for r = 1:length(startinds)
        
        % Calculate distance between peaks of rip filtered data for each rip
        [pks, pkinds] = findpeaks(double(ripple{d}{e}{t}.data(startinds(r):endinds(r),1)));
        instfreq(r) = mean(Fs./diff(pkinds));
        
        % count number of marks on this tet during each rip
        spikenum(r) = sum(marks{d}{e}{t}.times>=ripstarttimes(r) & marks{d}{e}{t}.times<=ripendtimes(r));
    end
    
    out.riptsz = [ripstarttimes instfreq' spikenum'];
end

if appendindex
    out.index = index;
end

end