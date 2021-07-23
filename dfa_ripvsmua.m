function out = dfa_ripvsmua(index, excludeperiods, ripdecodes, muadecodes,trials, pos, varargin)

%

% define defaults
appendindex = 0;
window = 0;
% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);

if isempty(ripdecodes) || length(ripdecodes{d})< e || isempty(ripdecodes{d}{e})
    out.fracmua_withoverlap = nan;
    out.fracrips_withoverlap = nan; 
    out.numrip_mua = [];
else
    muatimes = [muadecodes{d}{e}.riptimes(:,1)-window,muadecodes{d}{e}.riptimes(:,2)+window];  % add window buffer to one set of events
    riptimes = ripdecodes{d}{e}.riptimes;
    %how many muas overlap with rips?
    mua_overlapswrips = isExcluded(muatimes(:,1),riptimes) | isExcluded(muatimes(:,2),riptimes);
    engulfed = riptimes(logical(isExcluded(riptimes(:,1),muatimes(~mua_overlapswrips,:))),1); %starttimes of rips contained within remotes
    engulf_mua = lookup(engulfed,muatimes(:,1));
    mua_overlapswrips(engulf_mua) = 1;
    %how many rips overlap with mua?
    rip_overlapswmua = isExcluded(riptimes(:,1),muatimes) | isExcluded(riptimes(:,2),muatimes);
    engulfed = muatimes(logical(isExcluded(muatimes(:,1),riptimes(~rip_overlapswmua,:))),1);
    engulf_rips = lookup(engulfed,riptimes(:,1));
    rip_overlapswmua(engulf_rips) = 1;
    out.fracmua_withoverlap = sum(mua_overlapswrips)/length(mua_overlapswrips);
    out.fracrips_withoverlap = sum(rip_overlapswmua)/length(rip_overlapswmua);
    
    out.numrip_mua = [length(rip_overlapswmua), length(mua_overlapswrips)];
end


if appendindex
    out.index = index;
end

end