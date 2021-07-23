function out = dfa_noneventcontent(index, excludeperiods, rips, trials, pos, varargin)

%

% define defaults
appendindex=1;
velthresh = 4;
useclassifier = 0;
vers = 'lik';

% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);

post_path = sprintf('/mnt/stelmo/anna/%s/filterframework/decoding/',animal);

switch vers
    case 'lik'
        postfile = sprintf('%s%s_%d_%d_shuffle_0_likelihoods_v2.nc',post_path,animal,d,e);
        linposfile = sprintf('%s%s_%d_%d_shuffle_0_linearposition_v2.nc', post_path, animal, d, e); %
    case 'dec'
        postfile = sprintf('%s%s_%d_%d_shuffle_0_posterior_acausalv2_full2state.nc',post_path,animal,d,e);
        linposfile = sprintf('%s%s_%d_%d_shuffle_0_linearposition_v2.nc', post_path, animal, d, e); %
end

if exist(postfile) & exist(linposfile)
    disp(sprintf('decode results found for %s d%d e%d',animal, d, e));
    linpos = ncread(linposfile,'linpos_flat')+1;  % to compensate for python 0-based
    linvel = ncread(linposfile,'linvel_flat');
    linposts = ncread(linposfile,'time');
    if strcmp(vers,'dec')
        tmppost(:,:,1) = ncread(postfile,'state1_posterior'); %continuous
        tmppost(:,:,2) = ncread(postfile,'state2_posterior'); %fragmented
        posterior = sum(tmppost,3);
    else
        posterior = ncread(postfile,'posterior');
    end
    posteriorts = ncread(postfile,'time');
    
    % determine arm boundaries [gaps are even numbered segments]
    gapinds = find(nansum(posterior,2)==0);
    nongap = nansum(posterior(:,1:1000),2)>0;
    armstarts = [1; diff(nongap)==1];
    grps=cumsum(armstarts);
    grps(~nongap)=nan;
    
    if isempty(gapinds)| length(gapinds)>27
        warning('bad gaps detected; linearization is probably bad')
        out.trips = [];
    else
        kernel = gaussian(3,100);
        moveinds = logical(isExcluded(posteriorts,excludeperiods));
        
        for seg = 1:9
            armmean(seg,:) = mean(posterior(grps==seg,:));
            smoothed(seg,:) = smoothvect(armmean(seg,:),kernel);
            normed(seg,:) = (armmean(seg,:)-mean(armmean(seg,~moveinds)))./std(armmean(seg,~moveinds)); % normalize by immobility mean
        end
        % exclude rips during movement
        valrips = ~isExcluded(rips{d}{e}{1}.starttime, excludeperiods) & ~isExcluded(rips{d}{e}{1}.endtime, excludeperiods) & rips{d}{e}{1}.starttime>posteriorts(1) & rips{d}{e}{1}.endtime<posteriorts(end);
        % logicals for all times during rips in entire ep
        ripinds = isExcluded(posteriorts,[rips{d}{e}{1}.starttime(valrips) rips{d}{e}{1}.endtime(valrips)]);

        valtrials = trials{d}{e}.leavehome>0;   % since lockouts are included, set xlim to exclude the zeros that come with lock trials
        nonlocktrials = valtrials & cellfun(@isempty,trials{d}{e}.lockstarts);
        taskphase = nan(length(trials{d}{e}.starttime),1);
        taskphase(find(nonlocktrials)) = label_trial_interval(trials{d}{e},(nonlocktrials));
        errortrials = mod(taskphase,1)>0;
        trips.taskphase = taskphase;
        trips.trialtype = trials{d}{e}.trialtype;
        % content counts  [numrips #past #future #goal #other #box]
        converter(8:15) = fliplr([1:8]);
        outers = converter(trials{d}{e}.outerwell(nonlocktrials));  %translate from 8-15 to 1-8
        trips.outerarm = zeros(1,length(nonlocktrials));
        trips.outerarm(nonlocktrials) = outers;
        
        % calculate and store "previous" either previous valid trial (col1) or previous outer visit even if during lockout (col2)
        trips.prevarm = nan(length(nonlocktrials),2);
        trips.prevarm(nonlocktrials,1) = [0 outers(1:end-1)];
        lastlockouter(trials{d}{e}.locktype>0) = cellfun(@(x) x(find(x(:,2)>3,1,'last'),2),trials{d}{e}.duringlock(trials{d}{e}.locktype>0),'Un',0);
        trips.prevarm(nonlocktrials,2) = [0 outers(1:end-1)];
        if length(lastlockouter) == length(nonlocktrials) & ~isempty(lastlockouter{end})
            lastlockouter{end} = [];  % last trial was a lockout where he went out - discard this info bc will cause indexing error below
        end
        trips.prevarm(1+find(~cellfun(@isempty,lastlockouter)),2) = converter(cell2mat(lastlockouter(~cellfun(@isempty,lastlockouter))));
        
        % calculate and store goals/prevgoals
        nolockgoals = trials{d}{e}.goalwell(nonlocktrials);
        trips.goalarm = nan(length(nonlocktrials),3); %initialize [currgoal prevgoal preprevgoal]
        trips.contingency = nan(length(nonlocktrials),1); %initialize [currgoal prevgoal preprevgoal]
        goals(nolockgoals>0) = converter(nolockgoals(nolockgoals>0))';  %translate from 8-15 to 1-8
        goals(nolockgoals==0) = 0;
        if any(goals)
            goalbounds = [[1; 1+find(diff(goals')~=0)], [find(diff(goals')~=0); sum(nonlocktrials)]];
            if goalbounds(end,1)>sum(nonlocktrials)
                goalbounds(end,1)=sum(nonlocktrials);
            end
            eachgoal =goals(logical([1; diff(goals')~=0]));
            tmpgoals = nan(length(goals),2);
            for g = 1:length(eachgoal)
                ctemp(goalbounds(g,1):goalbounds(g,2)) = g;
                if g==2
                    tmpgoals(goalbounds(g,1):goalbounds(g,2),1) = eachgoal(1);
                elseif g>2
                    tmpgoals(goalbounds(g,1):goalbounds(g,2),1) = eachgoal(g-1);
                    tmpgoals(goalbounds(g,1):goalbounds(g,2),2) = eachgoal(g-2);
                end
            end
            trips.goalarm(nonlocktrials,:) = [goals',tmpgoals];
            trips.contingency(nonlocktrials) = [1 ctemp(1:end-1)];  % shifted by 1 since the goal change happens on the last trial of the cont
        end
        
        % for each trial, determine rip types that occur in each phase
        %initialize with empty cells to keep size consistent
        % for each phase seg x [mean_of_all; without_rips; rips only]  arm segs only!
        trips.homecontent = cell(1,length(nonlocktrials));
        trips.RWcontent = cell(1,length(nonlocktrials));
        trips.postRWcontent = cell(1,length(nonlocktrials));
        
        for t = find(nonlocktrials)'
            homeinds = logical(isExcluded(posteriorts,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)]));
            trips.homecontent{t} = [mean(armmean(:,homeinds),2)'; mean(armmean(:,homeinds & ~ripinds),2)'; mean(armmean(:,homeinds & ripinds),2)'];
            trips.homecontent_norm{t} = [mean(normed(:,homeinds),2)'; mean(normed(:,homeinds & ~ripinds),2)'; mean(normed(:,homeinds & ripinds),2)'];
            RWinds = logical(isExcluded(posteriorts,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)]));
            trips.RWcontent{t} = [mean(armmean(:,RWinds),2)'; mean(armmean(:,RWinds & ~ripinds),2)'; mean(armmean(:,RWinds & ripinds),2)'];
            trips.RWcontent_norm{t} = [mean(normed(:,RWinds),2)'; mean(normed(:,RWinds & ~ripinds),2)'; mean(normed(:,RWinds & ripinds),2)'];            
            postRWinds = logical(isExcluded(posteriorts,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)]));
            trips.postRWcontent{t} = [mean(armmean(:,postRWinds),2)'; mean(armmean(:,postRWinds & ~ripinds),2)'; mean(armmean(:,postRWinds & ripinds),2)'];
            trips.postRWcontent_norm{t} = [mean(normed(:,postRWinds),2)'; mean(normed(:,postRWinds & ~ripinds),2)'; mean(normed(:,postRWinds & ripinds),2)'];               
        end
        
        out.trips = trips;
        
    end
else
    out.trips = [];
end

if appendindex
    out.index = index;
end

end