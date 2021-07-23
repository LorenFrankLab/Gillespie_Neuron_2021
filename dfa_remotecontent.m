function out = dfa_remotecontent(index, excludeperiods, remdecodes, ripdecodes, trials, pos, varargin)
% sungod manu
%  adapted for the slightly different structure of remotedecodes vs ripdecodes

% define defaults
appendindex = 0;
box_thresh = .7; % proportion of posterior density in box to be considered box ripple
ripadjwin = .05; % in ms
% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);

if isempty(remdecodes) || length(remdecodes{d})< e || isempty(remdecodes{d}{e})
    out.riptsz = [];
    out.trips = [];   
    out.ripadjacent = [];
else
    
    q = remdecodes{d}{e};
    
    % extend rip windows by ripadjwin; exclude any rem events that have fall in that extended window
    extriptimes = [ripdecodes{d}{e}.riptimes(:,1)-ripadjwin, ripdecodes{d}{e}.riptimes(:,2)+ripadjwin];
    % find any window containing a rip start or end
    ripadjacent = isExcluded(q.starttime,extriptimes) | isExcluded(q.endtime,extriptimes);
    engulfedrips = logical(isExcluded(extriptimes(:,1),[q.starttime(~ripadjacent) q.endtime(~ripadjacent)])) ...
        & logical(isExcluded(extriptimes(:,2),[q.starttime(~ripadjacent) q.endtime(~ripadjacent)]));
    engulfingrems = lookup(extriptimes(engulfedrips,1),q.starttime,-1);
    ripadjacent(engulfingrems) = 1;
    switch excluderipadjacent
        case 1
            q.valid_states = q.valid_states(~ripadjacent,:);
            q.max_state = q.max_state(~ripadjacent,:);
            q.arm_prop = q.arm_prop(~ripadjacent,:);
            q.starttime = q.starttime(~ripadjacent);
            q.endtime = q.endtime(~ripadjacent);
        case -1
            q.valid_states = q.valid_states(ripadjacent,:);
            q.max_state = q.max_state(ripadjacent,:);
            q.arm_prop = q.arm_prop(ripadjacent,:);
            q.starttime = q.starttime(ripadjacent);
            q.endtime = q.endtime(ripadjacent);
        otherwise
    end
    out.ripadjacent = ripadjacent;
    
    % assign label to each ripple by classifier type
    riplabels(sum(q.valid_states,2)==0) = 0;  % no decode
    riplabels(q.valid_states(:,1)==1 & sum(q.valid_states,2)==1) = 1;  %cont
    riplabels(q.valid_states(:,2)==1 & sum(q.valid_states,2)==1) = 2;    % jumpy
    riplabels(q.valid_states(:,3)==1 & sum(q.valid_states,2)==1) = 3;        %hover
    riplabels(q.valid_states(:,1)==1 & q.valid_states(:,2)==1 & sum(q.valid_states,2)==2) = 4;   % cont+jumpy
    riplabels(q.valid_states(:,1)==1 & q.valid_states(:,3)==1 & sum(q.valid_states,2)==2) = 5;   % cont+hover
    riplabels(q.valid_states(:,2)==1 & q.valid_states(:,3)==1 & sum(q.valid_states,2)==2) = 6;   % jumpy +hover
    riplabels(sum(q.valid_states,2)==3) = 7; % all 3 >.8
    
    % assign label to each ripple by MAX classifier type
    ripmaxlabels(sum(q.max_state,2)==0) = 0;  % no decode
    ripmaxlabels(q.max_state(:,1)==1) = 1;  %cont
    ripmaxlabels(q.max_state(:,2)==1) = 2;    % jumpy
    ripmaxlabels(q.max_state(:,3)==1) = 3;        %hover
    
    box = q.arm_prop(:,1)>box_thresh;
    boxfrac = q.arm_prop(:,1);
    
    % label task phases of each trial (forage, goal, error...)
    valtrials = trials{d}{e}.leavehome>0;   % since lockouts are included, set xlim to exclude the zeros that come with lock trials
    nonlocktrials = valtrials & cellfun(@isempty,trials{d}{e}.lockstarts);
    taskphase = nan(length(trials{d}{e}.starttime),1);
    taskphase(find(nonlocktrials)) = label_trial_interval(trials{d}{e},(nonlocktrials));
    errortrials = mod(taskphase,1)>0;
    trips.taskphase = taskphase;
    trips.trialtype = trials{d}{e}.trialtype;
    trips.homewaitlength = trials{d}{e}.RWstart-trials{d}{e}.starttime;
    trips.RWwaitlength = trials{d}{e}.RWend-trials{d}{e}.RWstart;
    trips.postRWwaitlength = trials{d}{e}.leaveRW-trials{d}{e}.RWend;
    trips.outerwaitlength = trials{d}{e}.leaveouter-trials{d}{e}.outertime;
        
    % assign a trial phase to each ripple - good for overall stats only, nothing per-trial
    % 1=home 2=R 2.5=W 3=postR 3.5=postW 4=outerrewarded 5=outerunrew
    % only assign labels to rips during valid trials (nonlock)
    
    trialphaselabels = zeros(length(riplabels),1);
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.starttime(nonlocktrials), trials{d}{e}.RWstart(nonlocktrials)]))) = 1;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.RWstart(trials{d}{e}.trialtype==1 & nonlocktrials), trials{d}{e}.RWend(trials{d}{e}.trialtype==1 & nonlocktrials)]))) = 2;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.RWstart(trials{d}{e}.trialtype==2 & nonlocktrials), trials{d}{e}.RWend(trials{d}{e}.trialtype==2 & nonlocktrials)]))) = 2.5;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.RWend(trials{d}{e}.trialtype==1 & nonlocktrials), trials{d}{e}.leaveRW(trials{d}{e}.trialtype==1 & nonlocktrials)]))) = 3;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.RWend(trials{d}{e}.trialtype==2 & nonlocktrials), trials{d}{e}.leaveRW(trials{d}{e}.trialtype==2 & nonlocktrials)]))) = 3.5;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.outertime(trials{d}{e}.outersuccess==1 & nonlocktrials), trials{d}{e}.leaveouter(trials{d}{e}.outersuccess==1 & nonlocktrials)]))) = 4;
    trialphaselabels(logical(isExcluded(q.starttime,[trials{d}{e}.outertime(trials{d}{e}.outersuccess==0 & nonlocktrials), trials{d}{e}.leaveouter(trials{d}{e}.outersuccess==0 & nonlocktrials)]))) = 4.5;
    
    % fill in size column with zeros
    out.riptsz = [q.starttime, q.endtime, zeros(length(q.starttime),1), riplabels', ripmaxlabels', box, trialphaselabels, boxfrac];

    riplengths = q.endtime-q.starttime;
    % for each trial, determine rip types that occur in each phase
    %initialize with empty cells to keep size consistent
    trips.homeripsizes = cell(1,length(nonlocktrials));
    trips.homeriplengths = cell(1,length(nonlocktrials));
    trips.homeriptypes = cell(1,length(nonlocktrials));
    trips.homeripmaxtypes = cell(1,length(nonlocktrials));
    trips.homeripcontent = cell(1,length(nonlocktrials));
    trips.RWripsizes = cell(1,length(nonlocktrials));
    trips.RWriplengths = cell(1,length(nonlocktrials));
    trips.RWriptypes =  cell(1,length(nonlocktrials));
    trips.RWripmaxtypes =  cell(1,length(nonlocktrials));
    trips.RWripcontent = cell(1,length(nonlocktrials));
    trips.postRWripsizes = cell(1,length(nonlocktrials));
    trips.postRWriplengths = cell(1,length(nonlocktrials));
    trips.postRWriptypes = cell(1,length(nonlocktrials));
    trips.postRWripmaxtypes = cell(1,length(nonlocktrials));
    trips.postRWripcontent = cell(1,length(nonlocktrials));
    trips.outerripsizes = cell(1,length(nonlocktrials));
    trips.outerriplengths = cell(1,length(nonlocktrials));
    trips.outerriptypes = cell(1,length(nonlocktrials));
    trips.outerripmaxtypes = cell(1,length(nonlocktrials));
    trips.outerripcontent = cell(1,length(nonlocktrials));
    trips.RWripbins = cell(1,length(nonlocktrials));
    
    for t = find(nonlocktrials)'
        trips.homeripsizes{t} = out.riptsz(find(isExcluded(q.starttime,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)])),3);
        trips.homeriplengths{t} = riplengths(find(isExcluded(q.starttime,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)])));
        trips.homeriptypes{t} = riplabels(find(isExcluded(q.starttime,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)])));
        trips.homeripmaxtypes{t} = ripmaxlabels(find(isExcluded(q.starttime,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)])));
        trips.homeripcontent{t} = q.arm_prop(find(isExcluded(q.starttime,[trials{d}{e}.starttime(t), trials{d}{e}.RWstart(t)])),:);
        trips.RWripsizes{t} = out.riptsz(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])),3);
        trips.RWriplengths{t} = riplengths(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])));
        trips.RWriptypes{t} =  riplabels(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])));
        trips.RWripmaxtypes{t} =  ripmaxlabels(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])));
        trips.RWripcontent{t} = q.arm_prop(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])),:);
        trips.postRWripsizes{t} = out.riptsz(find(isExcluded(q.starttime,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)])),3);
        trips.postRWriplengths{t} = riplengths(find(isExcluded(q.starttime,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)])));
        trips.postRWriptypes{t} = riplabels(find(isExcluded(q.starttime,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)])));
        trips.postRWripmaxtypes{t} = ripmaxlabels(find(isExcluded(q.starttime,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)])));
        trips.postRWripcontent{t} = q.arm_prop(find(isExcluded(q.starttime,[trials{d}{e}.RWend(t), trials{d}{e}.leaveRW(t)])),:);
        trips.outerripsizes{t} = out.riptsz(find(isExcluded(q.starttime,[trials{d}{e}.outertime(t), trials{d}{e}.leaveouter(t)])),3);
        trips.outerriplengths{t} = riplengths(find(isExcluded(q.starttime,[trials{d}{e}.outertime(t), trials{d}{e}.leaveouter(t)])));
        trips.outerriptypes{t} = riplabels(find(isExcluded(q.starttime,[trials{d}{e}.outertime(t), trials{d}{e}.leaveouter(t)])));
        trips.outerripmaxtypes{t} = ripmaxlabels(find(isExcluded(q.starttime,[trials{d}{e}.outertime(t), trials{d}{e}.leaveouter(t)])));
        trips.outerripcontent{t} = q.arm_prop(find(isExcluded(q.starttime,[trials{d}{e}.outertime(t), trials{d}{e}.leaveouter(t)])),:);
        trips.RWripbins{t} = q.maxbins_per_seg(find(isExcluded(q.starttime,[trials{d}{e}.RWstart(t), trials{d}{e}.RWend(t)])),:);
        
    end
    
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
    % past_future_diff: Nan if lockout or following lockout, 1 if diff, 0 if same
    pfdiff = 10*ones(length(nonlocktrials),1); % initialize
    pfdiff(~nonlocktrials) = nan;
    pfdiff(nonlocktrials) = logical( outers ~= [0,outers(1:end-1)]);
    pfdiff(find(~nonlocktrials)+1) = nan;
    pfdiff = pfdiff(1:length(nonlocktrials));  % get rid of the extra entry that can be introduced by the previous step
    trips.pfdiff = pfdiff;
    
    ripstouse = logical(ones(length(riplabels),1));
    trialtimes = [trials{d}{e}.starttime(nonlocktrials), trials{d}{e}.RWstart(nonlocktrials)];
    %[trips.homecurrank, trips.homeprevrank, trips.homegoalrank, trips.homeshuff] = checkarmrank(q.arm_prop(ripstouse,2:end), riptsz(ripstouse,:), trials{d}{e}, nonlocktrials, trialtimes, converter,1);
    % keep record of length of contingency
    % home
    trips.homecontentcounts = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh,.5);
    trips.homerecencyscores = calcrecency(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, converter, .5);
    ripstouse = ripmaxlabels==1;
    trips.homecontentcounts_contmax = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    ripstouse = ripmaxlabels==3;
    trips.homecontentcounts_hovmax = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh,.3);
    % rw
    trialtimes = [trials{d}{e}.RWstart(nonlocktrials), trials{d}{e}.RWend(nonlocktrials)];
    ripstouse = logical(ones(length(riplabels),1));
    trips.rwcontentcounts = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .5);
    % calc recency score for each rip
    trips.rwrecencyscores = calcrecency(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, converter, .5);
    
    ripstouse = ripmaxlabels==1;
    trips.rwcontentcounts_contmax = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    ripstouse = ripmaxlabels==3;
    trips.rwcontentcounts_hovmax = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    
    %postrw
    trialtimes = [trials{d}{e}.RWend(nonlocktrials), trials{d}{e}.leaveRW(nonlocktrials)];
    ripstouse = logical(ones(length(riplabels),1));
    trips.postrwcontentcounts = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .5);
    ripstouse = ripmaxlabels==1;
    trips.postrwcontentcounts_contmax = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    ripstouse = ripmaxlabels==3;
    trips.postrwcontentcounts_hovmax = count_content_types(q.arm_prop(ripstouse,2:end),out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    trips.postrwrecencyscores = calcrecency(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, converter, .5);
    
    %combined allrw
    trialtimes = [trials{d}{e}.RWstart(nonlocktrials), trials{d}{e}.leaveRW(nonlocktrials)];
    ripstouse = logical(ones(length(riplabels),1));
    trips.allrwcontentcounts = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .5);
    trips.allrwcontentcounts_lowthresh = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .3);
    trips.allrwrecencyscores = calcrecency(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, converter, .5);
    
    %outer
    trialtimes = [trials{d}{e}.outertime(nonlocktrials), trials{d}{e}.leaveouter(nonlocktrials)];
    ripstouse = logical(ones(length(riplabels),1));
    trips.outercontentcounts = count_content_types(q.arm_prop(ripstouse,2:end), out.riptsz(ripstouse,1:3), trials{d}{e}, nonlocktrials, trialtimes, taskphase, converter, box_thresh, .5);
    %ripstouse = ripmaxlabels==1;
    %trips.outercontentcounts_contmax = count_content_types(q.arm_prop(ripstouse,2:end), riptsz(ripstouse,:), trials{d}{e}, nonlocktrials, trialtimes, converter, .3);
    %ripstouse = ripmaxlabels==3;
    %trips.outercontentcounts_hovmax = count_content_types(q.arm_prop(ripstouse,2:end), riptsz(ripstouse,:), trials{d}{e}, nonlocktrials, trialtimes, converter, .3);
     
    out.trips = trips;

end


if appendindex
    out.index = index;
end

end