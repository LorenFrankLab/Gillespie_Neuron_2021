function out = dfa_plotripcontent(index, excludeperiods, remdecodes, ripdecodes,trials, varargin)

%

% define defaults
appendindex = 0;
box_thresh = .9; % proportion of posterior density in box to be considered box ripple
armthresh = .5;
v=1; 
posterior = 0;
tet=[];
span = 'full'; % vs rips
% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);
post_path = '/mnt/stelmo/anna/'; 
switch v
    case 3 
    linposfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_linearposition_v2.nc', post_path, animal,animal, d, e); 
    postfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_posterior_acausalv2_full2state.nc', post_path, animal,animal, d, e); 
    case 2
    linposfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_linearposition_v2.nc', post_path, animal,animal, d, e); 
    postfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_posterior_acausal_v2.nc', post_path, animal,animal, d, e); 
    otherwise %v1
    linposfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_linearposition.nc', post_path, animal, d, e); 
    postfile = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_posterior_acausal.nc', post_path, animal,animal, d, e); 
end

if posterior  % only load if required
    postposbins = 1+ncread(postfile,'position');
    acausal_post(:,:,1) = ncread(postfile,'state1_posterior'); %causal
    acausal_post(:,:,2) = ncread(postfile,'state2_posterior'); %causal  state2_
    acausal_post(:,:,3) = ncread(postfile,'state3_posterior'); %causal
    posteriorts = ncread(postfile,'time');
    post_combined = sum(acausal_post,3); 
    classifiercurves = [sum(acausal_post(:,:,1),1); sum(acausal_post(:,:,2),1)];
    if v<3 % need to also load non-classifier for movemnt times and stitch together
        postfile2 = sprintf('%s%s/filterframework/decoding/%s_%d_%d_shuffle_0_posteriors_v2.nc', post_path, animal,animal, d, e); 
        v2posterior = ncread(postfile2,'posterior');
        nanrows = isnan(v2posterior(:,1));
        post_combined(nanrows,:) = nan;
        v2cols = post_combined(1,:)>0;
        v2posterior(:,v2cols) = post_combined(:,v2cols);
        post_combined = v2posterior;
        clear v2posterior v2cols
    end
    clear acausal_post
end

if isempty(remdecodes) || length(remdecodes{d})< e || isempty(remdecodes{d}{e}) || ~exist(linposfile)
    out.success = 0;  
else
  out.success=1;  
  linpos = ncread(linposfile,'linpos_flat')+1;
  linvel = ncread(linposfile,'linvel_flat');
  linposts = ncread(linposfile,'time');
  
  
    q = remdecodes{d}{e};
    q.riptimes = [q.starttime, q.endtime];
        
    % generate a list of all riptimes, maxarm, amt content
    [maxpost,maxseg] = max(q.arm_prop');  
    maxseg = maxseg-1;  % adjust so that box = 0 and arms are 1-8

    %% what do those rips represent?
    valtrials = trials{d}{e}.leavehome>0;   % since lockouts are included, set xlim to exclude the zeros that come with lock trials
    nonlocktrials = valtrials & cellfun(@isempty,trials{d}{e}.lockstarts);
    converter(8:15) = fliplr([1:8]);
    outers = converter(trials{d}{e}.outerwell(nonlocktrials));  %translate from 8-15 to 1-8
    outerarm = nan(1,length(nonlocktrials));
    outerarm(nonlocktrials) = outers;
    % calculate and store "previous" - outer visit even if during lockout 
    prevarm = nan(length(nonlocktrials),1);
    prevarm(nonlocktrials) = [0 outers(1:end-1)];
    lastlockouter(trials{d}{e}.locktype>0) = cellfun(@(x) x(find(x(:,2)>3,1,'last'),2),trials{d}{e}.duringlock(trials{d}{e}.locktype>0),'Un',0);
    if length(lastlockouter) == length(nonlocktrials) & ~isempty(lastlockouter{end})  
        lastlockouter{end} = [];  % last trial was a lockout where he went out - discard this info bc will cause indexing error below
    end
    prevarm(1+find(~cellfun(@isempty,lastlockouter))) = converter(cell2mat(lastlockouter(~cellfun(@isempty,lastlockouter))));
    
    % calculate and store goals/prevgoals                                                           
    nolockgoals = trials{d}{e}.goalwell(nonlocktrials);
    goalarm = nan(length(nonlocktrials),3); %initialize [currgoal prevgoal preprevgoal]
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
            if g==2
                tmpgoals(goalbounds(g,1):goalbounds(g,2),1) = eachgoal(1);
            elseif g>2
                tmpgoals(goalbounds(g,1):goalbounds(g,2),1) = eachgoal(g-1);
                tmpgoals(goalbounds(g,1):goalbounds(g,2),2) = eachgoal(g-2);
            end
        end
        goalarm(nonlocktrials,:) = [goals',tmpgoals];
    end
    
    % assign each ripple to a trial
    riptrials = zeros(length(maxpost),1);
    for tr = 1:length(valtrials)
        intrial = find(isExcluded(q.riptimes(:,1),[trials{d}{e}.starttime(tr) trials{d}{e}.endtime(tr)]));
        riptrials(intrial) = tr;
    end
    
    armlist = [outerarm(riptrials)',prevarm(riptrials),goalarm(riptrials,:)];  %[future past currgoal prevgoal prevprevgoal]
    
    valtrials = trials{d}{e}.leavehome>0 & cellfun(@isempty,trials{d}{e}.lockstarts);
    taskphase = nan(length(trials{d}{e}.starttime),1);
    taskphase(find(valtrials)) = label_trial_interval(trials{d}{e},(valtrials));
    %% generate plot
    epstart = linposts(1);
    epend = linposts(end);
    
    % correct for uneven gaps between segments
    nodatarows = sum(post_combined(:,1:100),2)==0;
    correction = cumsum(nodatarows);
    linposcorr = double(linpos)-correction(linpos);
    bounds = .5+find(diff(correction(~nodatarows))>0);
    
    figure; hold on; set(gcf,'Position',[109 19 1788 756]);
    switch span
        case 'full'
            % load eeg data and plot if specified
            if ~isempty(tet)
                ax1=subplot(6,1,[2 3]); hold on;
                patch([q.riptimes'; fliplr(q.riptimes)'],repmat([-1000 -1000 1000 1000]',1,length(maxseg)),'k','FaceAlpha',.1,'EdgeColor','none');
                patch([ripdecodes{d}{e}.riptimes'; fliplr(ripdecodes{d}{e}.riptimes)'],repmat([-1000 -1000 1000 1000]',1,size(ripdecodes{d}{e}.riptimes,1)),'r','FaceAlpha',.1,'EdgeColor','none');
                plot(q.riptimes(q.max_state(:,1),1),-1000*ones(1,sum(q.max_state(:,1))),'b.');
                plot(q.riptimes(q.max_state(:,2),1),-1000*ones(1,sum(q.max_state(:,2))),'r.');
                for t = 1:length(tet)
                    eeg = loadeegstruct([post_path,animal,'/filterframework/'],animal,'eeg',d, e,tet(t));
                    eegtimes = geteegtimes(eeg{d}{e}{tet(t)});
                    eeginds = find(eegtimes>=epstart & eegtimes<=epend);
                    plot(eegtimes(eeginds),1000*(t-1)+eeg{d}{e}{tet(t)}.data(eeginds),'k');
                end
            end
            ylabel(['tets=',num2str(tet)]); ylim([-1000 3000]);
            ax2=subplot(6,1,[4:6]); hold on
            colormap(flipud(bone)); imagesc(posteriorts, [1:sum(~nodatarows)], post_combined(~nodatarows,:),[0 .3]); set(gca,'YDir','normal');
            plot(linposts,linposcorr,'m.','Markersize',11)
            patch([q.riptimes'; fliplr(q.riptimes)'],repmat([0 0 113.5 113.5]',1,length(maxseg)),'k','FaceAlpha',.1,'EdgeColor','none');
            % label trial types (lockout, search, repeat, error)
            plot([trials{d}{e}.starttime(~nonlocktrials),trials{d}{e}.endtime(~nonlocktrials)]',repmat(114,sum(~nonlocktrials),2)','Color',[.5 .5 .5],'Linewidth',2)
            plot([trials{d}{e}.starttime(trials{d}{e}.outersuccess==1),trials{d}{e}.endtime(trials{d}{e}.outersuccess==1)]',repmat(114,sum(trials{d}{e}.outersuccess==1),2)','Color',[1 1 0],'Linewidth',2)
            plot([trials{d}{e}.starttime(~nonlocktrials),trials{d}{e}.endtime(~nonlocktrials)]',repmat(114,sum(~nonlocktrials),2)','Color',[.5 .5 .5],'Linewidth',2)
            plot([trials{d}{e}.starttime(taskphase<=1),trials{d}{e}.endtime(taskphase<=1)]',repmat(115,sum(taskphase<=1),2)','Color',[0 0 0],'Linewidth',2)
            plot([trials{d}{e}.starttime(taskphase>0 & mod(taskphase,1)>0),trials{d}{e}.endtime(taskphase>0 & mod(taskphase,1)>0)]',repmat(115,sum(taskphase>0 & mod(taskphase,1)>0),2)','Color',[1 0 0],'Linewidth',2)
            plot(trials{d}{e}.starttime,repmat(116,1,length(nonlocktrials)),'k.')

            plot(repmat([0 epend],length(bounds),1)',repmat(bounds,1,2)','k:')
            set(gca,'ytick',[4.5;bounds+6.5],'yticklabel',{'B','1','2','3','4','5','6','7','8'})
%             % decide which rips to plot
%             %rinds = ones(length(maxpost),1);  % all rips
%             homerips = isExcluded(q.riptimes(:,1),[trials{d}{e}.starttime, trials{d}{e}.RWstart]);  % home rips
%             centerrips = isExcluded(q.riptimes(:,1),[trials{d}{e}.RWstart, trials{d}{e}.leaveRW]);  % center rips
%             outerrips = isExcluded(q.riptimes(:,1),[trials{d}{e}.outertime, trials{d}{e}.leaveouter]);  % outerrips
%             armcenters = [4.5;bounds+6.5];
            
            ylim([0 117]); xlabel(sprintf('%s d%d e%d',animal,d,e))
            linkaxes([ax1, ax2],'x');
            pan(gca,'xon'); zoom(gca, 'xon');
        case 'rips'
            numev = 5;
            %candidates = find(q.max_state(:,2));
            %ripind = candidates(randi(length(candidates),numev,1));
            %ripind = [1007, 1017, 1019, 1022, 1031]; %desp
            %ripind = [691 696 698 701 706]; %jaq
            %ripind = [829 830 839 845 846]; %roqui
            ripind = [1481 1484 1485 1486 1487]; %monty
            
            width = .5;
            eeg = loadeegstruct([post_path,animal,'/filterframework/'],animal,'eeg',d, e,tet);
            eegtimes = geteegtimes(eeg{d}{e}{tet(1)}); 
            
            for r = 1:numev
                rstartend = [mean(q.riptimes(ripind(r),:))-width/2 mean(q.riptimes(ripind(r),:))+width/2];
                ax1=subplot(6,numev,r); hold on;
                postinds = posteriorts>=rstartend(1) & posteriorts<=rstartend(2);
                plot(posteriorts(postinds),classifiercurves(1,postinds),'b');
                plot(posteriorts(postinds),classifiercurves(2,postinds),'r');
                patch([q.riptimes(ripind(r),:)'; fliplr(q.riptimes(ripind(r),:))'],[0 0 1 1]','k','FaceAlpha',.1,'EdgeColor','none');
                ax2=subplot(6,numev,[r+numev,r+2*numev]); hold on;
                patch([q.riptimes(ripind(r),:)'; fliplr(q.riptimes(ripind(r),:))'],[-1000 -1000 1000 1000]','k','FaceAlpha',.1,'EdgeColor','none');
                if q.max_state(ripind(r),1)
                    plot(q.riptimes(ripind(r),1),-1000,'b.');
                else
                    plot(q.riptimes(ripind(r),1),-1000,'r.');
                end
                eeginds = find(eegtimes>=rstartend(1) & eegtimes<=rstartend(2));
                for t = 1:length(tet)
                    plot(eegtimes(eeginds),1000*(t-1)+eeg{d}{e}{tet(t)}.data(eeginds),'k');
                end
                inrips = logical(isExcluded(eegtimes(eeginds),q.riptimes));
                plot(eegtimes(eeginds(inrips)),-500*ones(sum(inrips)),'k.'); % mark any other rips that occur in this window
                ylim([-1000 3000]); if r==1; ylabel(['tets=',num2str(tet)]); end
                ax3 = subplot(6,numev,[r+numev*3:numev:r+numev*5]); hold on;
                colormap(flipud(bone)); imagesc(posteriorts(postinds), [1:sum(~nodatarows)], post_combined(~nodatarows,postinds),[0 .3]); set(gca,'YDir','normal');
                linposinds = linposts>=rstartend(1) & linposts<=rstartend(2);
                plot(linposts(linposinds),linposcorr(linposinds),'m.','Markersize',11)
                patch([q.riptimes(ripind(r),:)'; fliplr(q.riptimes(ripind(r),:))'],[0 0 113.5 113.5]','k','FaceAlpha',.1,'EdgeColor','none');
                plot(repmat(rstartend,length(bounds),1)',repmat(bounds,1,2)','k:')
                set(gca,'ytick',[4.5;bounds+6.5],'yticklabel',{'B','1','2','3','4','5','6','7','8'})
                ylim([0 117]); xlabel(sprintf('%s d%d e%d r%d',animal(1:3),d,e,ripind(r)))
                linkaxes([ax1, ax3, ax2],'x'); if r==1; ylabel(['width=',num2str(width)]); end
                if r==numev; ylabel(['cbar=.3']); end
                pan(gca,'xon'); zoom(gca, 'xon');xlim(rstartend); 
            end
    
end


if appendindex
    out.index = index;
end

end