%% Sungod manu: Plot main results

animals = {'jaq','roquefort','despereaux','montague'};  %,, 'remy',};%};

epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; % & $decode_error<=1
%epochfilter{1} = ['$session==27'];

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epochbehaveanal';

f = createfilter('animal',animals,'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
f = setfilterfunction(f, 'dfa_ripcontent', {'muadecodesv3','trials','pos'});
f = runfilter(f);

animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols

%% plot the time spent, numrips, and rip rate at each trial phase - home, RW, postRW, outer(rew), outer(unrew)
figure;

for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        taskphase= f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(taskphase);
        
        rips = f(a).output{1}(eps(e)).trips.homeripsizes(valtrials);
        norips = cellfun(@isempty,rips)';
        count = zeros(length(norips),1);
        count(~norips) = cellfun(@(x) size(x,1),rips(~norips));
        waitlength{a}{e} = f(a).output{1}(eps(e)).trips.homewaitlength(valtrials);
        ripnum{a}{e} = count;
        
        rips = f(a).output{1}(eps(e)).trips.RWripsizes(valtrials);
        norips = cellfun(@isempty,rips)';
        count = zeros(length(norips),1);
        count(~norips) = cellfun(@(x) size(x,1),rips(~norips));
        waitlength{a}{e}(:,2) = f(a).output{1}(eps(e)).trips.RWwaitlength(valtrials);
        ripnum{a}{e}(:,2) = count;

        rips = f(a).output{1}(eps(e)).trips.postRWripsizes(valtrials);
        norips = cellfun(@isempty,rips)';
        count = zeros(length(norips),1);
        count(~norips) = cellfun(@(x) size(x,1),rips(~norips));
        waitlength{a}{e}(:,3) = f(a).output{1}(eps(e)).trips.postRWwaitlength(valtrials);
        ripnum{a}{e}(:,3) = count;
        
        rewouter = mod(taskphase(valtrials),1)==0 & taskphase(valtrials)>=1;
        rips = f(a).output{1}(eps(e)).trips.outerripsizes(valtrials);
        norips = cellfun(@isempty,rips)';
        count = zeros(length(norips),1);
        count(~norips) = cellfun(@(x) size(x,1),rips(~norips));
        ripnum{a}{e}(:,4:5) = [count count];  % duplicate for rew and unrew outer, then nan corresponding trials
        waitlength{a}{e}(:,4:5) = [f(a).output{1}(eps(e)).trips.outerwaitlength(valtrials) f(a).output{1}(eps(e)).trips.outerwaitlength(valtrials)];
        waitlength{a}{e}(~rewouter,4) = nan;
        ripnum{a}{e}(~rewouter,4) = nan;
        waitlength{a}{e}(rewouter,5) = nan;
        ripnum{a}{e}(rewouter,5) = nan;
    end
    rates{a} = cellfun(@(x,y) x./y,ripnum{a},waitlength{a},'un',0);
    subplot(3,length(animals),a); hold on; boxplot(vertcat(waitlength{a}{:}),'Positions',[1:5],'Symbol','','Colors','k'); ylim([0 30]); title(animals{a})
    subplot(3,length(animals),a+length(animals)); hold on; boxplot(vertcat(ripnum{a}{:}),'Positions',[1:5],'Symbol','','Colors','k'); ylim([0 20])
    subplot(3,length(animals),a+2*length(animals)); hold on; boxplot(vertcat(rates{a}{:}),'Positions',[1:5],'Symbol','','Colors','k');  ylim([0 2])
end

figure;
subplot(3,1,1); plot4a(cellfun(@(x) vertcat(x{:}),waitlength,'un',0),'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('time'); ylim([0 25])
subplot(3,1,2); plot4a(cellfun(@(x) vertcat(x{:}),ripnum,'un',0),'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('num rips'); ylim([0 30])
subplot(3,1,3); plot4a(cellfun(@(x) vertcat(x{:}),rates,'un',0),'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('riprate'); ylim([0 2])
figure;
subplot(3,1,1); plot4a(cellfun(@(x) vertcat(x{:}),waitlength,'un',0),'pooled',1,'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('time'); ylim([0 25])
subplot(3,1,2); plot4a(cellfun(@(x) vertcat(x{:}),ripnum,'un',0),'pooled',1,'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('num rips'); ylim([0 30])
subplot(3,1,3); plot4a(cellfun(@(x) vertcat(x{:}),rates,'un',0),'pooled',1,'gnames',{'home','rw','postrw','outer,rew','outer,unrew'}); title('riprate'); ylim([0 2])


%% plot the fraction of each event in the box area, by trialphase
figure;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        riptsz = f(a).output{1}(eps(e)).riptsz;
        %riptsz = riptsz(riptsz(:,4)==1,:);  % cont only
        riptsz = riptsz(riptsz(:,5)==1,:);  % cont max
        homeboxfracs{a}{e} = riptsz(riptsz(:,7)==1,8);
        centerboxfracs{a}{e} = riptsz(riptsz(:,7)>1 & riptsz(:,7)<4,8);
        outerboxfracs{a}{e} = riptsz(riptsz(:,7)>=4,8);
    end
    subplot(1,length(animals),a); hold on;  title(animals{a});
    [h,e] = histcounts(vertcat(homeboxfracs{a}{:}),[0:.1:1],'Normalization','probability'); bar(.02+e(1:end-1),h,'BarWidth',.3,'FaceColor','w');
    [h,e] = histcounts(vertcat(centerboxfracs{a}{:}),[0:.1:1],'Normalization','probability'); bar(.05+e(1:end-1),h,'BarWidth',.3,'FaceColor','b');
    [h,e] = histcounts(vertcat(outerboxfracs{a}{:}),[0:.1:1],'Normalization','probability'); bar(.08+e(1:end-1),h,'BarWidth',.3,'FaceColor','y');
    xlabel('fraction of event in box'); ylabel('frac of events');
end
homeall = cellfun(@(x) vertcat(x{:}),homeboxfracs,'un',0);
centerall = cellfun(@(x) vertcat(x{:}),centerboxfracs,'un',0); outerall = cellfun(@(x) vertcat(x{:}),outerboxfracs,'un',0);
figure; hold on; % other good spacing .03/.05/.07 width .2
[h,e] = histcounts(vertcat(homeall{:}),[0:.1:1],'Normalization','probability'); bar(.02+e(1:end-1),h,'BarWidth',.3,'FaceColor','w'); 
[h,e] = histcounts(vertcat(centerall{:}),[0:.1:1],'Normalization','probability'); bar(.05+e(1:end-1),h,'BarWidth',.3,'FaceColor','b')
[h,e] = histcounts(vertcat(outerall{:}),[0:.1:1],'Normalization','probability'); bar(.08+e(1:end-1),h,'BarWidth',.3,'FaceColor','y')
legend({'home','center','outer'}); xlabel('fraction of event in box'); ylabel('frac of events'); title('pooled')

%% plot the fraction of each event in the current maze segment and max remote single arm fraction
figure;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        valtrials = ~isnan(f(a).output{1}(eps(e)).trips.taskphase);
        home = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        homeboxfrac{a}{e} = cell2mat(cellfun(@(x) x(:,1)',home(~cellfun(@isempty,home)),'Un',0))';
        homemaxremote{a}{e} = cell2mat(cellfun(@(x) max(x(:,2:end)'),home(~cellfun(@isempty,home)),'Un',0))';
        rw = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        rwboxfrac{a}{e} = cell2mat(cellfun(@(x) x(:,1)',rw(~cellfun(@isempty,rw)),'Un',0))';
        rwmaxremote{a}{e} = cell2mat(cellfun(@(x) max(x(:,2:end)'),rw(~cellfun(@isempty,rw)),'Un',0))';
        postrw = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        postrwboxfrac{a}{e} = cell2mat(cellfun(@(x) x(:,1)',postrw(~cellfun(@isempty,postrw)),'Un',0))';
        postrwmaxremote{a}{e} = cell2mat(cellfun(@(x) max(x(:,2:end)'),postrw(~cellfun(@isempty,postrw)),'Un',0))';
        outer = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        arm = f(a).output{1}(eps(e)).trips.outerarm(valtrials); %(~cellfun(@isempty,outer))
        outerfracs{a}{e} = cell2mat(cellfun(@(x,y) x(:,y+1)',outer(~cellfun(@isempty,outer)),num2cell(arm(~cellfun(@isempty,outer))),'Un',0))';
        nolocal = cellfun(@(x,y) x(:,find(~ismember([1:9],y+1))),outer(~cellfun(@isempty,outer)),num2cell(arm(~cellfun(@isempty,outer))),'Un',0);
        outermaxremote{a}{e} = cell2mat(cellfun(@(x) max(x'),nolocal,'Un',0))';
        allmaxremote{a}{e} = [homemaxremote{a}{e}; rwmaxremote{a}{e}; postrwmaxremote{a}{e}; outermaxremote{a}{e}];
    end
    subplot(1,length(animals),a); hold on;  title(animals{a});
    [h,e] = histcounts(vertcat(allmaxremote{a}{:}),[0:.1:1],'Normalization','probability'); bar(.05+e(1:end-1),h,'FaceColor',animcol(a,:));
    %[h,e] = histcounts(vertcat(homeboxfrac{a}{:}),[0:.1:1],'Normalization','probability'); bar(.02+e(1:end-1),h,'BarWidth',.2,'FaceColor','w');
    %[h,e] = histcounts(vertcat(rwboxfrac{a}{:}),[0:.1:1],'Normalization','probability'); bar(.04+e(1:end-1),h,'BarWidth',.2,'FaceColor','c');
    %[h,e] = histcounts(vertcat(postrwboxfrac{a}{:}),[0:.1:1],'Normalization','probability'); bar(.06+e(1:end-1),h,'BarWidth',.2,'FaceColor','b');
    %[h,e] = histcounts(vertcat(outerfracs{a}{:}),[0:.1:1],'Normalization','probability'); bar(.08+e(1:end-1),h,'BarWidth',.2,'FaceColor','y');
    xlabel('max remote fraction'); ylabel('frac of events'); ylim([0 .5]); plot([.3 .3],[0 .5],'k:')
    text(.5,.2,['n=',num2str(length(vertcat(allmaxremote{a}{:})))])
end
% homeall = cellfun(@(x) vertcat(x{:}),homeboxfrac,'un',0); rwall = cellfun(@(x) vertcat(x{:}),rwboxfrac,'un',0);
% postrwall = cellfun(@(x) vertcat(x{:}),postrwboxfrac,'un',0); outerall = cellfun(@(x) vertcat(x{:}),outerfracs,'un',0);
% centerall = cellfun(@(x,y) [vertcat(x{:}); vertcat(y{:})], rwboxfrac,postrwboxfrac,'un',0);
% figure; hold on; % other good spacing .03/.05/.07 width .2
% [h,e] = histcounts(vertcat(homeall{:}),[0:.1:1],'Normalization','probability'); bar(.02+e(1:end-1),h,'BarWidth',.2,'FaceColor','w'); 
% %[h,e] = histcounts(vertcat(rwall{:}),[0:.1:1],'Normalization','probability'); bar(.04+e(1:end-1),h,'BarWidth',.2,'FaceColor','b')
% %[h,e] = histcounts(vertcat(postrwall{:}),[0:.1:1],'Normalization','probability'); bar(.06+e(1:end-1),h,'BarWidth',.2,'FaceColor','c')
% [h,e] = histcounts(vertcat(centerall{:}),[0:.1:1],'Normalization','probability'); bar(.05+e(1:end-1),h,'BarWidth',.2,'FaceColor','b')
% [h,e] = histcounts(vertcat(outerall{:}),[0:.1:1],'Normalization','probability'); bar(.08+e(1:end-1),h,'BarWidth',.2,'FaceColor','y')
% legend({'home','center','outer'}); xlabel('fraction of event in same segment'); ylabel('frac of events'); title('pooled')
% 

%% plot fraction coherent, local, salient, overall and by trial phase and taskphase [2F,3A]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
contentthresh = .3;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
   
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(tphasenum(:,1)<=1,1) = nan; % turn currgoals during search trials into nans
        goals(goals(:,1)==0,1) = nan;
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        trialstack  = [outers', pastwlock, goals,tphasenum(:,1)];
        clear replays homereplays rwreplays postrwreplays outerreplays boxreplays
        for t=1:length(homerips)  % extract valid rips and tack on trial info: [replay future past currgoal prevgoal ppgoal tphase salient local]
            if ~isempty(homerips{t})
                [maxval,ind] = max(homerips{t},[],2); %(:,2:end)
                valid = hometypes{t}'==1 & maxval>contentthresh;
                homereplays{t} =[ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==0];
            else homereplays{t} = []; end
            if ~isempty(rwrips{t})
                [maxval,ind] = max(rwrips{t},[],2); %(:,2:end)
                valid = rwtypes{t}'==1 & maxval>contentthresh;
                rwreplays{t} = [ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==0];
            else rwreplays{t} = []; end
            if ~isempty(postrwrips{t})
                [maxval,ind] = max(postrwrips{t},[],2); %(:,2:end)
                valid = postrwtypes{t}'==1 & maxval>contentthresh;
                postrwreplays{t} = [ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==0];
            else postrwreplays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = [ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[0,trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==trialstack(t,1)]; % include box as salient
                if any(valid)
                    outerreplays{t}(outerreplays{t}(:,9)==1,8) = 0; % correct salience to not include local events
                end
            else outerreplays{t} = []; end
        end
        allreplay = [homereplays';rwreplays'; postrwreplays'; outerreplays']; allreplay = vertcat(allreplay{:});
        allhome{a}{e} = vertcat(homereplays{:}); allrw{a}{e} = vertcat(rwreplays{:}); allpostrw{a}{e} = vertcat(postrwreplays{:}); allouter{a}{e} = vertcat(outerreplays{:});
        allbox{a}{e} = [homereplays';rwreplays'; postrwreplays']; allbox{a}{e} = vertcat(allbox{a}{e}{:});
        
        fraccohall{a}(e,1) = size(allreplay,1)/size([vertcat(homerips{:});vertcat(rwrips{:});vertcat(postrwrips{:});vertcat(outerrips{:})],1);
        fracremoteall{a}(e,1) = sum(allreplay(:,9)==0)/size([vertcat(homerips{:});vertcat(rwrips{:});vertcat(postrwrips{:});vertcat(outerrips{:})],1); % out of ALL detected SWRSsize(allreplay,1)
        fracsalientall{a}(e,1) = sum(allreplay(:,8)==1 & allreplay(:,9)==0)/sum(allreplay(:,9)==0); % out of nonlocal events
        
        fraccohbyphase{a}(e,:) = [size(allhome{a}{e},1)/size(vertcat(homerips{:}),1),size(allrw{a}{e},1)/size(vertcat(rwrips{:}),1), ...
            size(allpostrw{a}{e},1)/size(vertcat(postrwrips{:}),1),size(allouter{a}{e},1)/size(vertcat(outerrips{:}),1)];
        fracremotebyphase{a}(e,:) = [sum(allhome{a}{e}(:,9)==0)/size(allhome{a}{e},1),sum(allrw{a}{e}(:,9)==0)/size(allrw{a}{e},1),sum(allpostrw{a}{e}(:,9)==0)/size(allpostrw{a}{e},1),sum(allouter{a}{e}(:,9)==0)/size(allouter{a}{e},1)]; 
        fracsalientbyphase{a}(e,:) = [sum(allhome{a}{e}(:,8)==1 & allhome{a}{e}(:,9)==0)/sum(allhome{a}{e}(:,9)==0),sum(allrw{a}{e}(:,8)==1 & allrw{a}{e}(:,9)==0)/sum(allrw{a}{e}(:,9)==0), ...
            sum(allpostrw{a}{e}(:,8)==1 & allpostrw{a}{e}(:,9)==0)/sum(allpostrw{a}{e}(:,9)==0),sum(allouter{a}{e}(:,8)==1 & allouter{a}{e}(:,9)==0)/sum(allouter{a}{e}(:,9)==0)]; % out of nonlocal events
        
        fraccohboxouter{a}(e,:) = [size(allbox{a}{e},1)/size([vertcat(homerips{:});vertcat(rwrips{:});vertcat(postrwrips{:})],1),size(allouter{a}{e},1)/size(vertcat(outerrips{:}),1)];
        fracremoteboxouter{a}(e,:) = [sum(allbox{a}{e}(:,9)==0)/size(allbox{a}{e},1),sum(allouter{a}{e}(:,9)==0)/size(allouter{a}{e},1)]; 
        fracsalientboxouter{a}(e,:) = [sum(allbox{a}{e}(:,8)==1 & allbox{a}{e}(:,9)==0)/sum(allbox{a}{e}(:,9)==0),sum(allouter{a}{e}(:,8)==1 & allouter{a}{e}(:,9)==0)/sum(allouter{a}{e}(:,9)==0)]; % out of nonlocal events
        %subplot(221); hold on; plot(histcounts(allhome{a}{e}(:,1),[0:9],'Normalization','probability'),'.'); title([animals{a} 'home'])
        %subplot(222); hold on; plot(histcounts(allrw{a}{e}(:,1),[0:9],'Normalization','probability'),'.'); title('rw')
        %subplot(223); hold on; plot(histcounts(allpostrw{a}{e}(:,1),[0:9],'Normalization','probability'),'.'); title('postrw')
        %subplot(224); hold on; plot(histcounts(allouter{a}{e}(:,1),[0:9],'Normalization','probability'),'.'); title('outer')
    end
    %boxfracs{a} = mean(cell2mat(cellfun(@(x) [sum(x(:,9)==1);sum(x(:,9)==0 & x(:,8)==1);sum(x(:,9)==0 & x(:,8)==0)]./size(x,1),allbox{a},'un',0)),2); 
    %fracs = cell2mat(cellfun(@(x) [sum(x(:,9)==1);sum(x(:,1)==x(:,5));sum(x(:,1)~=x(:,5) & x(:,8)==1); sum(x(:,9)==0 & x(:,8)==0)]./size(x,1),allbox{a},'un',0)); 
    %subplot(2,1,1); %pie(mean(fracs,2),{'local','prevgoal','salient nonprevgoal','nonsalient'}); 
    %bar(a,mean(fracs,2),'stacked');title([animals{a} 'box'])
    % for outer need to isolate box (is considered salient). local is not salient
    %outerfracs{a} = mean(cell2mat(cellfun(@(x) [sum(x(:,9)==1);sum(x(:,1)==0); sum(x(:,1)~=0 & x(:,8)==1); sum(x(:,9)==0 & x(:,8)==0 & x(:,1)~=0)]./size(x,1),allouter{a},'un',0)),2); 
    %outerfracs{a} = mean(cell2mat(cellfun(@(x) [sum(x(:,9)==1);sum(x(:,1)==0); sum(x(:,1)==x(:,5)); sum(x(:,1)~=x(:,5) & x(:,8)==1 & x(:,1)~=0); sum(x(:,8)==0 & x(:,9)==0 & x(:,1)~=0)]./size(x,1),allouter{a},'un',0)); 
    %subplot(2,4,a+4); pie(mean(fracs,2),{'local','box','salient nonbox','nonsalient'}); title('outer')
    % total num box local/remote + outer local/box/remote arm pie
    totalnums{a} = [sum(cellfun(@(x) sum(x(:,9)==1),allbox{a})), sum(cellfun(@(x) sum(x(:,9)==0),allbox{a})), ...
        sum(cellfun(@(x) sum(x(:,9)==1),allouter{a})), sum(cellfun(@(x) sum(x(:,1)==0),allouter{a})),sum(cellfun(@(x) sum(x(:,9)==0 & x(:,1)>0),allouter{a}))] ...
        ./(sum(cellfun(@(x) size(x,1),allbox{a}))+sum(cellfun(@(x) size(x,1),allouter{a})));
    subplot(1,4,a); pie(totalnums{a}); text(0,-1.5,['n=',num2str(sum(cellfun(@(x) size(x,1),allbox{a}))+sum(cellfun(@(x) size(x,1),allouter{a})))]);
    title(animals{a})
end
legend({'box local','box remote','outer local','outer box','outer remotearm'})
%subplot(1,2,1); bar(horzcat(boxfracs{:})','stacked'); title('box replays'); legend({'local','salient','nonsalient'}); ylim([0 1]); ylabel('fraction of coherent SWRs')
%subplot(1,2,2); bar(horzcat(outerfracs{:})','stacked'); title('outer replays'); legend({'local','box','salient','nonsalient'}); xlabel('subject')
figure;
subplot(3,3,1); hold on; plot4a(fraccohall,'gnames',{'coherent'}); ylim([0 1]); title('out of all swrs'); ylabel('frac of all events')
subplot(3,3,2); hold on; plot4a(fracremoteall,'gnames',{'remote'}); ylim([0 1]); title('out of ALL SWRs')
text([6:9],[.6 .7 .8 .9],num2str(cellfun(@(x) mean(x),fracremoteall)','%.04f')); text([7:10],[.6 .7 .8 .9],num2str(cellfun(@length,fracremoteall)'))
subplot(3,3,3); hold on; plot4a(fracsalientall,'gnames',{'salient'}); ylim([0 1]); title('out of all remote')
subplot(3,3,4); hold on; plot4a(fraccohbyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('coherent'); ylabel('frac of all events')
subplot(3,3,5); hold on; plot4a(fracremotebyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('remote out of all coh')
subplot(3,3,6); hold on; plot4a(fracsalientbyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('salient')
subplot(3,3,7); hold on; plot4a(fraccohboxouter,'gnames',{'box','outer'}); ylim([0 1]); title('coherent'); ylabel('frac of all events')
subplot(3,3,8); hold on; plot4a(fracremoteboxouter,'gnames',{'box','outer'}); ylim([0 1]); title('remote out of all coh')
subplot(3,3,9); hold on; plot4a(fracsalientboxouter,'gnames',{'box','outer'}); ylim([0 1]); title('salient')

%% make Violins and bars of content relationships with various trial categories, vs rand shuffs [HOME / RW] [3A,B]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
reps = 1000;
contentthresh = .3;
for a = 1:length(animals)
    %figure; set(gcf,'Position',[1008 1009 663 833]);
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        
        valtrials = ~cellfun(@isempty, replays);
        if any(valtrials)
            ripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], replays(valtrials), num2cell(outers(valtrials)), ...
                num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
            ripcomb = vertcat(ripcomb{:});
        salient = ripcomb(:,1)>0 & (ripcomb(:,1)==ripcomb(:,2) | ripcomb(:,1)==ripcomb(:,3) | table2array(rowfun(@(x) ismember(x(1),goals(1:x(8),1)),table(ripcomb))));
        contentfracs{a}(e,:) = [length(vertcat(rips{:}))-size(ripcomb,1), sum(ripcomb(:,1)==0), sum(salient), sum(ripcomb(:,1)>0 & ~salient)]./length(vertcat(rips{:}));

        % all ripples during search trials; f vs past vs pgoal
        search = ripcomb((ripcomb(:,7) <= 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(search)));
        allunique = search(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            search_future{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            search_past{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            search_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5)); 
            search_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,3) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                search_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        search_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)<1)];  % #rips #trials #totalsearchtrials 

        % all ripples during search trials; f==pgoal vs past 
        alluniqueinds = search(:,2)==search(:,5) & search(:,2)~=search(:,4) ;
        allunique = search(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            search2_futurepg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            search2_past{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            search2_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,4));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                search2_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
         search2_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)<1)];  % #rips #trials #totalsearchtrials
       % all ripples during repeat trials; future==past==goal vs pg
        repeat = ripcomb((ripcomb(:,7) > 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,4])))==1,table(repeat))) & repeat(:,5)~=repeat(:,2);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep1_pfg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            rep1_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            rep1_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep1_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep1_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        
        % all ripples during repeat trials; future==goal vs past vs pg
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(repeat))) & repeat(:,2)==repeat(:,4);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep2_futureg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            rep2_past{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            rep2_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            rep2_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,3) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep2_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep2_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        
        % all ripples during repeat trials; past==curgoal vs future vs pg
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(repeat))) & repeat(:,3)==repeat(:,4);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep3_future{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            rep3_pastg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            rep3_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            rep3_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,3) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep3_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep3_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        
        % all ripples during repeat trials; past vs curgoal vs future vs pg
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,4,5])))==4,table(repeat)));
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep4_future{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,2));
            rep4_past{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            rep4_currg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,4));
            rep4_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            rep4_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,3) & allunique(:,1)~=allunique(:,4) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep4_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep4_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials

        end
    end
    diag = logical(eye(8));
    eptot_future = sum(search_future{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_past = sum(search_past{a},3);  frac_past = sum(eptot_past(diag))/eventtotal; 
    eptot_prevgoal = sum(search_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    frac_other = (sum(search_other{a})/eventtotal)/5;
    eptot_randshuff = sum(search_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_search_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,5,6); hold on;
    bar(a/5+[1:4],[frac_past,frac_future,frac_prevgoal,frac_other]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_other,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dsearchtrials',eventtotal,sum(search_rtcounts{a}(:,2)),sum(search_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:4],a/20+[.1 .1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
   
%     eptot_future = sum(search2_futurepg{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
%     eptot_past = sum(search2_past{a},3);  frac_past = sum(eptot_past(diag))/eventtotal; 
%     eptot_randshuff = sum(search2_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
%     frac_search2_randshuff_norm{a} = frac_randshuff'-.125;
%     figure(bars);  subplot(2,5,7); hold on;
%     bar(a/5+[1:2],[frac_future,frac_past]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
%     pvals =[permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps)];
%     ntext = sprintf('n=%devents;%d/%dsearchtrials',eventtotal,sum(search2_rtcounts{a}(:,2)),sum(search2_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
%     text(3/5+-.3+[1:2],a/20+[.1 .1 ],num2str(pvals','%.04f'),'Color',animcol(a,:));
%    
    eptot_future = sum(rep1_pfg{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_prevgoal = sum(rep1_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep1_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_other = (sum(rep1_other{a})/eventtotal)/6;
    frac_rep1_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,5,7); hold on;
    bar(a/5+[1:3],[frac_future,frac_prevgoal,frac_other]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_other,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep1_rtcounts{a}(:,2)),sum(rep1_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:3],a/20+[.1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
    
    eptot_future = sum(rep2_futureg{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_past = sum(rep2_past{a},3);  frac_past = sum(eptot_past(diag))/eventtotal; 
    eptot_prevgoal = sum(rep2_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep2_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_rep2_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,5,8); hold on;
    bar(a/5+[1:3],[frac_past,frac_future,frac_prevgoal]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep2_rtcounts{a}(:,2)),sum(rep2_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:3],a/20+[.1 .1 .1 ],num2str(pvals','%.04f'),'Color',animcol(a,:));
    
    eptot_future = sum(rep3_future{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_past = sum(rep3_pastg{a},3);  frac_past = sum(eptot_past(diag))/eventtotal; 
    eptot_prevgoal = sum(rep3_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep3_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_rep3_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,5,9); hold on;
    bar(a/5+[1:3],[frac_past,frac_future,frac_prevgoal]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep3_rtcounts{a}(:,2)),sum(rep3_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:3],a/20+[.1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
    
    eptot_future = sum(rep4_future{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_past = sum(rep4_past{a},3);  frac_past = sum(eptot_past(diag))/eventtotal; 
    eptot_currg = sum(rep4_currg{a},3);  frac_currg = sum(eptot_currg(diag))/eventtotal; 
    eptot_prevgoal = sum(rep4_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep4_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_rep4_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,5,10); hold on;
    bar(a/5+[1:4],[frac_past,frac_future,frac_currg,frac_prevgoal]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_future,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_currg,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep4_rtcounts{a}(:,2)),sum(rep4_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:4],a/20+[.1 .1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));

end

subplot(2,5,1); violin(frac_search_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,6); xlim([1 5]); ylim([-.15 .4]); 
set(gca,'xtick',[1.5:1:4.5],'xticklabel',{'past','future','prevgoal','other'}); title('search'); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
%subplot(2,5,2); violin(frac_search2_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
%set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
%subplot(2,5,7); xlim([1 4]); ylim([-.15 .4]); 
%set(gca,'xtick',[1.5:1:2.5],'xticklabel',{'f/prevgoal','past'}); title('search'); set(gca,'yticklabel',{'0.025','0.075','0.125','0.175','0.225','0.275','0.325','',''})
subplot(2,5,2); violin(frac_rep1_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,7); xlim([1 4]); ylim([-.15 .4]); 
set(gca,'xtick',[1.5:1:3.5],'xticklabel',{'pfg','prevgoal','other'}); title('repeat'); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,3); violin(frac_rep2_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,8); xlim([1 4]); ylim([-.15 .4]); 
set(gca,'xtick',[1.5:1:3.5],'xticklabel',{'past','future/g','prevgoal'}); title('repeat'); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,4); violin(frac_rep3_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,9); xlim([1 4]); ylim([-.15 .4]); 
set(gca,'xtick',[1.5:1:3.5],'xticklabel',{'past/g','future','prevgoal'}); title('repeat'); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,5); violin(frac_rep4_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays, p vs randshuff')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
subplot(2,5,10); xlim([1 5]); ylim([-.15 .4]); 
set(gca,'xtick',[1.5:1:4.5],'xticklabel',{'past','future','currg','prevgoal'}); title('repeat'); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})

%figure; plot4a(contentfracs,'gnames',{'incoh','local','salient','other'}); ylim([0 .75]); title('box replays')
% figure; subplot(1,5,1); plot4a(cellfun(@(x) x(:,1)./x(:,2),search_rtcounts,'Un',0)); ylim([0 20]);
% subplot(1,5,2); plot4a(cellfun(@(x) x(:,1)./x(:,2),search2_rtcounts,'Un',0));ylim([0 20]);
% subplot(1,5,3); plot4a(cellfun(@(x) x(:,1)./x(:,2),rep1_rtcounts,'Un',0));ylim([0 20]);
% subplot(1,5,4); plot4a(cellfun(@(x) x(:,1)./x(:,2),rep2_rtcounts,'Un',0));ylim([0 20]);
% subplot(1,5,5); plot4a(cellfun(@(x) x(:,1)./x(:,2),rep3_rtcounts,'Un',0));ylim([0 20]);

%figname = 'allbox-maxcont'; 
%print(figname,'-depsc','-painters')
%% plot how the trials break down across categories (search p==f==pg etc)
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        valtrials = ~isnan(f(a).output{1}(eps(e)).trips.taskphase);
        rips = f(a).output{1}(eps(e)).trips.allrwcontentcounts(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        %allrwtypes = cellfun(@(x,y) [x,y]',rwtypes,postrwtypes,'un',0);
        %rips = f(a).output{1}(eps(e)).trips.homecontentcounts;
        %allrwtypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes;
        homerips = f(a).output{1}(eps(e)).trips.homecontentcounts(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rips = cellfun(@(x,y) [x;y],homerips,rips,'un',0);
        allrwtypes = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase(valtrials);   % add trial numbers
        hasrips = ~cellfun(@isempty, rips);
        hasreplay = zeros(length(hasrips),1);
        hasreplay(hasrips) = cellfun(@(x,y) any(x(:,1)>0 & y==1),rips(hasrips),allrwtypes(hasrips));
        comb = [hasreplay, outers',pastwlock, goals(:,1:2), tphasenum];
        % categories of search trials
        searchtypes{a}(e,1) = sum(comb(:,6)<=1 & table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(comb)))); %alldif
        searchtypes{a}(e,2) = sum(comb(:,6)<=1 & table2array(rowfun(@(x) length(unique(x([2,3,5])))==1,table(comb)))); % allsame
        searchtypes{a}(e,3) = sum(comb(:,6)<=1 & comb(:,2)==comb(:,3) & comb(:,2)~=comb(:,5)); %pfvspgsearch
        searchtypes{a}(e,4) =  sum(comb(:,6)<=1 & comb(:,2)~=comb(:,3) & comb(:,3)==comb(:,5)); %ppgvsfsearch
        searchtypes{a}(e,5) =  sum(comb(:,6)<=1 & comb(:,2)==comb(:,5) & comb(:,3)~=comb(:,5)); %fpgvspsearch
        searchtypes{a}(e,6) = sum(comb(:,6)<=1);
       % frac that contains replay
        fracrep{a}(e,1) = sum(comb(:,1)==1 & comb(:,6)<=1 & table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(comb))))/searchtypes{a}(e,1); %alldif
        fracrep{a}(e,2) = sum(comb(:,1)==1 & comb(:,6)<=1 & table2array(rowfun(@(x) length(unique(x([2,3,5])))==1,table(comb))))/searchtypes{a}(e,2); % allsame
        fracrep{a}(e,3) = sum(comb(:,1)==1 & comb(:,6)<=1 & comb(:,2)==comb(:,3) & comb(:,2)~=comb(:,5))/searchtypes{a}(e,3); %pfvspgsearch
        fracrep{a}(e,4) =  sum(comb(:,1)==1 & comb(:,6)<=1 & comb(:,2)~=comb(:,3) & comb(:,3)==comb(:,5))/searchtypes{a}(e,4); %ppgvsfsearch
        fracrep{a}(e,5) =  sum(comb(:,1)==1 & comb(:,6)<=1 & comb(:,2)==comb(:,5) & comb(:,3)~=comb(:,5))/searchtypes{a}(e,5); %fpgvspsearch
        fracrep{a}(e,6) = sum(comb(:,1)==1 & comb(:,6)<=1)/searchtypes{a}(e,6);
    end
end
figure; subplot(1,2,1); plot4a(cellfun(@(x) x(:,1:5)./repmat(x(:,6),1,5),searchtypes,'Un',0),'gnames',{'alldif','allsame','pfvspg','ppgvsf','fpgvsp'});
subplot(1,2,2); plot4a(fracrep,'gnames',{'alldif','allsame','pfvspg','ppgvsf','fpgvsp','total'});

%% make Violins and bars of content relationships with various trial categories, vs rand shuffs [OUTER]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
reps = 1000;
contentthresh=.3;
for a = 1:length(animals)
    %figure; set(gcf,'Position',[1008 1009 663 833]);
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        rips = f(a).output{1}(eps(e)).trips.outerripcontent;
        types = f(a).output{1}(eps(e)).trips.outerripmaxtypes; %
        goals = f(a).output{1}(eps(e)).trips.goalarm;
        outers = f(a).output{1}(eps(e)).trips.outerarm;
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(:,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase, [1:length(goals)]'];   % add trial numbers
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}'==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
        end   
        valtrials = ~cellfun(@isempty, replays);
        if any(valtrials)
            ripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], replays(valtrials), num2cell(outers(valtrials)), ...
                num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
            ripcomb = vertcat(ripcomb{:});
            %salient - past or previously rewarded arms only, not box/future
        salient = ~(ripcomb(:,1)==ripcomb(:,2)) & (ripcomb(:,1)==ripcomb(:,3) | table2array(rowfun(@(x) ismember(x(1),goals(1:x(8),1)),table(ripcomb))));
        contentfracs{a}(e,:) = [length(vertcat(rips{:}))-size(ripcomb,1), sum(ripcomb(:,1)==ripcomb(:,2)), sum(ripcomb(:,1)==0), sum(salient), sum(ripcomb(:,1)~=ripcomb(:,2) & ripcomb(:,1)>0 & ~salient)]./length(vertcat(rips{:}));
        nonlocal = ripcomb(ripcomb(:,1)~=ripcomb(:,2),:);  % get rid of local events
        nonlocal(:,9) = zeros(size(nonlocal,1),1); % add a new column for future: box (zeros) in addition to current location
        trialfracs{a}(e,:) = [sum(~valtrials' & tphasenum(:,1)>=1), sum(valtrials' & tphasenum(:,1)>=1)-length(unique(nonlocal(:,8))),length(unique(nonlocal(:,8)))]/sum(tphasenum(:,1)>=1); % of repeat trials, fractrials no replay, frac local only, frac with nonlocal , 

        % all ripples during repeat trials; future=box, prevarm=currarm/goal vs prevgoal 
        %repeat = nonlocal((nonlocal(:,7) >= 1 &  ~isnan(nonlocal(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        repeat = ripcomb((ripcomb(:,7) >= 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = repeat(:,2)==repeat(:,3) & repeat(:,3)==repeat(:,4) & repeat(:,4)~=repeat(:,5);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
%             rep1_future{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,9),'withbox',1);
%             rep1_pcg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3),'withbox',1);
%             rep1_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5),'withbox',1);
%             for r = 1:reps
%                 randlist = randi([0 8],size(allunique,1),1);
%                 while any(randlist==allunique(:,2))   % remove any localarms from randlist
%                     randlist(randlist==allunique(:,2)) = randi([0 8],sum(randlist==allunique(:,2)),1);
%                 end
%                 rep1_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist,'withbox',1);
%             end
            rep1_pcg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            rep1_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            rep1_other{a}(:,:,e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep1_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep1_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        
        % all ripples during repeat trials; future==goal vs past vs pg (past error, not to pg)
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([3,4,5])))==3,table(repeat)));
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep2_past{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,3));
            rep2_cg{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,4));
            rep2_prevgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5));
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep2_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist);
           end
        end
        rep2_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        
        % all ripples during repeat trials; future==goal vs past=pg (past error to pg)
%         alluniqueinds = repeat(:,7)==1; %repeat(:,3)==repeat(:,5) & repeat(:,4)~=repeat(:,3);
%         allunique = repeat(alluniqueinds,:); %
%         if length(unique(allunique(:,8)))>=1
%             rep3_box{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,9),'withbox',1);
%             rep3_pgoal{a}(:,:,e) = replaymatrix(allunique(:,1),allunique(:,5),'withbox',1);
%             for r = 1:reps
%                 randlist = randi([0 8],size(allunique,1),1);
%                 while any(randlist==allunique(:,2))   % remove any localarms from randlist
%                     randlist(randlist==allunique(:,2)) = randi([0 8],sum(randlist==allunique(:,2)),1);
%                 end
%                 rep3_randshuff{a}(:,:,e,r) = replaymatrix(allunique(:,1),randlist,'withbox',1);
%            end
%         end
%         rep3_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
%         
        end
    end
    diag = logical(eye(8));
    %eptot_future = sum(rep1_future{a},3); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_pcg = sum(rep1_pcg{a},3); eventtotal = sum(sum(eptot_pcg)); frac_pcg = sum(eptot_pcg(diag))/eventtotal; 
    eptot_prevgoal = sum(rep1_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep1_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_other = (sum(rep1_other{a})/eventtotal)/6;
    %frac_rep1_randshuff_norm{a} = frac_randshuff'-.125; %
    %figure(bars);  subplot(2,3,4); hold on;
    %bar(a/5+[1:3],[frac_pcg,frac_prevgoal,frac_other]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    %pvals =[permutationp(frac_pcg,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps), permutationp(frac_other,frac_randshuff,'tails',2,'reps',reps)];
    %ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep1_rtcounts{a}(:,2)),sum(rep1_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    %text(3/5+-.3+[1:3],a/20+[.1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
    % relative to 0 (not .125) version
    frac_rep1_randshuff_norm{a} = frac_randshuff'; %
    figure(bars);  subplot(2,3,4); hold on;
    bar(a/5+[1:3],[frac_pcg,frac_prevgoal,frac_other],'FaceColor',animcol(a,:),'BarWidth',.2)
    %pvals =[permutationp(frac_pcg,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps), permutationp(frac_other,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep1_rtcounts{a}(:,2)),sum(rep1_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    %text(3/5+-.3+[1:3],a/20+[.1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));

    %eptot_future = sum(rep2_future{a},3); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
    eptot_past = sum(rep2_past{a},3); eventtotal = sum(sum(eptot_past));  frac_past = sum(eptot_past(diag))/eventtotal; 
    eptot_cg = sum(rep2_cg{a},3);  frac_cg = sum(eptot_cg(diag))/eventtotal; 
    eptot_prevgoal = sum(rep2_prevgoal{a},3); frac_prevgoal = sum(eptot_prevgoal(diag))/eventtotal; 
    eptot_randshuff = sum(rep2_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[8 reps]))/eventtotal;
    frac_rep2_randshuff_norm{a} = frac_randshuff'-.125;
    figure(bars);  subplot(2,3,5); hold on;
    bar(a/5+[1:3],[frac_past,frac_cg,frac_prevgoal]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
    pvals =[permutationp(frac_past,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_cg,frac_randshuff,'tails',2,'reps',reps),permutationp(frac_prevgoal,frac_randshuff,'tails',2,'reps',reps)];
    ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep2_rtcounts{a}(:,2)),sum(rep2_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
    text(3/5+-.3+[1:3],a/20+[.1 .1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
    
%     eptot_future = sum(rep3_box{a},3);eventtotal = sum(sum(eptot_future)); frac_future = sum(eptot_future(diag))/eventtotal;% will be same total for all
%     eptot_pgoal = sum(rep3_pgoal{a},3);  frac_pgoal = sum(eptot_pgoal(diag))/eventtotal; 
%     eptot_randshuff = sum(rep3_randshuff{a},3); frac_randshuff = sum(reshape(eptot_randshuff(repmat(diag,1,1,reps)),[9 reps]))/eventtotal;
%     frac_rep3_randshuff_norm{a} = frac_randshuff'-.125;
%     figure(bars);  subplot(2,3,6); hold on;
%     bar(a/5+[1:2],[frac_future,frac_pgoal]-.125,'FaceColor',animcol(a,:),'BarWidth',.2)
%     pvals =[permutationp(frac_future,frac_randshuff,'tails',2),permutationp(frac_pgoal,frac_randshuff,'tails',2)];
%     ntext = sprintf('n=%devents;%d/%dreptrials',eventtotal,sum(rep3_rtcounts{a}(:,2)),sum(rep3_rtcounts{a}(:,3))); text(1,a/20+.125,ntext,'Color',animcol(a,:));
%     text(3/5+-.3+[1:2],a/20+[.1 .1],num2str(pvals','%.04f'),'Color',animcol(a,:));
%     
end

%subplot(2,3,1); violin(frac_rep1_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .55]); title('randshuff'); ylabel('fraction replays')
%set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425','0.525','0.625'})
subplot(2,3,4); xlim([1 5]); %ylim([-.15 .55]); set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425','0.525','0.625'})
set(gca,'xtick',[1.5:1:3.5],'xticklabel',{'current','prevgoal','other'}); title('repeat');
subplot(2,3,2); violin(frac_rep2_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .55]); title('randshuff'); ylabel('fraction replays')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425','0.525','0.625'})
subplot(2,3,5); xlim([1 5]); ylim([-.15 .55]); 
set(gca,'xtick',[1.5:1:3.5],'xticklabel',{'past','current','prevgoal'}); title('repeat')
set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425','0.525','0.625'})
% subplot(2,3,3); violin(frac_rep3_randshuff_norm,'medc',[],'facecolor',[.3 .3 .3]); ylim([-.15 .4]); title('randshuff'); ylabel('fraction replays')
% set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})
% subplot(2,3,6); xlim([1 4]); ylim([-.15 .4]); 
% set(gca,'xtick',[1.5:1:2.5],'xticklabel',{'box','pgoal'}); title('repeat');
% set(gca,'yticklabel',{'0.025','0.125','0.225','0.325','0.425',''})

%figure; %plot4a(contentfracs,'gnames',{'incoh','localarm','box','salient','other'}); ylim([0 .75]); title('outer replays')
subplot(2,3,6); plot4a(trialfracs,'gnames',{'norips','localonly','hasremote'}); ylim([0 1]); title('repeat frac norips/localonly')

%%  measure replay rate of an arm during contingencies before during/after it is goal
clearvars -except f animals animcol
figure; set(gcf,'Position',[675 1 1202 973]);  plt=1;
contentthresh = .3;
window = 40; %trials for trialcurves
kernel = gaussian(1,5); %[0 0 1 0 0]; %
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        cont = f(a).output{1}(eps(e)).trips.contingency;
        valtrials = cont<=8;  % don't use any part of the epoch with repeat goals
        cont=cont(valtrials);
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase(valtrials), [1:length(goals)]'];   % add trial numbers
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
               valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        % smoothing is ok here bc this is just used for visualizing the curves across trial, not quantification per phase
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        for r = 1:8; countspertrial(r,:) = smoothvect(countspertrial(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        ind=1;
        for c = 1:max(cont)  % for each contingency, count search and repeat phases separately
            searchreplays = replays(cont==c & tphasenum(:,1)<=1);  
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(searchreplays),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)<=1),1,8);
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)<=1),[1:9]);
                ecp{a}{e}(ind,:) = [e, c, 1]; % epoch cont phase (search=1, repeat=2);
                goalarm{a}{e}(ind) = nan;
                if ind==1
                goalreplay{a}{e}(ind,:) = [nan sum(replaycount{a}{e}(ind,:))];
                cumgoalreplay{a}{e}(ind,:) = goalreplay{a}{e}(ind,:);
                else
                    goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                end
            ind = ind+1;
            
            if any(cont==c & tphasenum(:,1)==4)  % needs to earn at least 4 goals for this cont to count
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(replays(cont==c & tphasenum(:,1)>1)),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)>1),1,8);
                goalarm{a}{e}(ind) = goals(cont==c & tphasenum(:,1)==1); % convenient to use first trial to indicate goal
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)>1),[1:9]);
                ecp{a}{e}(ind,:) = [e c 2]; % epoch cont phase (search=1, repeat=2);
                goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                searchlength{a}{e}(c) = sum(cont==c & tphasenum(:,1)<1); % if complete cont, store search length for later

            else % not enough of this goal experienced
                replaycount{a}{e}(ind,:) = nan(1,8);
                trialcount{a}{e}(ind,:) = nan(1,8);
                visitcount{a}{e}(ind,:) = nan(1,8);
                goalarm{a}{e}(ind) = nan; 
                ecp{a}{e}(ind,:) = [nan nan nan]; % epoch cont phase (search=1, repeat=2);
                goalreplay{a}{e}(ind,:) = [nan nan]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = [nan nan];
            end
            ind = ind+1;
        end
        replaypertrial{a}{e} = [nan(4,8); replaycount{a}{e}./trialcount{a}{e}; nan(6,8)];  % pad with nans for alignment
        goalarm{a}{e} = [nan(1,4), goalarm{a}{e},nan(1,6)];
        visitcount{a}{e} = [nan(4,8); visitcount{a}{e}; nan(6,8)];  
        goallist = unique(goalarm{a}{e}(~isnan(goalarm{a}{e})),'stable');
        nevergoals{a}{e} = find(~ismember([1:8],goallist));
        %subplot(1,4,a);hold on;
        %if length(goallist)>3
        realignednongoal{a}{e} = [];
        realignednongoalvis{a}{e} = [];
        bytrial_firstrew_non{a}{e} = [];
        bytrial_lastrew_non{a}{e} = [];
        bytrial_start_non{a}{e} = [];
        bytrial_firstrewvis_non{a}{e} = [];
        bytrial_lastrewvis_non{a}{e} = [];
        for c = 1:length(goallist)
            inds = [-4+find(goalarm{a}{e}==goallist(c)):find(goalarm{a}{e}==goallist(c))+6];
            realigned{a}{e}(c,:) = replaypertrial{a}{e}(inds,goallist(c));
            realignedvis{a}{e}(c,:) = visitcount{a}{e}(inds,goallist(c));
            if ~isempty(nevergoals{a}{e})
            %randnongoal = randi(length(nevergoals{a}{e}));  % choose a random unrewarded arm
            %allbutgoal = find(goallist(c)~=[1:8]);
            realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,nevergoals{a}{e})']; % add all nonrewarded arms to list
            %realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,allbutgoal)']; % add all nonrewarded arms to list
            realignednongoalvis{a}{e} = [realignednongoalvis{a}{e}; visitcount{a}{e}(inds,nevergoals{a}{e})'];
            end
            goalnum{a}{e}(c) = sum(tphasenum(cont==c,1)>=1 & mod(tphasenum(cont==c,1),1)==0);
            % trialwise curves (aligned to first and last reward of cont)
            start = find(cont==c & tphasenum(:,1)==1);
            firstinds = start-window:start+window;
            bytrial_firstrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrew{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= countspertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            bytrial_firstrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrewvis{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= vispertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            start= find(cont==c & tphasenum(:,1)==max(tphasenum(cont==c & mod(tphasenum(:,1),1)==0,1)));
            lastinds = start-window:start+window;
            bytrial_lastrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrew{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= countspertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            bytrial_lastrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrewvis{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= vispertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            %post-cont replay/visit count
            if sum(lastinds>start & lastinds<=length(outers))==window % only collect data if all trials available
                postreplaycount{a}{e}(c) = sum(countspertrial(goallist(c),lastinds(lastinds>start & lastinds<=length(outers))));
                postviscount{a}{e}(c) = sum(vispertrial(goallist(c),lastinds(lastinds>start & lastinds<=length(outers)))); 
            else
                postreplaycount{a}{e}(c) = nan;
                postviscount{a}{e}(c) = nan;
            end
            
            start= find(cont==c,1);
            startinds = start-window:start+window;
            bytrial_start{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_start{a}{e}(c,find(startinds>0 & startinds<=length(outers)))= countspertrial(goallist(c),startinds(startinds>0 & startinds<=length(outers)));
 
            if ~isempty(nevergoals{a}{e})
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(firstinds>0 & firstinds<=length(outers)))= countspertrial(nevergoals{a}{e},firstinds(firstinds>0 & firstinds<=length(outers)));
                bytrial_firstrew_non{a}{e} = [bytrial_firstrew_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(firstinds>0 & firstinds<=length(outers)))= vispertrial(nevergoals{a}{e},firstinds(firstinds>0 & firstinds<=length(outers)));
                bytrial_firstrewvis_non{a}{e} = [bytrial_firstrewvis_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(lastinds>0 & lastinds<=length(outers)))= countspertrial(nevergoals{a}{e},lastinds(lastinds>0 & lastinds<=length(outers)));
                bytrial_lastrew_non{a}{e} = [bytrial_lastrew_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(lastinds>0 & lastinds<=length(outers)))= vispertrial(nevergoals{a}{e},lastinds(lastinds>0 & lastinds<=length(outers)));
                bytrial_lastrewvis_non{a}{e} = [bytrial_lastrewvis_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(startinds>0 & startinds<=length(outers)))= countspertrial(nevergoals{a}{e},startinds(startinds>0 & startinds<=length(outers)));
                bytrial_start_non{a}{e} = [bytrial_start_non{a}{e}; tmp];
            end
            
            
            
        %    plot([1:9],replaypertrial{a}{e}(inds,goallist(c)),'k-o');
        end
        %realigned{a}{e} = realigned{a}{e}(searchlength(1:length(goallist))>=4,:);
        %realignednongoal{a}{e} = realignednongoal{a}{e}(searchlength(1:length(goallist))>=4,:);
        
        %end
        %figure; subplot(3,1,1); plot(replaypertrial{a}{e}); legend; title(['ep',num2str(e)])
        %subplot(3,1,2); hold on; plot(realigned{a}{e}'); plot(realignednongoal{a}{e}',':'); title(num2str(unique(goalarm{a}{e}(~isnan(goalarm{a}{e})),'stable')));
        %subplot(3,1,3); hold on; plot(nanmean(realigned{a}{e})); plot(nanmean(realignednongoal{a}{e}),':');
    end
    
    % BY TRIAL CURVES - aligned to first reward of cont
%     xvals = -window:window;
%     firstrewcurve = vertcat(bytrial_firstrew{a}{:}); firstrewcurve_non = vertcat(bytrial_firstrew_non{a}{:}); 
%     %firstrewcurve = vertcat(bytrial_start{a}{:}); firstrewcurve_non = vertcat(bytrial_start_non{a}{:}); 
%     %valeps = ~cellfun(@isempty,bytrial_firstrew{a}) & cellfun(@(x) sum(~isnan(x)),goalarm{a})>=1;
%     %firstrewcurve = cell2mat(cellfun(@(x) x(1,:)',bytrial_firstrew{a}(valeps),'un',0))';  % just plot a single contingency#
%     %firstrewcurve_non = cell2mat(cellfun(@(x,y) x((1-1)*length(y)+[1:length(y)],:)',bytrial_firstrew_non{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
%     subplot(4,4,a+12); hold on; ylabel('replay/trial'); xlabel('trials from first rew of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstrewcurve)-nanstd(firstrewcurve)./sqrt(sum(~isnan(firstrewcurve))), fliplr(nanmean(firstrewcurve)+nanstd(firstrewcurve)./sqrt(sum(~isnan(firstrewcurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstrewcurve),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstrewcurve_non)-nanstd(firstrewcurve_non)./sqrt(sum(~isnan(firstrewcurve_non))), fliplr(nanmean(firstrewcurve_non)+nanstd(firstrewcurve_non)./sqrt(sum(~isnan(firstrewcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstrewcurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     ylim([0 2]); plot([0 0],[0 2],'k');  title(animals{a}); xlim([-40 40]);
%     for r = 1:length(xvals)
%        [p{a}(r),~]=ranksum(firstrewcurve(:,r),firstrewcurve_non(:,r)); % ttest for paired, ttest2 for unpaired
%     end
%     plot(xvals(p{a}<.05/length(xvals)),1.8*ones(sum(p{a}<.05/length(xvals)),1),'r.');
%     firstviscurve = vertcat(bytrial_firstrewvis{a}{:}); firstviscurve_non = vertcat(bytrial_firstrewvis_non{a}{:}); 
%     %valeps = ~cellfun(@isempty,bytrial_lastrew{a}) & cellfun(@(x) sum(~isnan(x)),goalarm{a})>=1;
%     %lastrewcurve = cell2mat(cellfun(@(x) x(1,:)',bytrial_lastrew{a}(valeps),'un',0))';  % just plot a single contingency#
%     %lastrewcurve_non = cell2mat(cellfun(@(x,y) x((1-1)*length(y)+[1:length(y)],:)',bytrial_lastrew_non{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
%     subplot(4,4,a+12); hold on; ylabel('visits/trial'); xlabel('trials from first reward of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstviscurve)-nanstd(firstviscurve)./sqrt(sum(~isnan(firstviscurve))), fliplr(nanmean(firstviscurve)+nanstd(firstviscurve)./sqrt(sum(~isnan(firstviscurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstviscurve),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstviscurve_non)-nanstd(firstviscurve_non)./sqrt(sum(~isnan(firstviscurve_non))), fliplr(nanmean(firstviscurve_non)+nanstd(firstviscurve_non)./sqrt(sum(~isnan(firstviscurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstviscurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     plot([0 0],[0 12],'k'); ylim([0 1.5]);   title(animals{a}); xlim([-40 40]);
%     for r = 1:length(xvals)
%        [p{a}(r),~]=ranksum(firstviscurve(:,r),firstviscurve_non(:,r)); % ttest for paired, ttest2 for unpaired
%     end
%     plot(xvals(p{a}<.05/length(xvals)),1.2*ones(sum(p{a}<.05/length(xvals)),1),'r.');
    % TRIALCURVES - aligned to last reward of cont
    xvals = -window:window;
    lastrewcurve = vertcat(bytrial_lastrew{a}{:}); lastrewcurve_non = vertcat(bytrial_lastrew_non{a}{:}); 
    subplot(4,4,a); hold on; ylabel('replay/trial'); xlabel('trials from last rew of block')
    h = fill([xvals, fliplr(xvals)], [nanmean(lastrewcurve)-nanstd(lastrewcurve)./sqrt(sum(~isnan(lastrewcurve))), fliplr(nanmean(lastrewcurve)+nanstd(lastrewcurve)./sqrt(sum(~isnan(lastrewcurve))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastrewcurve),'Color',animcol(a,:),'Linewidth',1);
    h = fill([xvals, fliplr(xvals)], [nanmean(lastrewcurve_non)-nanstd(lastrewcurve_non)./sqrt(sum(~isnan(lastrewcurve_non))), fliplr(nanmean(lastrewcurve_non)+nanstd(lastrewcurve_non)./sqrt(sum(~isnan(lastrewcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastrewcurve_non),':','Color',animcol(a,:),'Linewidth',1);
    ylim([0 2]); plot([0 0],[0 2],'k');  title(animals{a}); xlim([-40 40]);
    for r = 1:length(xvals)
       [p{a}(r),~]=ranksum(lastrewcurve(:,r),lastrewcurve_non(:,r)); % ttest for paired, ttest2 for unpaired
    end
    plot(xvals(p{a}<.05/length(xvals)),1.8*ones(sum(p{a}<.05/length(xvals)),1),'r.');
    text(-20,1.5,sprintf('n=%drew,%dunrew',size(lastrewcurve,1),size(lastrewcurve_non,1)));
    %lastrewcurve = vertcat(bytrial_lastrew{a}{:}); lastrewcurve_non = vertcat(bytrial_lastrew_non{a}{:}); 
    lastviscurve = vertcat(bytrial_lastrewvis{a}{:}); lastviscurve_non = vertcat(bytrial_lastrewvis_non{a}{:}); 
    %valeps = ~cellfun(@isempty,bytrial_lastrew{a}) & cellfun(@(x) sum(~isnan(x)),goalarm{a})>=1;
    %lastrewcurve = cell2mat(cellfun(@(x) x(1,:)',bytrial_lastrew{a}(valeps),'un',0))';  % just plot a single contingency#
    %lastrewcurve_non = cell2mat(cellfun(@(x,y) x((1-1)*length(y)+[1:length(y)],:)',bytrial_lastrew_non{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
    subplot(4,4,a+4); hold on; ylabel('visits/trial'); xlabel('trials from last reward of block')
    h = fill([xvals, fliplr(xvals)], [nanmean(lastviscurve)-nanstd(lastviscurve)./sqrt(sum(~isnan(lastviscurve))), fliplr(nanmean(lastviscurve)+nanstd(lastviscurve)./sqrt(sum(~isnan(lastviscurve))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastviscurve),'Color',animcol(a,:),'Linewidth',1);
    h = fill([xvals, fliplr(xvals)], [nanmean(lastviscurve_non)-nanstd(lastviscurve_non)./sqrt(sum(~isnan(lastviscurve_non))), fliplr(nanmean(lastviscurve_non)+nanstd(lastviscurve_non)./sqrt(sum(~isnan(lastviscurve_non))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastviscurve_non),':','Color',animcol(a,:),'Linewidth',1);
    plot([0 0],[0 12],'k'); ylim([0 1]);   title(animals{a}); xlim([-40 40]);
    for r = 1:length(xvals)
       [p{a}(r),~]=ranksum(lastviscurve(:,r),lastviscurve_non(:,r)); % ttest for paired, ttest2 for unpaired
    end
    plot(xvals(p{a}<.05/length(xvals)),.9*ones(sum(p{a}<.05/length(xvals)),1),'r.');
    clear p
    % BY CONTINGENCY
    allgoal = vertcat(realigned{a}{:}); 
    allnon = vertcat(realignednongoal{a}{:}); 
    %valeps = ~cellfun(@isempty,realigned{a}) & cellfun(@(x) any(x>5),searchlength{a}); %cellfun(@(x) sum(~isnan(x)),goalarm{a})>=2
    %allgoal = cell2mat(cellfun(@(x,y) x(y>5,:)',realigned{a}(valeps),searchlength{a}(valeps),'un',0))';  % just plot a single contingency#
    %allgoal = cell2mat(cellfun(@(x) x(2,:)',realigned{a}(valeps),'un',0))';  % just plot a single contingency#
    %allnon = cell2mat(cellfun(@(x,y) x((2-1)*length(y)+[1:length(y)],:)',realignednongoal{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
    reps = 6:11; % reps = 1:9;
    subplot(4,4,a+8); hold on; ylabel('replays/trial')
    errorbar(1:6,nanmean(allgoal(:,reps)),nanstd(allgoal(:,reps))./sqrt(sum(~isnan(allgoal(:,reps)))),'.','Color',animcol(a,:));
    bar(1:6,nanmean(allgoal(:,reps)),.3,'Facecolor',animcol(a,:));
    errorbar(1.3:6.3,nanmean(allnon(:,reps)),nanstd(allnon(:,reps))./sqrt(sum(~isnan(allnon(:,reps)))),'.','Color',animcol(a,:));
    bar(1.3:6.3,nanmean(allnon(:,reps)),.3,'Facecolor',animcol(a,:),'Facealpha',.3); ylim([0 1.5]); xlim([.5 7;]);
   
%     h = fill([reps, fliplr(reps)], [nanmean(allgoal(:,reps))-nanstd(allgoal(:,reps))./sqrt(sum(~isnan(allgoal(:,reps)))), fliplr(nanmean(allgoal(:,reps))+nanstd(allgoal(:,reps))./sqrt(sum(~isnan(allgoal(:,reps)))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(reps, nanmean(allgoal(:,reps)),'.-','Color',animcol(a,:),'Linewidth',1);
%     h = fill([reps, fliplr(reps)], [nanmean(allnon(:,reps))-nanstd(allnon(:,reps))./sqrt(sum(~isnan(allnon(:,reps)))), fliplr(nanmean(allnon(:,reps))+nanstd(allnon(:,reps))./sqrt(sum(~isnan(allnon(:,reps)))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(reps, nanmean(allnon(:,reps)),'.:','Color',animcol(a,:),'Linewidth',1);
%     ylim([0 2]); plot([5 5],[0 2],'k');  title(animals{a}); xlim([1 9]);
     for r = 1:length(reps)
       [p{a}(r),~]=ranksum(allgoal(:,reps(r)),allnon(:,reps(r))); % ranksum because nonparametric
    end
    plot(reps(p{a}<.05/length(reps))-5,.9*ones(sum(p{a}<.05/length(reps)),1),'r.'); xlabel(sprintf('n=%dconts',size(allgoal,1)));
    set(gca,'XTick',1:6,'XTickLabel',{'s1','r1','s2','r2','s3','r3'})
%     allvis = vertcat(realignedvis{a}{:}); allnonvis = vertcat(realignednongoalvis{a}{:});     
%     subplot(4,4,a+12); hold on; ylabel('visits/block')
%     errorbar(1:6,nanmean(allvis(:,reps)),nanstd(allvis(:,reps))./sqrt(sum(~isnan(allvis(:,reps)))),'.','Color',animcol(a,:));
%     bar(1:6,nanmean(allvis(:,reps)),.3,'Facecolor',animcol(a,:));
%     errorbar(1.3:6.3,nanmean(allnonvis(:,reps)),nanstd(allnonvis(:,reps))./sqrt(sum(~isnan(allnonvis(:,reps)))),'.','Color',animcol(a,:));
%     bar(1.3:6.3,nanmean(allnonvis(:,reps)),.3,'Facecolor',animcol(a,:),'Facealpha',.3); ylim([0 3]); xlim([.5 7;]);
%      for r = 1:length(reps)
%        [p{a}(r),~]=ranksum(allvis(:,r),allnonvis(:,r)); % ranksum because nonparametric
%     end
%     plot(reps(p{a}<.05/length(reps)),2*ones(sum(p{a}<.05/length(reps)),1),'r.');

%    % compare MANY VS FEW rews at goal 
%     xvals = -window:window;
%     lowrew = cell2mat(cellfun(@(x,y) x(y<=10,:)', bytrial_lastrew{a},goalnum{a},'un',0))';
%     highrew = cell2mat(cellfun(@(x,y) x(y>10,:)', bytrial_lastrew{a},goalnum{a},'un',0))'; 
%     subplot(4,4,a+12); hold on; ylabel('replay/trial'); xlabel('trials from last rew of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(lowrew)-nanstd(lowrew)./sqrt(sum(~isnan(lowrew))), fliplr(nanmean(lowrew)+nanstd(lowrew)./sqrt(sum(~isnan(lowrew))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(lowrew),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(highrew)-nanstd(highrew)./sqrt(sum(~isnan(highrew))), fliplr(nanmean(highrew)+nanstd(highrew)./sqrt(sum(~isnan(highrew))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(highrew),':','Color',animcol(a,:),'Linewidth',1); title('many vs few rews'); ylim([0 2])

    % compare first vs second contingency
%     xvals = -window:window;
%     cont1 = cell2mat(cellfun(@(x) x(1,:)', bytrial_lastrew{a},'un',0))';
%     cont2 = cell2mat(cellfun(@(x,y) x(2,:)', bytrial_lastrew{a}(cellfun(@(x) length(x),goalnum{a})>2),'un',0))'; 
%     subplot(4,4,a+12); hold on; ylabel('replay/trial'); xlabel('trials from last rew of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(cont1)-nanstd(cont1)./sqrt(sum(~isnan(cont1))), fliplr(nanmean(cont1)+nanstd(cont1)./sqrt(sum(~isnan(cont1))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(cont1),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(cont2)-nanstd(cont2)./sqrt(sum(~isnan(cont2))), fliplr(nanmean(cont2)+nanstd(cont2)./sqrt(sum(~isnan(cont2))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(cont2),':','Color',animcol(a,:),'Linewidth',1); title('1st vs 2nd'); ylim([0 2])

% correlate numgoals with count of replay in window  post cont change
%subplot(4,4,a+12); hold on; plot(horzcat(goalnum{a}{:}),horzcat(postreplaycount{a}{:}),'.','Color',animcol(a,:)); lsline
%ylabel('replaycount'); xlabel('goalnum'); title(['window=',num2str(window)]);
%[r2,pv] = corrcoef([horzcat(goalnum{a}{:})',horzcat(postreplaycount{a}{:})'],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(horzcat(postreplaycount{a}{:}))),r2(2)^2,pv(2)),'Color',animcol(a,:));

end


%% Calc mean rate of local, past, future, pg replay by trial (box vs outer & search vs rep)
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
contentthresh=.3;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];  
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
        end 
        for t=1:length(outerrips)
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end 
        
%         valtrials = ~cellfun(@isempty, replays);
%         if any(valtrials)  % [replay future past pg]
%             ripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], replays(valtrials), num2cell(outers(valtrials)), ...
%                 num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
%             ripcomb = vertcat(ripcomb{:});
%         end
%         valtrials = ~cellfun(@isempty, outerreplays);
%         if any(valtrials)
%             outerripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], outerreplays(valtrials), num2cell(outers(valtrials)), ...
%                 num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
%             outerripcomb = vertcat(outerripcomb{:});
%         end
        valtrials = ~cellfun(@isempty,replays);
        countspertrial = zeros(length(valtrials),5);  % [future past currentg previousg totalreplays]
        countspertrial(valtrials,:) = cell2mat(cellfun(@(x,fut,pst,crg,prg) [sum(x==fut), sum(x==pst), sum(x==crg), sum(x==prg), length(x)], ...
                    replays(valtrials),num2cell(outers(valtrials)),num2cell(pastwlock(valtrials))',num2cell(goals(valtrials,1)'),...
                    num2cell(goals(valtrials,2))','un',0)'); 
        valtrials = ~cellfun(@isempty,outerreplays);
        outercountspertrial = zeros(length(valtrials),5);
        outercountspertrial(valtrials,:) = cell2mat(cellfun(@(x,fut,pst,crg,prg) [sum(x==fut), sum(x==pst), sum(x==crg), sum(x==prg), length(x)], ...
                    outerreplays(valtrials),num2cell(outers(valtrials)),num2cell(pastwlock(valtrials))',num2cell(goals(valtrials,1)'),...
                    num2cell(goals(valtrials,2))','un',0)'); 

        % boxSearch boxRep outerrew
        rewouternums = tphasenum(tphasenum(:,1)>=1 & mod(tphasenum(:,1),1)==0,2);
        totaleventrate{a}(e,:) = [mean(countspertrial(tphasenum(:,1)<=1,5)),mean(countspertrial(tphasenum(:,1)>1,5)),mean(outercountspertrial(rewouternums,5))];
        % [future pg ]
        searchboxrates{a}(e,:) = [mean(countspertrial(tphasenum(:,1)<=1 & ~isnan(goals(:,2)),1)), mean(countspertrial(tphasenum(:,1)<=1 & ~isnan(goals(:,2)),4))];
        repeatboxrates{a}(e,:) = [mean(countspertrial(tphasenum(:,1)>1 & ~isnan(goals(:,2)),1)), mean(countspertrial(tphasenum(:,1)>1 & ~isnan(goals(:,2)),4))];
        % future only, [correct  err] (.9 trials count as correct 
        correcttrinums = tphasenum(~isnan(goals(:,2)) & tphasenum(:,1)>1 & (mod(tphasenum(:,1),1)==0 | mod(tphasenum(:,1),1)>.8),2);
        errtrinums = tphasenum(~isnan(goals(:,2)) & tphasenum(:,1)>1 & (mod(tphasenum(:,1),1)>0 & mod(tphasenum(:,1),1)<.9),2);
        repcorr_errboxrates{a}(e,:) = [mean(countspertrial(correcttrinums,1)), mean(countspertrial(errtrinums,1))];
        
    end
    totalp(a) = ranksum(totaleventrate{a}(:,1),totaleventrate{a}(:,2));
    %boxlocalp(a) = ranksum(boxlocalrates{a}(:,1),boxlocalrates{a}(:,2));
    searchboxp(a) = [ranksum(searchboxrates{a}(:,1),searchboxrates{a}(:,2))];
    repeatboxp(a) = [ranksum(repeatboxrates{a}(:,1),repeatboxrates{a}(:,2))];
    errboxp(a) = [ranksum(repcorr_errboxrates{a}(:,1),repcorr_errboxrates{a}(:,2))];
    
    subplot(1,4,1); hold on; title('total box events search vs rep'); ylim([0 15]);
    errorbar([a a+.5],mean(totaleventrate{a}(:,[1 2])),std(totaleventrate{a}(:,[1 2]))./sqrt(size(totaleventrate{a},1)),'k.')
    bar([a a+.5],mean(totaleventrate{a}(:,[1 2])),.8,'FaceColor',animcol(a,:));
    text([a+.3],[14],num2str(ranksum(totaleventrate{a}(:,1),totaleventrate{a}(:,2)),'%.02f'));
    subplot(1,4,[2 3]); hold on; title('future/pg search vs rep')
    errorbar([a a+6],mean(searchboxrates{a}),std(searchboxrates{a})./sqrt(size(searchboxrates{a},1)),'k.')
    bar([a a+6],mean(searchboxrates{a}),.05,'FaceColor',animcol(a,:));
    errorbar([a+.4 a+6.4],mean(repeatboxrates{a}),std(repeatboxrates{a})./sqrt(size(repeatboxrates{a},1)),'k.')
    bar([a+.4 a+6.4],mean(repeatboxrates{a}),.05,'FaceColor',animcol(a,:),'FaceAlpha',.3);
    text([a+.3 a+6.3],[1.7 1.7],num2str([ranksum(searchboxrates{a}(:,1),repeatboxrates{a}(:,1));ranksum(searchboxrates{a}(:,2),repeatboxrates{a}(:,2))],'%.02f'));
    subplot(1,4,4); hold on; title('future on correct vs error')
    errorbar([a a+.5],nanmean(repcorr_errboxrates{a}),nanstd(repcorr_errboxrates{a})./sqrt(sum(~isnan(repcorr_errboxrates{a}))),'k.')
    bar([a a+.5],nanmean(repcorr_errboxrates{a}),.8,'FaceColor',animcol(a,:));
    text([a+.3],[.8 ],num2str(ranksum(repcorr_errboxrates{a}(:,1),repcorr_errboxrates{a}(:,2)),'%.02f')); ylim([0 1]); ylabel('events/trial')
end
subplot(1,4,[2 3]); set(gca,'XTick',[3 9],'XTickLabel',{'future','pg'})
% subplot(3,2,1); hold on; 
% plot4a(totaleventrate,'gnames',{'boxser','boxrep','outerrew'}); 
% ylabel('totalevents/trial'); ylim([0 20]); text([6 7 8 9],[16 17 18 19],num2str(totalp'))
% subplot(3,2,2); hold on;
% plot4a(boxlocalrates,'gnames',{'ser','rep'}); 
% ylabel('localboxev/trial'); ylim([0 15]); text([9 10 11 12],[10 11 12 13],num2str(boxlocalp'))
% subplot(3,2,3);
% plot4a(searchboxrates,'gnames',{'future','prevgoal'}); title('search')
% ylabel('box rates'); ylim([0 3]); text([12 13 14 15],[2 2.2 2.4 2.6],num2str(searchboxp','%.03f')); 
% subplot(3,2,4);
% plot4a(repeatboxrates,'gnames',{'future','prevgoal'}); title('repeat')
% ylabel('box rates'); ylim([0 3]); text([12 13 14 15],[2 2.2 2.4 2.6],num2str(repeatboxp','%.03f')); 
% subplot(3,2,5); %plot4a(repcorr_errboxrates,'gnames',{'correct','error'}); 
% ylabel('box rates'); ylim([0 3]); text([12 13 14 15],[2 2.2 2.4 2.6],num2str(errboxp','%.03f'));title('repeat correct vs error') 
% %subplot(3,2,[5 6]); hold on;
% %plot4a(outerrates,'gnames',{'past','pg','current','box'});  ylabel('outer rates'); ylim([0 2]);

%% fit linear model of category predictors for each arm, for box and outer
clearvars -except f animals animcol
contentthresh = .3;
all = figure(); byarm = figure(); cov = figure(); set(gcf,'Position',[90 262 1822 697]); poold = figure();
search_pooled = [];  repeat_pooled = [];
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        future = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        past = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(pastwlock'),'un',0));
        prevgoal = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(goals(:,2)'),'un',0));
        currgoal = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(goals(:,1)'),'un',0));
        allsearch{a}{e} = [reshape(future(:,tphasenum(:,1)<=1),[],1),reshape(past(:,tphasenum(:,1)<=1),[],1),reshape(prevgoal(:,tphasenum(:,1)<=1),[],1) ...
                    reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [future past prevgoal #replays];
        allrepeat{a}{e} = [reshape(future(:,tphasenum(:,1)>1),[],1),reshape(past(:,tphasenum(:,1)>1),[],1),reshape(currgoal(:,tphasenum(:,1)>1),[],1) ...
                    ,reshape(prevgoal(:,tphasenum(:,1)>1),[],1), reshape(countspertrial(:,tphasenum(:,1)>1),[],1)]; % [future past currgoal prevgoal #replays];
        earlycorr = tphasenum(:,1)>1 & tphasenum(:,1)<5 & outers'==goals(:,1);
        earlycorrrepeat{a}{e} = [reshape(future(:,earlycorr),[],1),reshape(past(:,earlycorr),[],1),reshape(currgoal(:,earlycorr),[],1) ...
                    ,reshape(prevgoal(:,earlycorr),[],1), reshape(countspertrial(:,earlycorr),[],1)]; % [future past currgoal prevgoal #replays];
        latecorr = tphasenum(:,1)>4 & outers'==goals(:,1);
        latecorrrepeat{a}{e} = [reshape(future(:,latecorr ),[],1),reshape(past(:,latecorr ),[],1),reshape(currgoal(:,latecorr ),[],1) ...
                    ,reshape(prevgoal(:,latecorr ),[],1), reshape(countspertrial(:,latecorr ),[],1)]; % [future past currgoal prevgoal #replays];
        earlyerr = tphasenum(:,1)>1 & tphasenum(:,1)<5 & outers'~=goals(:,1);
        earlyerrrepeat{a}{e} = [reshape(future(:,earlyerr),[],1),reshape(past(:,earlyerr),[],1),reshape(currgoal(:,earlyerr),[],1) ...
                    ,reshape(prevgoal(:,earlyerr),[],1), reshape(countspertrial(:,earlyerr),[],1)]; % [future past currgoal prevgoal #replays];
        lateerr = tphasenum(:,1)>4 & outers'~=goals(:,1);
        lateerrrepeat{a}{e} = [reshape(future(:,lateerr ),[],1),reshape(past(:,lateerr ),[],1),reshape(currgoal(:,lateerr ),[],1) ...
                    ,reshape(prevgoal(:,lateerr ),[],1), reshape(countspertrial(:,lateerr ),[],1)]; % [future past currgoal prevgoal #replays];

        for arm = 1:8
            searchbyarm{a}{arm}{e} = [future(arm,tphasenum(:,1)<=1)',past(arm,tphasenum(:,1)<=1)',prevgoal(arm,tphasenum(:,1)<=1)',countspertrial(arm,tphasenum(:,1)<=1)'];
            repeatbyarm{a}{arm}{e} = [future(arm,tphasenum(:,1)>1)',past(arm,tphasenum(:,1)>1)',currgoal(arm,tphasenum(:,1)>1)',prevgoal(arm,tphasenum(:,1)>1)',countspertrial(arm,tphasenum(:,1)>1)'];
        end
        outercountspertrial = zeros(8,length(outers));
        outercountspertrial(:,~cellfun(@isempty,outerreplays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',outerreplays(~cellfun(@isempty,outerreplays)),'un',0));
        rewd = mod(tphasenum(:,1),1)==0 & tphasenum(:,1)>0;
        allouterrew{a}{e} = [reshape(past(:,rewd),[],1),reshape(currgoal(:,rewd),[],1), ...
                    reshape(prevgoal(:,rewd),[],1), reshape(outercountspertrial(:,rewd),[],1)]; % [ past current prevgoal #replays];

    end
    figure(all);
    searchcat = vertcat(allsearch{a}{:});
    searchtbl = table(searchcat(:,2),searchcat(:,1),searchcat(:,3),searchcat(:,4),'VariableNames',{'past','future','prevgoal','replaynum'});
    s_mdl = fitglm(searchtbl,'linear','Distribution','poisson');
    CI = coefCI(s_mdl,.01);
    subplot(1,3,1); hold on; title('allsearch')
    %errorbar(a+[0:5:19],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:19],exp(table2array(s_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(searchcat(:,1),searchcat(:,2)), corrcoef(searchcat(:,1),searchcat(:,3)), corrcoef(searchcat(:,2),searchcat(:,3))];
    %searchr2(a, :)=cr(1,[2 4 6]).^2;
    text(5,2+.2*a,['trial n=',num2str(size(searchcat,1)/8)],'Color',animcol(a,:));
    repeatcat = vertcat(allrepeat{a}{:});
    reptbl = table(repeatcat(:,2),repeatcat(:,1),repeatcat(:,3),repeatcat(:,4),repeatcat(:,5),'VariableNames',{'past','future','currgoal','prevgoal','replaynum'});
    r_mdl = fitglm(reptbl,'linear','Distribution','poisson'); 
    CI = coefCI(r_mdl,.01);
    subplot(1,3,2); hold on; title('allrepeat')
    %errorbar(a+[0:5:24],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:24],exp(table2array(r_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(repeatcat(:,1),repeatcat(:,2)), corrcoef(repeatcat(:,1),repeatcat(:,3)),corrcoef(repeatcat(:,1),repeatcat(:,4)), ...
    %    corrcoef(repeatcat(:,2),repeatcat(:,3)), corrcoef(repeatcat(:,2),repeatcat(:,4)),corrcoef(repeatcat(:,3),repeatcat(:,4))];
    %repr2(a,:)=cr(1,[2:2:12]).^2;
    %text(5,2+.2*a,['f vs cg corrcoef=',num2str(cr(2),'%.03f')],'Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(repeatcat,1)/8)],'Color',animcol(a,:));
    outercat = vertcat(allouterrew{a}{:});
    mdl = fitglm(outercat(:,1:3),outercat(:,4),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    subplot(1,3,3); hold on; title('outer rewarded')
    plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(outercat,1)/8)],'Color',animcol(a,:));
    
    figure(cov);
    % note that predictors haven't be reordered to match main figs (future past cg pg)
    subplot(2,4,a); imagesc(1:3,1:3,corrcov(s_mdl.CoefficientCovariance(2:end,2:end))); caxis([-1 1])
    set(gca,'ytick',1:3,'xticklabel',{'pst','fut','pg'},'yticklabel',{'fut','pst','pg'}); colorbar; title('search')
    nums = sprintfc('%.02f',corrcov(s_mdl.CoefficientCovariance(2:end,2:end)));
    [x,y] = meshgrid(1:3,1:3); text(x(:),y(:),nums,'horizontalalignment','center','verticalalignment','middle')
    subplot(2,4,a+4); imagesc(corrcov(r_mdl.CoefficientCovariance(2:end,2:end))); caxis([-1 1])
    colorbar; set(gca,'xticklabel',{'pst','fut','cg','pg'},'yticklabel',{'fut','pst','cg','pg'}); title('rep')
    nums = sprintfc('%.02f',corrcov(r_mdl.CoefficientCovariance(2:end,2:end)));
    [x,y] = meshgrid(1:4,1:4); text(x(:),y(:),nums,'horizontalalignment','center','verticalalignment','middle')
  
    search_pooled = [search_pooled;searchcat]; repeat_pooled = [repeat_pooled;repeatcat];
    figure(byarm);  
%     subplot(2,2,[1:2]); hold on; 
%     reptbl = table(repeatcat(:,1),repeatcat(:,2),repeatcat(:,3),repeatcat(:,4),repeatcat(:,5),'VariableNames',{'future','past','currgoal','prevgoal','replaynum'});
%     modelspec = 'replaynum ~ future + past +currgoal + prevgoal  + future:currgoal'; %
%     mdl = fitglm(reptbl,modelspec,'Distribution','poisson'); 
%     coefinds = 1:6;
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))<.05),ones(sum(table2array(mdl.Coefficients(:,4))<.05),1),'*','Color',animcol(a,:)); 
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))>=.05),zeros(sum(table2array(mdl.Coefficients(:,4))>=.05),1),'o','Color',animcol(a,:)); 
%     set(gca,'XTickLabel',{'int','future','past','currg','pg','f+cg'})
%     subplot(2,2,3); hold on;
%     [sims,simCI] = predict(mdl,[1 0 1 0; 1 0 0 0; 0 0 1 0; 0 0 0 0]);
%     plot(a/5+[1:4],sims, 'ko'); plot(a/5+[1:4;1:4],simCI','Color',animcol(a,:)); set(gca,'XTickLabel',{'f+ cg+','f+ cg-','f- cg+','f-cg-'})
     
%subplot(2,2,4); hold on;
    %[sims,simCI] = predict(mdl,[1 0 1; 1 0 0; 0 0 1; 0 0 0]);
    %plot(a/5+[1:4],sims, 'ko'); plot(a/5+[1:4;1:4],simCI','Color',animcol(a,:)); set(gca,'XTickLabel',{'f+ pg+','f+ pg-','f- pg+','f-pg-'})
%    
%     reptbl = table(repeatcat(:,1),repeatcat(:,2),repeatcat(:,3),repeatcat(:,4),repeatcat(:,5),'VariableNames',{'future','past','currgoal','prevgoal','replaynum'});
%     modelspec = 'replaynum ~ future + past + currgoal + prevgoal  + future:currgoal + future:past+ future:prevgoal + past:currgoal +past:prevgoal'; %
%     mdl = fitglm(reptbl,modelspec,'Distribution','poisson'); 
%     coefinds = 1:10;
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))<.05),ones(sum(table2array(mdl.Coefficients(:,4))<.05),1),'*','Color',animcol(a,:)); 
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))>=.05),zeros(sum(table2array(mdl.Coefficients(:,4))>=.05),1),'o','Color',animcol(a,:)); 
%     set(gca,'XTickLabel',{'int','future','past','currg','pg','f+p','f+cg','p+cg','f+pg','p+pg'})
%     subplot(3,1,2); hold on;
%     modelspec = 'replaynum ~ future + past + currgoal + prevgoal  + future:currgoal + future:past';%
%     mdl = fitglm(reptbl,modelspec,'Distribution','poisson'); 
%     coefinds = 1:7;
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))<.05),ones(sum(table2array(mdl.Coefficients(:,4))<.05),1),'*','Color',animcol(a,:)); 
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))>=.05),zeros(sum(table2array(mdl.Coefficients(:,4))>=.05),1),'o','Color',animcol(a,:)); 
%     set(gca,'XTickLabel',{'int','future','past','currg','pg','f+p','f+cg'})
%     subplot(3,1,3); hold on;
%     modelspec = 'replaynum ~ future + past + currgoal + prevgoal  + future:currgoal ';%
%     mdl = fitglm(reptbl,modelspec,'Distribution','poisson'); 
%     coefinds = 1:6;
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))<.05),ones(sum(table2array(mdl.Coefficients(:,4))<.05),1),'*','Color',animcol(a,:)); 
%     plot(a/5+coefinds(table2array(mdl.Coefficients(:,4))>=.05),zeros(sum(table2array(mdl.Coefficients(:,4))>=.05),1),'o','Color',animcol(a,:)); 
%     set(gca,'XTickLabel',{'int','future','past','currg','pg','f+cg'})
   %     [sims,simCI] = predict(mdl,[1 0 1 0; 1 0 0 0; 0 0 1 0; 0 0 0 0]);
%     plot(1:4,sims, '.'); plot([1:4;1:4],simCI','k'); set(gca,'XTickLabel',{'f+ cg+','f+ cg-','f- cg+','f-cg-'})
%     subplot(1,2,2); hold on;
%     [sims,simCI] = predict(mdl,[1 1 1 0; 1 0 1 0; 0 1 1 0; 0 0 1 0]);
%     plot(1:4,sims, '.'); plot([1:4;1:4],simCI','k'); set(gca,'XTickLabel',{'f+ p+','f+ p-','f- p+','f-p-'})
%     mdl2 = step(mdl,'NSteps',5)
%     plotSlice(mdl)
%     plotInteraction(mdl,'future','past')
%     CI = coefCI(mdl,.01);
%     plot(a+[0:5:29],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:29];a+[0:5:29]],exp(CI)','Color',animcol(a,:)); %title('repeat f cg diff')

% OLD FIG S5
%     subplot(1,2,1); hold on;
%     fcgdiffcat = vertcat(fcgdiffrepeat{a}{:}); fcgsamecat = vertcat(fcgsamerepeat{a}{:});
%     mdl = fitglm(fcgdiffcat(:,[2 1 3 4]),fcgdiffcat(:,5),'linear','Distribution','poisson'); 
%     CI = coefCI(mdl,.01);
%     plot(a+[0:5:24],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:)); title('repeat f cg diff')
%     text(5,2+.2*a,['n=',num2str(size(fcgdiffcat,1))],'Color',animcol(a,:));
%     subplot(1,2,2); hold on;
%     % Note that each time you subsample fcgsame, you will get a slightly different result
%     %subset = randi(size(fcgsamecat,1),size(fcgdiffcat,1),1);
%     %mdl = fitglm(fcgsamecat(subset,[2:4]),fcgsamecat(subset,5),'linear','Distribution','poisson'); 
%     mdl = fitglm(fcgsamecat(:,[2:4]),fcgsamecat(:,5),'linear','Distribution','poisson'); 
%     CI = coefCI(mdl,.01);
%     plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:)); title('repeat f cg same')
%     text(5,2+.2*a,['n=',num2str(size(fcgsamecat,1))],'Color',animcol(a,:));
%     %text(5,2+.2*a,['n=',num2str(size(fcgsamecat(subset,:),1))],'Color',animcol(a,:));

    subplot(3,2,1); hold on;
    earlycorr = vertcat(earlycorrrepeat{a}{:}); latecorr = vertcat(latecorrrepeat{a}{:});
    earlyerr = vertcat(earlyerrrepeat{a}{:}); lateerr = vertcat(lateerrrepeat{a}{:});
    mdl = fitglm([earlycorr(:,[2 1 3 4]);earlyerr(:,[2 1 3 4])],[earlycorr(:,5);earlyerr(:,5)],'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:24],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:)); title('repeat early (<5) all')
    text(5,2+.2*a,['trial n=',num2str(size([earlycorr;earlyerr],1)/8)],'Color',animcol(a,:));
    subplot(3,2,2); hold on;
    mdl = fitglm([latecorr(:,[2 1 3 4]);lateerr(:,[2 1 3 4])],[latecorr(:,5);lateerr(:,5)],'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:24],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:)); title('repeat late (5+) all')
    text(5,2+.2*a,['trial n=',num2str(size([latecorr;lateerr],1)/8)],'Color',animcol(a,:));
    subplot(3,2,3); hold on;
    mdl = fitglm(earlycorr(:,[2:4]),earlycorr(:,5),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:)); title('repeat early (<5) corr')
    text(5,2+.2*a,['trial n=',num2str(size(earlycorr,1)/8)],'Color',animcol(a,:));
    subplot(3,2,4); hold on;
    mdl = fitglm(latecorr(:,[2:4]),latecorr(:,5),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:)); title('repeat late (5+) corr')
    text(5,2+.2*a,['trial n=',num2str(size(latecorr,1)/8)],'Color',animcol(a,:));
    subplot(3,2,5); hold on;
    mdl = fitglm(earlyerr(:,[2 1 3 4]),earlyerr(:,5),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:24],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:)); title('repeat early (<5) err')
    text(5,2+.2*a,['trial n=',num2str(size(earlyerr,1)/8)],'Color',animcol(a,:));
    subplot(3,2,6); hold on;
    mdl = fitglm(lateerr(:,[2 1 3 4]),lateerr(:,5),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    plot(a+[0:5:24],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:)); title('repeat late (5+) err')
    text(5,2+.2*a,['trial n=',num2str(size(lateerr,1)/8)],'Color',animcol(a,:));

%     mdl = fitglm(repeatcat(:,[1,2,4]),repeatcat(:,5),'linear','Distribution','poisson'); 
%     CI = coefCI(mdl,.01);
%     plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:)); title('future only')
%     text(5,2+.2*a,['AIC=',num2str(mdl.ModelCriterion.AIC,'%.03f')],'Color',animcol(a,:));
%     subplot(1,2,2); hold on; title('currgoal only')
%     mdl = fitglm(repeatcat(:,[2:4]),repeatcat(:,5),'linear','Distribution','poisson'); 
%     CI = coefCI(mdl,.01);
%     plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
%     text(5,2+.2*a,['AIC=',num2str(mdl.ModelCriterion.AIC,'%.03f')],'Color',animcol(a,:));

%     figure(byarm);
%     for arm = 1:8
%         subplot(2,4,a); hold on; title([animals{a},'searchbyarm']);
%         searchcat = vertcat(searchbyarm{a}{arm}{:});
%         mdl = fitglm(searchcat(:,1:3),searchcat(:,4),'linear','Distribution','poisson');
%         errorbar(arm+[0:11:43],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
%         subplot(2,4,a+4); hold on; title([animals{a},'repbyarm']);
%         repeatcat = vertcat(repeatbyarm{a}{arm}{:});
%         mdl = fitglm(repeatcat(:,1:4),repeatcat(:,5),'linear','Distribution','poisson');
%         errorbar(arm+[0:11:54],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
%     end
%     subplot(2,4,a); xlim([0 43]); set(gca,'XTick',5.5+[0:11:43],'XTickLabel',{'int','fut','pst','pg'})
%     subplot(2,4,a+4); xlim([0 53]);set(gca,'XTick',5.5+[0:11:54],'XTickLabel',{'int','fut','pst','cg','pg'})
end
figure(all)
subplot(1,3,1); xlim([0 20]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:19],'XTickLabel',{'intrcpt','past','future','prevgoal'})
plot([0 20],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);
subplot(1,3,2); set(gca,'YScale','log'); ylim([.4 3]); xlim([0 25]);set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','curgoal','prevgoal'})
plot([0 25],[1 1],'k:');
subplot(1,3,3); set(gca,'YScale','log'); ylim([.7 20]); xlim([0 20]);set(gca,'XTick',2+[0:5:20],'XTickLabel',{'intrcpt','past','current','prevgoal'})
plot([0 20],[1 1],'k:'); ylabel('[.7 20]')

figure(poold)
s_tbl = table(search_pooled(:,2),search_pooled(:,1),search_pooled(:,3),search_pooled(:,4),'VariableNames',{'past','future','prevgoal','replaynum'});
s_mdl = fitglm(s_tbl,'linear','Distribution','poisson'); 
CI = coefCI(s_mdl,.01);
subplot(1,2,1); hold on; title('pooledsearch')
plot([0:5:19],exp(table2array(s_mdl.Coefficients(:,1))),'k.','MarkerSize',20);
plot([[0:5:19];[0:5:19]],exp(CI)','k');
text(5,2,['trial n=',num2str(size(search_pooled,1)/8)]);
text(1,1.5,mat2str(exp(table2array(s_mdl.Coefficients(:,1)))',3)) %'%.03f'
text(1,1.4,mat2str(exp(CI(:,1))',3)) %'%.03f'
text(1,1.3,mat2str(exp(CI(:,2))',3)) %set(gca,'YScale','log'); 
r_tbl = table(repeat_pooled(:,2),repeat_pooled(:,1),repeat_pooled(:,3),repeat_pooled(:,4),repeat_pooled(:,5),'VariableNames',{'past','future','currgoal','prevgoal','replaynum'});
r_mdl = fitglm(r_tbl,'linear','Distribution','poisson'); 
CI = coefCI(r_mdl,.01);
subplot(1,2,2); hold on; title('pooledrepeat')
plot([0:5:24],exp(table2array(r_mdl.Coefficients(:,1))),'k.','MarkerSize',20);
plot([[0:5:24];[0:5:24]],exp(CI)','k');
text(5,2,['trial n=',num2str(size(repeat_pooled,1)/8)]);
text(1,1.5,mat2str(exp(table2array(r_mdl.Coefficients(:,1)))',3)) %'%.03f'
text(1,1.4,mat2str(exp(CI(:,1))',3)) %'%.03f'
text(1,1.3,mat2str(exp(CI(:,2))',3)) %

figure(byarm)
subplot(3,2,1); xlim([0 25]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','currgoal','prevgoal'})
plot([0 25],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 3]);
subplot(3,2,2); xlim([0 25]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','currgoal','prevgoal'})
plot([0 25],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 3]);
subplot(3,2,3); xlim([0 20]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:19],'XTickLabel',{'intrcpt','past','currgoal','prevgoal'})
plot([0 20],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 4]);
subplot(3,2,4); xlim([0 20]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:19],'XTickLabel',{'intrcpt','past','currgoal','prevgoal'})
plot([0 20],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 4]);
subplot(3,2,5); xlim([0 25]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','currgoal','prevgoal'})
plot([0 25],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 4]);
subplot(3,2,6); xlim([0 25]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','currgoal','prevgoal'})
plot([0 25],[1 1],'k:'); set(gca,'YScale','log'); ylim([.3 4]);

% save correlations (r2) to csv for supplementary table
%csvwrite('search_glm_r2table.txt',searchr2);
%csvwrite('repeat_glm_r2table.txt',repr2);

% sanity checks for the model
% randpred = randi([0 1],size(searchcat,1),3);
% randpred = searchcat(randperm(size(searchcat,1)),1:3);
% replay = zeros(size(searchcat,1),1); replay(searchcat(:,3)==1)=randi([1 2],sum(searchcat(:,3)==1),1); replay(searchcat(:,2)==1)=randi([1 2],sum(searchcat(:,2)==1),1);
% mdl = fitglm(searchcat(:,1:3),replay,'linear','Distribution','poisson'); CI = coefCI(mdl,.01);
% mdl = fitglm(randpred,searchcat(:,4),'linear','Distribution','poisson'); CI = coefCI(mdl,.01);
% figure; hold on; 
% plot(1:4,table2array(mdl.Coefficients(:,1)),'.','MarkerSize',20,'Color',animcol(a,:));
% plot([1:4;1:4],CI','Color',animcol(a,:));
%simresponse = random(mdl,searchcat(:,1:3));
%[simres,simCI] = predict(mdl,searchcat(:,1:3));
%[simres,simCI] = predict(mdl,[0 1 0],'Alpha',.01)
% mdl = fitglm(searchcat(:,1:3),searchcat(:,4),'linear','Distribution','poisson');
% aic(1) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,1),searchcat(:,4),'linear','Distribution','poisson');
% aic(2) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,2),searchcat(:,4),'linear','Distribution','poisson');
% aic(3) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,3),searchcat(:,4),'linear','Distribution','poisson');
% aic(4) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,1:2),searchcat(:,4),'linear','Distribution','poisson');
% aic(5) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,[1,3]),searchcat(:,4),'linear','Distribution','poisson');
% aic(6) = mdl.ModelCriterion.AIC;
% mdl = fitglm(searchcat(:,2:3),searchcat(:,4),'linear','Distribution','poisson');
% aic(7) = mdl.ModelCriterion.AIC;
% figure; plot(aic,'ro'); ylabel('AIC');
% set(gca,'XTickLabel',{'all','future','past','pg','futpast','futpg','pastpg'},'XTickLabelRotation',45)
%% correlations by trial window rather than contingency =
clearvars -except f animals animcol
figure; set(gcf,'Position',[675 1 1202 973]);  plt=1;
contentthresh = .3;
window = 25; %trials for trialcurves
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        cont = f(a).output{1}(eps(e)).trips.contingency;
        valtrials = cont<=8;  % don't use any part of the epoch with repeat goals
        cont=cont(valtrials);
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase(valtrials), [1:length(goals)]'];   % add trial numbers
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
               valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        ind=1;
        for c = 1:max(cont)  % for each contingency, count search and repeat phases separately
            searchreplays = replays(cont==c & tphasenum(:,1)<=1);  
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(searchreplays),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)<=1),1,8);
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)<=1),[1:9]);
                ecp{a}{e}(ind,:) = [e, c, 1]; % epoch cont phase (search=1, repeat=2);
                goalarm{a}{e}(ind) = nan;
                if ind==1
                goalreplay{a}{e}(ind,:) = [nan sum(replaycount{a}{e}(ind,:))];
                cumgoalreplay{a}{e}(ind,:) = goalreplay{a}{e}(ind,:);
                else
                    goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                end
            ind = ind+1;
            
            if any(cont==c & tphasenum(:,1)==4)  % needs to earn at least 4 goals for this cont to count
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(replays(cont==c & tphasenum(:,1)>1)),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)>1),1,8);
                goalarm{a}{e}(ind) = goals(cont==c & tphasenum(:,1)==1); % convenient to use first trial to indicate goal
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)>1),[1:9]);
                ecp{a}{e}(ind,:) = [e c 2]; % epoch cont phase (search=1, repeat=2);
                goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                searchlength{a}{e}(c) = sum(cont==c & tphasenum(:,1)<1); % if complete cont, store search length for later
            else % not enough of this goal experienced
                replaycount{a}{e}(ind,:) = nan(1,8);
                trialcount{a}{e}(ind,:) = nan(1,8);
                visitcount{a}{e}(ind,:) = nan(1,8);
                goalarm{a}{e}(ind) = nan; 
                ecp{a}{e}(ind,:) = [nan nan nan]; % epoch cont phase (search=1, repeat=2);
                goalreplay{a}{e}(ind,:) = [nan nan]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = [nan nan];
            end
            ind = ind+1;
        end
        replaypertrial{a}{e} = [nan(4,8); replaycount{a}{e}./trialcount{a}{e}; nan(6,8)];  % pad with nans for alignment
        goalarm{a}{e} = [nan(1,4), goalarm{a}{e},nan(1,6)];
        visitcount{a}{e} = [nan(4,8); visitcount{a}{e}; nan(6,8)];  
        goallist = unique(goalarm{a}{e}(~isnan(goalarm{a}{e})),'stable');
        nevergoals{a}{e} = find(~ismember([1:8],goallist));
        realignednongoal{a}{e} = [];
        realignednongoalvis{a}{e} = [];
        bytrial_firstrew_non{a}{e} = [];
        bytrial_lastrew_non{a}{e} = [];
        bytrial_start_non{a}{e} = [];
        bytrial_firstrewvis_non{a}{e} = [];
        bytrial_lastrewvis_non{a}{e} = [];
        for c = 1:length(goallist)
            inds = [-4+find(goalarm{a}{e}==goallist(c)):find(goalarm{a}{e}==goallist(c))+6];
            realigned{a}{e}(c,:) = replaypertrial{a}{e}(inds,goallist(c));
            realignedvis{a}{e}(c,:) = visitcount{a}{e}(inds,goallist(c));
            if ~isempty(nevergoals{a}{e})
            %randnongoal = randi(length(nevergoals{a}{e}));  % choose a random unrewarded arm
            %allbutgoal = find(goallist(c)~=[1:8]);
            realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,nevergoals{a}{e})']; % add all nonrewarded arms to list
            %realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,allbutgoal)']; % add all nonrewarded arms to list
            realignednongoalvis{a}{e} = [realignednongoalvis{a}{e}; visitcount{a}{e}(inds,nevergoals{a}{e})'];
            end
            goalnum{a}{e}(c) = sum(tphasenum(cont==c,1)>=1 & mod(tphasenum(cont==c,1),1)==0);
            % trialwise curves (aligned to first and last reward of cont)
            start = find(cont==c & tphasenum(:,1)==1);
            firstinds = start-window:start+window;
            bytrial_firstrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrew{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= countspertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            bytrial_firstrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrewvis{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= vispertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            start= find(cont==c & tphasenum(:,1)==max(tphasenum(cont==c & mod(tphasenum(:,1),1)==0,1)));
            lastinds = start-window:start+window;
            bytrial_lastrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrew{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= countspertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            bytrial_lastrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrewvis{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= vispertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            %post-cont replay/visit count
            if sum(lastinds>start & lastinds<=length(outers))==window % only collect data if all trials available
                postreplaycount{a}{e}(c) = sum(countspertrial(goallist(c),lastinds(lastinds>start+1 & lastinds<=length(outers))));
                postviscount{a}{e}(c) = sum(vispertrial(goallist(c),lastinds(lastinds>start+1 & lastinds<=length(outers)))); 
            else
                postreplaycount{a}{e}(c) = nan;
                postviscount{a}{e}(c) = nan;
            end
            
            start= find(cont==c,1);
            startinds = start-window:start+window;
            bytrial_start{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_start{a}{e}(c,find(startinds>0 & startinds<=length(outers)))= countspertrial(goallist(c),startinds(startinds>0 & startinds<=length(outers)));
        end
    end   
% correlate numgoals with count of replay in window  post cont change
subplot(4,4,a); hold on; plot(horzcat(goalnum{a}{:}),horzcat(postreplaycount{a}{:}),'.','Color',animcol(a,:)); lsline
ylabel('replaycount'); xlabel('goalnum'); title(['window=',num2str(window)]);
[r2,pv] = corrcoef([horzcat(goalnum{a}{:})',horzcat(postreplaycount{a}{:})'],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(horzcat(postreplaycount{a}{:}))),r2(2)^2,pv(2)),'Color',animcol(a,:));

subplot(4,4,a+4); hold on; plot(horzcat(postviscount{a}{:}),horzcat(postreplaycount{a}{:}),'.','Color',animcol(a,:)); lsline
ylabel('replaycount'); xlabel('visitcount'); title(['window=',num2str(window)]);
[r2,pv] = corrcoef([horzcat(postviscount{a}{:})',horzcat(postreplaycount{a}{:})'],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(horzcat(postreplaycount{a}{:}))),r2(2)^2,pv(2)),'Color',animcol(a,:));

end

%%  measure lag between replay and future visit
clearvars -except f animals animcol
bars = figure();  set(gcf,'Position',[110 446 1747 518]); %reg = figure();
contentthresh = .3;
plt=1;
sinceedges = [-40:1];
untiledges = [0:40];
kernel = gaussian(1,5);
window =50;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
   
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(tphasenum(:,1)<=1,1) = nan; % turn currgoals during search trials into nans
        goals(goals(:,1)==0,1) = nan;
        goals(mod(tphasenum(:,1),1)>.85,:) = goals(find(mod(tphasenum(:,1),1)>.85)-1,:); % fix the last visit of cont (.9) to not reflect new goal yet
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastNOlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,1);  % only consider the including lockout option
        trialstack  = [outers', pastNOlock, goals,tphasenum(:,1)];
        clear replays outerreplays recency pgvisit
        for t=1:length(rips)  % extract valid rips and tack on trial info: [replay future past currgoal prevgoal ppgoal tphase salient local]
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} =[ind(valid)-1]; %,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==0];
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = [ind(valid)-1]; %,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[0,trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==trialstack(t,1)]; % include box as salient
                %if any(valid)
                %    outerreplays{t}(outerreplays{t}(:,9)==1,8) = 0; % correct salience to not include local events
                %end
            else outerreplays{t} = []; end
            % for each arm, calc trialdist to/from visit, categorize and replayed, salient 
            for r = 1:8  %[since until boxreplayed outerreplayed salient]
                if any(outers(1:t-1)==r)
                    recency{t}(r,1) = -(t-find(outers(1:t-1)==r,1,'last'));
                else recency{t}(r,1) = nan; end
                if any(outers(t+1:end)==r)
                    recency{t}(r,2) = find(outers(t:end)==r,1,'first');
                else recency{t}(r,2) = nan; end
                recency{t}(r,[3 4]) = [sum(r==replays{t}) sum(r==outerreplays{t})];
                recency{t}(r,5) = ismember(r,trialstack(1:t,4));  % salient= any previously rewarded arm (OR just prevgoal any(r==trialstack(t,4)))
            end
            % is this trial a visit to previous goal and if so, is there pgreplay? future replay? [pgvis pgreplay futurereplay]
            pgoals = goals(t,2);  % nans still included, but doesnt matter
            if any(pgoals)
                pgvisit(t,:) = [any(outers(t)==pgoals) any(intersect(replays{t},pgoals)) any(replays{t}==outers(t))];
            else pgvisit(t,:) = [nan nan any(replays{t}==outers(t))];
            end
        end
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        %for r = 1:8; countspertrial(r,:) = smoothvect(countspertrial(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        % group recency into 1,2,3,4,5+
        recencypertrial = cellfun(@(x) [abs(x(:,1))==1,abs(x(:,1))==2,abs(x(:,1))==3,abs(x(:,1))==4,abs(x(:,1))>=5] ,recency,'un',0);
        untilpertrial = cellfun(@(x) [x(:,2)==1,x(:,2)==2,x(:,2)==3,x(:,2)==4,x(:,2)>=5] ,recency,'un',0);
        allsearchrecency{a}{e} = [vertcat(recencypertrial{tphasenum(:,1)<=1}), reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [recency #replays];
        allsearchuntil{a}{e} = [vertcat(untilpertrial{tphasenum(:,1)<=1}), reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [until #replays];

         %for each search trial, plot replay count curve
        goallist = unique(goals(~isnan(goals(:,1)),1),'stable');
        %tri = find(tphasenum(:,1)<1 & ~ismember(outers,goallist)'); %
        tri = find(outers'==goals(:,2) & tphasenum(:,1)<1);
%         tri = [];
%         for r = 1:8
%             if any(outers==r)
%                 tri = [tri find(outers==r,1,'first')];
%             end
%         end
        for t = 1:length(tri)
            inds = tri(t)-window:tri(t)+window;
            searchcurve{a}{e}(t,:) = nan(1,2*window+1);
            searchcurve{a}{e}(t,find(inds>0 & inds<=length(outers)))= countspertrial(outers(tri(t)),inds(inds>0 & inds<=length(outers)));
            visitcurve{a}{e}(t,:) = nan(1,2*window+1);
            visitcurve{a}{e}(t,find(inds>0 & inds<=length(outers)))= vispertrial(outers(tri(t)),inds(inds>0 & inds<=length(outers)));
        end
        clear tri
        
        since_replayed_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==1,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_replayed_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==1,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_non_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==1,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_non_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==1,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_replayed_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==0,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_replayed_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==0,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_non_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==0,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_non_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==0,2)',recency,'un',0)),untiledges,'Normalization','probability');
        
        % what fraction of -x recencies get replayed? [-1, -2, -3, -4, -5, any];
        recencyfrac{a}(e,:) = [mean(cellfun(@(x) x(x(:,1)==-1,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-1 & x(:,5)==0),recency)'))), ...
                               mean(cellfun(@(x) x(x(:,1)==-2,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-2 & x(:,5)==0),recency)'))), ...
                                mean(cellfun(@(x) x(x(:,1)==-3,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-3 & x(:,5)==0),recency)'))), ...
                                mean(cellfun(@(x) x(x(:,1)==-4,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-4 & x(:,5)==0),recency)'))), ...
                                mean(cell2mat(cellfun(@(x) x(x(:,1)<=-5,3)',recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)<=-5 & x(:,5)==0),recency)'),'un',0)))];
        %recencyfrac{a}(e,:) = [mean(cellfun(@(x) x(x(:,1)==-1,3),recency(2:end))),mean(cellfun(@(x) x(x(:,1)==-2,3),recency(cellfun(@(x) any(x(:,1)==-2),recency)))), ...
        %            mean(cellfun(@(x) x(x(:,1)==-3,3),recency(cellfun(@(x) any(x(:,1)==-3),recency)))), mean(cell2mat(cellfun(@(x) x(x(:,1)<0,3)',recency(2:end),'un',0)))];
       
        % what fraction of possible pgreplay prevgoal visits are preceded by a replay pgvisit = [pgvis pgreplay futurereplay]
        % fraction of pg visits with replay compared to fraction of other visits with pgreplay = similar chance of pgreplay whether your about to  visit it or not
        %[fracpgvis with replay/totalpgvis, othervis with pgreplay/possiblepgvis. nonpgfuturerep/nonpgvistrials
        fracpg{a}(e,:) = [sum(pgvisit(:,3)>0 & pgvisit(:,1)>0)/sum(pgvisit(:,1)>0), sum(pgvisit(:,2)==1 &  pgvisit(:,1)==0)/sum(pgvisit(:,1)==0)]; %, sum(pgvisit(:,3)>0 & pgvisit(:,1)~=1)/sum(pgvisit(:,1)~=1) don't bother with overall futurefrac
    end
    % replay curves 
%     allcurve = vertcat(searchcurve{a}{:}); xvals = -window:window;
%     subplot(2,4,a); hold on; ylabel('replays/trial'); xlabel('trials from unrewarded visit (nevergoals)')
%     h = fill([xvals, fliplr(xvals)], [nanmean(allcurve)-nanstd(allcurve)./sqrt(sum(~isnan(allcurve))), fliplr(nanmean(allcurve)+nanstd(allcurve)./sqrt(sum(~isnan(allcurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(allcurve),'.-','Color',animcol(a,:),'Linewidth',1);
%     %h = fill([xvals, fliplr(xvals)], [nanmean(allcurve_non)-nanstd(allcurve_non)./sqrt(sum(~isnan(allcurve_non))), fliplr(nanmean(allcurve_non)+nanstd(allcurve_non)./sqrt(sum(~isnan(allcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     %set(h,'EdgeColor','none'); plot(xvals, nanmean(allcurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     plot([0 0],[0 1],'k'); ylim([0 1]);   title(animals{a}); xlim([-window window]);
%     %for r = 1:length(xvals)
%     %   [p{a}(r),~]=ranksum(firstviscurve(:,r),firstviscurve_non(:,r)); % ttest for paired, ttest2 for unpaired
%     %end
%     %plot(xvals(p{a}<.05/length(xvals)),1.2*ones(sum(p{a}<.05/length(xvals)),1),'r.');
%     viscurve = vertcat(visitcurve{a}{:}); xvals = -window:window;
%     subplot(2,4,a+4); hold on; ylabel('visits/trial'); xlabel('trials from unrewarded visit (nevergoals)')
%     h = fill([xvals, fliplr(xvals)], [nanmean(viscurve)-nanstd(viscurve)./sqrt(sum(~isnan(viscurve))), fliplr(nanmean(viscurve)+nanstd(viscurve)./sqrt(sum(~isnan(viscurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(viscurve),'.-','Color',animcol(a,:),'Linewidth',1);
%     %h = fill([xvals, fliplr(xvals)], [nanmean(allcurve_non)-nanstd(allcurve_non)./sqrt(sum(~isnan(allcurve_non))), fliplr(nanmean(allcurve_non)+nanstd(allcurve_non)./sqrt(sum(~isnan(allcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     %set(h,'EdgeColor','none'); plot(xvals, nanmean(allcurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     plot([0 0],[0 1],'k'); ylim([0 1]);   title(animals{a}); xlim([-window window]);

    % recency curves
%     subplot(4,4,a); hold on; h = fill([sinceedges(1:end-1), fliplr(sinceedges(1:end-1))], [mean(since_replayed_sal{a})-std(since_replayed_sal{a})./sqrt(sum(~isnan(since_replayed_sal{a}))), fliplr(mean(since_replayed_sal{a})+std(since_replayed_sal{a})./sqrt(sum(~isnan(since_replayed_sal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(sinceedges(1:end-1), mean(since_replayed_sal{a}),'.-','Color',animcol(a,:),'Linewidth',1);
%     h = fill([sinceedges(1:end-1), fliplr(sinceedges(1:end-1))], [mean(since_non_sal{a})-std(since_non_sal{a})./sqrt(sum(~isnan(since_non_sal{a}))), fliplr(mean(since_non_sal{a})+std(since_non_sal{a})./sqrt(sum(~isnan(since_non_sal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(sinceedges(1:end-1), mean(since_non_sal{a}),'.:','Color',animcol(a,:),'Linewidth',1); title('since salient'); xlim([-10 0]);
%     subplot(4,4,a+4); hold on; h = fill([untiledges(1:end-1), fliplr(untiledges(1:end-1))], [mean(until_replayed_sal{a})-std(until_replayed_sal{a})./sqrt(sum(~isnan(until_replayed_sal{a}))), fliplr(mean(until_replayed_sal{a})+std(until_replayed_sal{a})./sqrt(sum(~isnan(until_replayed_sal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(untiledges(1:end-1), mean(until_replayed_sal{a}),'.-','Color',animcol(a,:),'Linewidth',1);
%     h = fill([untiledges(1:end-1), fliplr(untiledges(1:end-1))], [mean(until_non_sal{a})-std(until_non_sal{a})./sqrt(sum(~isnan(until_non_sal{a}))), fliplr(mean(until_non_sal{a})+std(until_non_sal{a})./sqrt(sum(~isnan(until_non_sal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(untiledges(1:end-1), mean(until_non_sal{a}),'.:','Color',animcol(a,:),'Linewidth',1);title('until salient'); xlim([0 10]);
    
%     subplot(2,4,a); hold on; h = fill([sinceedges(1:end-1), fliplr(sinceedges(1:end-1))], [mean(since_replayed_nonsal{a})-std(since_replayed_nonsal{a})./sqrt(sum(~isnan(since_replayed_nonsal{a}))), fliplr(mean(since_replayed_nonsal{a})+std(since_replayed_nonsal{a})./sqrt(sum(~isnan(since_replayed_nonsal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(sinceedges(1:end-1), mean(since_replayed_nonsal{a}),'.-','Color',animcol(a,:),'Linewidth',1);
%     h = fill([sinceedges(1:end-1), fliplr(sinceedges(1:end-1))], [nanmean(since_non_nonsal{a})-nanstd(since_non_nonsal{a})./sqrt(sum(~isnan(since_non_nonsal{a}))), fliplr(nanmean(since_non_nonsal{a})+nanstd(since_non_nonsal{a})./sqrt(sum(~isnan(since_non_nonsal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(sinceedges(1:end-1), nanmean(since_non_nonsal{a}),'.:','Color',animcol(a,:),'Linewidth',1); title('since, nonsalient'); xlim([-10 0]); ylim([0 .2])
%     for r = 1:length(sinceedges)-1
%        [p{a}(r),~]=ranksum(since_replayed_nonsal{a}(:,r),since_non_nonsal{a}(:,r)); 
%     end
%     plot(sinceedges(p{a}<.05/(length(sinceedges)-1)),.18*ones(sum(p{a}<.05/(length(sinceedges)-1)),1),'r.');
%     subplot(2,4,a+4); hold on; h = fill([untiledges(1:end-1), fliplr(untiledges(1:end-1))], [mean(until_replayed_nonsal{a})-std(until_replayed_nonsal{a})./sqrt(sum(~isnan(until_replayed_nonsal{a}))), fliplr(mean(until_replayed_nonsal{a})+std(until_replayed_nonsal{a})./sqrt(sum(~isnan(until_replayed_nonsal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(untiledges(1:end-1), mean(until_replayed_nonsal{a}),'.-','Color',animcol(a,:),'Linewidth',1);
%     h = fill([untiledges(1:end-1), fliplr(untiledges(1:end-1))], [mean(until_non_nonsal{a})-std(until_non_nonsal{a})./sqrt(sum(~isnan(until_non_nonsal{a}))), fliplr(mean(until_non_nonsal{a})+std(until_non_nonsal{a})./sqrt(sum(~isnan(until_non_nonsal{a}))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(untiledges(1:end-1), mean(until_non_nonsal{a}),'.:','Color',animcol(a,:),'Linewidth',1); title('until, nonsalient'); xlim([0 10]); xlabel('trials'); ylim([0 .2])
%     for r = 1:length(untiledges)-1
%        [p{a}(r),~]=ranksum(until_replayed_nonsal{a}(:,r),until_non_nonsal{a}(:,r)); 
%     end
%     plot(untiledges(p{a}<.05/(length(untiledges)-1)),.18*ones(sum(p{a}<.05/(length(untiledges)-1)),1),'r.');
figure(bars)
    subplot(2,4,a); hold on; %boxplot(recencyfrac{a},'Color',animcol(a,:),'Symbol','','Notch','on')
    errorbar(1:5, nanmean(recencyfrac{a}),nanstd(recencyfrac{a})/sqrt(length(eps)),'Color',animcol(a,:),'Linestyle','none');
    bar(1:5, nanmean(recencyfrac{a}),.5,'Facecolor',animcol(a,:)  );
    for r = 1:4
        [p{a}(r),~]=ranksum(recencyfrac{a}(:,r),recencyfrac{a}(:,5));
    end
    text([1:4],[.5 .6 .7 .8],num2str(p{a}','%.03f')); ylim([0 1]); ylabel('replayrate'); xlabel('recency'); xlim([0 6]);

    subplot(2,4,a+4); hold on;
    %boxplot(fracpg{a},'Color',animcol(a,:),'Symbol','','Notch','on')
    errorbar([1 2], nanmean(fracpg{a}),nanstd(fracpg{a})/sqrt(length(eps)),'Color',animcol(a,:),'Linestyle','none');
    bar([1 2], nanmean(fracpg{a}),.5,'Facecolor',animcol(a,:)  );
    p{a} = [ranksum(fracpg{a}(:,1),fracpg{a}(:,2))]; %,ranksum(fracpg{a}(:,1),fracpg{a}(:,3))
    text([1 ],[.9],num2str(p{a}')); ylim([0 1]); set(gca, 'xticklabel',{'','pgvisit','othervisit',''}); ylabel('frac of trials with pgreplay');
% figure(reg)
%     searchcat = vertcat(allsearchrecency{a}{:});
%     mdl = fitglm(searchcat(:,1:5),searchcat(:,6),'linear','Distribution','poisson');
%     CI = coefCI(mdl,.01);
%     subplot(1,2,1); hold on; title('recency')
%     plot(a+[0:5:29],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:29];a+[0:5:29]],exp(CI)','Color',animcol(a,:));
%     searchcat = vertcat(allsearchuntil{a}{:});
%     mdl = fitglm(searchcat(:,1:5),searchcat(:,6),'linear','Distribution','poisson');
%     CI = coefCI(mdl,.01);
%     subplot(1,2,2); hold on; title('until')
%     plot(a+[0:5:29],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:29];a+[0:5:29]],exp(CI)','Color',animcol(a,:));

end
%figure(bars);
% title('pgvisitswithpgreplay, othervisitswithpgreplay, othervisitswithfuturereplay'); 
%  figure(reg)
%  subplot(1,2,1); xlim([0 30]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:29],'XTickLabel',{'intrcpt','1','2','3','4','5+'})
% plot([0 30],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);
% subplot(1,2,2); xlim([0 30]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:29],'XTickLabel',{'intrcpt','1','2','3','4','5+'})
% plot([0 30],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);

%plot4a(fracpg,'gnames',{'pgvisitwithrep','otherviswithpgrep','nonpgvisfuturerep'}); ylim([0 1])
 

%% characterize trials that contain prevgoal replays 
figure; set(gcf,'Position',[37 518, 1526,420]);
ttypeedges = [-1 0 1 2 3 5 8 16];
numedges = [1 2 3 4 5 8 10 17 40];
for a = 1:length(animals)
    %figure; set(gcf,'Position',[1008 1009 663 833]);
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        hasrips = ~cellfun(@isempty,rips)';
        replays = cell(length(hasrips),1);
        for h = 1:length(hasrips)
            if hasrips(h)
                [maxval,ind] = max(rips{h},[],2);
                valid = maxval>.3 & types{h}==1;
                replays{h} = [ind(valid)-1]; %, maxval(valid)
            end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        valtrials = ~cellfun(@isempty, replays);
        ripcomb = cellfun(@(x,y,z,g,h) [x, repmat([y,z,g,h,length(x)],length(x),1)], replays(valtrials), num2cell(outers(valtrials))', ...
                num2cell(pastwlock(valtrials)), num2cell(goals(valtrials,:),2),num2cell(tphasenum(valtrials,:),2),'un',0);
         abovethresh = vertcat(ripcomb{:});
         %[1replay 2future 3past(withlock) 4curgoal 5prevgoal 6ppgoal 7tphase 8tnum 9numrips]
        other = abovethresh(:,1)~=abovethresh(:,5) & abovethresh(:,1)~=abovethresh(:,2) & abovethresh(:,1)~=abovethresh(:,3);
        pgoaltype{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,5),7),ttypeedges,'Normalization','probability');
        futuretype{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,2),7),ttypeedges,'Normalization','probability');
        pasttype{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,3),7),ttypeedges,'Normalization','probability');
        othertype{a}(e,:) = histcounts(abovethresh(other,7),ttypeedges,'Normalization','probability');
        
        pgoalnums{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,5),9),numedges,'Normalization','probability');
        futurenums{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,2),9),numedges,'Normalization','probability');
        pastnums{a}(e,:) = histcounts(abovethresh(abovethresh(:,1)==abovethresh(:,3),9),numedges,'Normalization','probability');
        othernums{a}(e,:) = histcounts(abovethresh(other,9),numedges,'Normalization','probability');
        
        if any(outers'==goals(:,2))
        pgoaltrialfrac{a}(e,:) = [sum(cellfun(@(x) sum(x(:,1)==x(:,5)),ripcomb)>0)/length(replays), ...
            sum(cellfun(@(x) sum(x(:,1)==x(:,5) & x(:,2)==x(:,5)),ripcomb)>0)/sum(outers(valtrials)'==goals(valtrials,2))...
            sum(cellfun(@(x) sum(x(:,1)==x(:,5) & x(:,2)~=x(:,5)),ripcomb)>0)/sum(outers(valtrials)'~=goals(valtrials,2))...
            sum(tphasenum(valtrials,1)<=1 & outers(valtrials)'==goals((valtrials),2) & cellfun(@(x) sum(x(:,1)==x(:,5)),ripcomb)>0)/sum(tphasenum((valtrials),1)<=1 & outers(valtrials)'==goals((valtrials),2)),...
            sum(tphasenum(valtrials,1)>1 & outers(valtrials)'==goals((valtrials),2) & cellfun(@(x) sum(x(:,1)==x(:,5)),ripcomb)>0)/sum(tphasenum((valtrials),1)>1 & outers(valtrials)'==goals((valtrials),2))];
        else
            pgoaltrialfrac{a}(e,:) = [nan nan nan nan nan];
        end
    end
    [~,p_pgfracvsnon(a)] = ttest(pgoaltrialfrac{a}(:,2),pgoaltrialfrac{a}(:,3));
    subplot(2,length(animals),a); hold on; bar(ttypeedges(1:end-1),[mean(pgoaltype{a}); mean(futuretype{a}); mean(pasttype{a}); mean(othertype{a})]','grouped'); title(animals{a}); xlabel('trialtype')
    subplot(2,length(animals),a+length(animals)); hold on; bar(numedges(1:end-1),[mean(pgoalnums{a}); mean(futurenums{a}); mean(pastnums{a}); mean(othernums{a})]','grouped'); title(animals{a}); xlabel('numrips')
end
legend({'pgoal','future','past','other'})
figure; plot4a(pgoaltrialfrac,'gnames',{'all','pgvisits','nonpgvisits','pgsearch','pgrepeat'});
text([10 10 10 10],[.6 .7 .8 .9],num2str(p_pgfracvsnon'))

%% quantify contingency corelations between pgoal numreps and pgoal replays  
clearvars -except f animals
figure; set(gcf,'Position',[71 205 1526 677]);
animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols
contentthresh = .3;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        cont = f(a).output{1}(eps(e)).trips.contingency;
        valtrials = ~isnan(cont);  % don't use any part of the epoch with repeat goals
        cont=cont(valtrials);
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase(valtrials), [1:length(goals)]'];   % add trial numbers
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
               valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        conts = unique(cont(~isnan(cont)));
        %if last cont is incomplete, get rid of it
        while sum(tphasenum(cont==max(conts),1)>3)==0
            conts = conts(1:end-1);
        end
        for c = 1:length(conts)  % for each contingency, count search and repeat phases separately
            ctrials{a}{e}(c,:) = [sum(tphasenum(cont==c,1)<=1), sum(tphasenum(cont==c,1)>1)];% [search repeat]
            crewards{a}{e}(c) = sum(tphasenum(cont==c,1)>=1 & mod(tphasenum(cont==c,1),1)==0);
            if c==1
                priorpgoalreplay{a}{e}(c,:) = [nan,nan];  %pgoal replay of previous cont
                pgrewards{a}{e}(c) = nan; 
                pgoalreplay{a}{e}(c,:) = [nan,nan];
                priorpgoalvisits{a}{e}(c,:) = [nan, nan]; %pgoal visit of previous cont
                pgoalvisits{a}{e}(c,:) = [nan,nan];   % visits to pgoal of this cont
                ppgvisits{a}{e}(c,:) = [nan, nan];  % visits to ppg this cont
                ppgrewards{a}{e}(c) = nan;
                ppgoalreplay{a}{e}(c,:) = [nan,nan];
            else
                priorpgoalreplay{a}{e}(c,:) = pgoalreplay{a}{e}(c-1,:);
                priorpgoalvisits{a}{e}(c,:) = pgoalvisits{a}{e}(c-1,:);
                pgrewards{a}{e}(c) = crewards{a}{e}(c-1);
                pgoalvisits{a}{e}(c,:) = [sum(outers(cont==c)'==goals(cont==c,2) & tphasenum(cont==c,1)<=1),sum(outers(cont==c)'==goals(cont==c,2) & tphasenum(cont==c,1)>1)];
                pgoalreplay{a}{e}(c,:) = [sum(cellfun(@(x,y) sum(x==y),replays(cont==c & tphasenum(:,1)<=1),num2cell(goals(cont==c & tphasenum(:,1)<=1,2))')),...
                    sum(cellfun(@(x,y) sum(x==y),replays(cont==c & tphasenum(:,1)>1),num2cell(goals(cont==c & tphasenum(:,1)>1,2))'))];
                if c>2
                    ppgrewards{a}{e}(c) = crewards{a}{e}(c-2);
                    ppgoalreplay{a}{e}(c,:) = [sum(cellfun(@(x,y) sum(x==y),replays(cont==c & tphasenum(:,1)<=1),num2cell(goals(cont==c & tphasenum(:,1)<=1,3))')),...
                        sum(cellfun(@(x,y) sum(x==y),replays(cont==c & tphasenum(:,1)>1),num2cell(goals(cont==c & tphasenum(:,1)>1,3))'))];
                    ppgvisits{a}{e}(c,:) = [sum(outers(cont==c)'==goals(cont==c,3) & tphasenum(cont==c,1)<=1),sum(outers(cont==c)'==goals(cont==c,3) & tphasenum(cont==c,1)>1)];
                else
                    ppgrewards{a}{e}(c) = nan;
                    ppgoalreplay{a}{e}(c,:) = [nan,nan];
                    ppgvisits{a}{e}(c,:) = [nan,nan];
                end
            end
        end
    end
    % pgoal reward # correlated with pgoal replay
    allpgrewards = horzcat(pgrewards{a}{:})'; 
%     % allpgreplayrate = cell2mat(cellfun(@(x,y) sum(x,2)'./sum(y,2)',pgoalreplay{a},ctrials{a},'un',0))';  %search+rep
%     allpgreplayrate = cell2mat(cellfun(@(x,y) x(:,1)'./y(:,1)',pgoalreplay{a},ctrials{a},'un',0))';  % search only
%     subplot(2,4,a); hold on; plot(allpgrewards,allpgreplayrate,'.','Color',animcol(a,:)); 
%     %plot(priorrewards{a},totalpgreplays{a}(:,1),'.','Color',animcol(a,:)); 
%     lsline; xlabel('#pgoalrewards'); xlim([0 20]); ylim([0 4]); title(animals{a}); ylabel('pgreplayrate search+rep')
%     [r2,p] = corrcoef([allpgrewards,allpgreplayrate],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(allpgrewards)),r2(2)^2,p(2)),'Color',animcol(a,:));
%     plotinds = find(allpgrewards>=14); 
%     subplot(2,4,a+4); hold on; plot(plotinds,allpgreplayrate(plotinds,:),'.','Color','k'); lsline; ylim([0 80]);
%     [r2,p] = corrcoef([plotinds,allpgreplayrate(plotinds,:)],'rows','complete'); text(5,3,sprintf('15n=%d,r2=%.03f,p=%.03f',length(plotinds),r2(2)^2,p(2)),'Color','k');
%     plotinds = find(allpgrewards==10); % note that these could also be during the 4-12 phase
%     plot(plotinds,allpgreplayrate(plotinds,:),'.','Color','r'); lsline; ylim([0 4]);
%     [r2,p] = corrcoef([plotinds,allpgreplayrate(plotinds,:)],'rows','complete'); text(5,3,sprintf('10n=%d,r2=%.03f,p=%.03f',length(plotinds),r2(2)^2,p(2)),'Color','r');

    
    % pgoal replay correlated with visits
    allpgreplayrate = cell2mat(cellfun(@(x,y) x(:,1)'./y(:,1)',pgoalreplay{a},ctrials{a},'un',0))'; %rate during search
    allvisits = vertcat(pgoalvisits{a}{:});
    subplot(2,4,a); hold on; plot(allvisits(:,1),allpgreplayrate,'.','Color',animcol(a,:)); 
    lsline; xlabel('#pgoalvisits search'); ylabel('pgreplayrate search'); xlim([0 10]); ylim([0 5]); title(animals{a})
    [r2,p] = corrcoef([allvisits(:,1),allpgreplayrate],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(allpgreplayrate)),r2(2)^2,p(2)),'Color',animcol(a,:));
    
    allpgreplayrate = cell2mat(cellfun(@(x,y) sum(x,2)'./sum(y,2)',pgoalreplay{a},ctrials{a},'un',0))';  %search+rep
    subplot(2,4,a+4); hold on; plot(sum(allvisits,2),allpgreplayrate,'.','Color',animcol(a,:)); 
    [r2,p] = corrcoef([sum(allvisits,2),allpgreplayrate],'rows','complete'); text(5,3,sprintf('n=%d,r2=%.03f,p=%.03f',sum(~isnan(allpgreplayrate)),r2(2)^2,p(2)),'Color',animcol(a,:));
    lsline; xlabel('#pgoalvisits search+rep'); ylabel('pgreplayrate search+rep'); xlim([0 10]); ylim([0 5]); 
    %plotinds = find(priorrewards{a}==10); % note that these could also be during the 4-12 phase
    %plot(plotinds,totalpgreplays{a}(plotinds,2)./ctrials{a}(plotinds,2),'.','Color','r'); lsline; ylim([0 5]);
    %[r2,p] = corrcoef([plotinds',totalpgreplays{a}(plotinds,2)./ctrials{a}(plotinds,2)],'rows','complete'); text(5,2,sprintf('10n=%d,r2=%.03f,p=%.03f',length(plotinds),r2(2)^2,p(2)),'Color','r');
end
%print(figname,'-depsc','-painters')           
                
%% Can we find times whether the behavior and the value changes are decoupled?
% - multiple errors in a row in the middle of a contingency
% - switching before receiving the unrewarded trial
clearvars -except f animals animcol
contentthresh=.3;
kernel = gaussian(1,5);
window =20;
figure; set(gcf,'Position',[110 446 1747 518])
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    manyerr{a} = [];
    earlyend(a) = 0;
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]']; 
        cont = f(a).output{1}(eps(e)).trips.contingency(valtrials);
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        clear replays 
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t}(:,2:end),[],2); 
                ind(maxval<contentthresh) = 0;  % if <contentthresh in arms, ind should be box; no longer need ind-1
                maxval(maxval<contentthresh) = rips{t}(maxval<contentthresh,1);
                valid = types{t}==1 & maxval>=contentthresh;
                replays{t} = [ind(valid)]';
            else replays{t} = []; end
        end 
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        %for r = 1:8; countspertrial(r,:) = smoothvect(countspertrial(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        goallist = goals(diff([goals(:,1);0])~=0);
        % contingencies with 3+ errors in a row
        for c = 1:max(cont)
            reptrials = tphasenum(cont==c & tphasenum(:,1)>1);
            errspan = diff(find([1; mod(reptrials, 1)==0]));
            errspanstarts = find(errspan>4); %4+ separation between rewards
            for er = 1:length(errspanstarts) % note that this doesn't actually save multiple per cont, it overwrites with the latest one
                starttri = find(tphasenum(:,1)==errspanstarts(er) & cont==c);
                inds = starttri-window:starttri+window;
                errstart{a}{e}(c) = errspanstarts(er);
                numerrs{a}{e}(c) = errspan(errspanstarts(er))-1;
                goalrate{a}{e}(c) = sum(countspertrial(goallist(c),starttri+1:starttri+numerrs{a}{e}(c)))/numerrs{a}{e}(c);
                if errspanstarts(er)<=3
                earlyerrcurve{a}{e}(c,:) = nan(1,2*window+1);
                earlyerrcurve{a}{e}(c,find(inds>0 & inds<=length(outers)))= countspertrial(goallist(c),inds(inds>0 & inds<=length(outers)));
                earlyerrdur{a}{e}(c,:) = zeros(1,2*window+1);
                earlyerrdur{a}{e}(c,window+2:window+errspan(errspanstarts(er))) = 1;  % window +1 is previous rewarded, errspan is 1>num errs
                else
                lateerrcurve{a}{e}(c,:) = nan(1,2*window+1);
                lateerrcurve{a}{e}(c,find(inds>0 & inds<=length(outers)))= countspertrial(goallist(c),inds(inds>0 & inds<=length(outers)));
                lateerrdur{a}{e}(c,:) = zeros(1,2*window+1);
                lateerrdur{a}{e}(c,window+2:window+errspan(errspanstarts(er))) = 1;  % window +1 is previous rewarded, errspan is 1>num errs
                end
            end
            if ~any(errspan>2) & length(reptrials)>4
                goalratectrl{a}{e}(c,:) = [1,sum(countspertrial(goallist(c),find(cont==c & tphasenum(:,1)>1)))/length(reptrials)];
            end
            if c>1
                searchtrials = find(cont==c & tphasenum(:,1)<=1);
                if length(searchtrials)>=2 && sum(outers(searchtrials(1:2))==goals(searchtrials(1),2))==0 % no persev in first 2 trials
                    nopersrate{a}{e}(c,:) = [1 sum(countspertrial(goallist(c-1),searchtrials(1:2)))/2]; % indicates that there is an entry here (otherwise could later get ride of real zeros)
                    inds = searchtrials(1)-window:searchtrials(1)+window;
                    noperscurve{a}{e}(c,:) = nan(1,2*window+1);
                    noperscurve{a}{e}(c,find(inds>0 & inds<=length(outers)))= countspertrial(goallist(c-1),inds(inds>0 & inds<=length(outers)));
                elseif length(searchtrials)>=2 && sum(outers(searchtrials(1:2))==goals(searchtrials(1),2))==1 && outers(searchtrials(1))==goals(searchtrials(1),2)
                    pers1rate{a}{e}(c,:) = [1 sum(countspertrial(goallist(c-1),searchtrials(1:2)))/2];                    
                    inds = searchtrials(1)-window:searchtrials(1)+window;
                    pers1curve{a}{e}(c,:) = nan(1,2*window+1);
                    pers1curve{a}{e}(c,find(inds>0 & inds<=length(outers)))= countspertrial(goallist(c-1),inds(inds>0 & inds<=length(outers)));
               elseif length(searchtrials)>=2 && sum(outers(searchtrials(1:2))==goals(searchtrials(1),2))==2 
                    pers2rate{a}{e}(c,:) = [1 sum(countspertrial(goallist(c-1),searchtrials(1:2)))/2];
                    inds = searchtrials(1)-window:searchtrials(1)+window;
                    pers2curve{a}{e}(c,:) = nan(1,2*window+1);
                    pers2curve{a}{e}(c,find(inds>0 & inds<=length(outers)))= countspertrial(goallist(c-1),inds(inds>0 & inds<=length(outers)));
                end
            end
            
        end
    end
    split = 3;
    allerrstart = horzcat(errstart{a}{:}); allgoalrate = horzcat(goalrate{a}{:});
    allgoalrate = allgoalrate(allerrstart>0); allerrstart = allerrstart(allerrstart>0);
    tmp = vertcat(goalratectrl{a}{:}); noconserrs = tmp(tmp(:,1)==1,2);
    subplot(1,2,1); hold on; title('no consecutive errs vs early vs late (>3goals in)')
    errorbar([a-.4 a-.2 a],[mean(noconserrs), mean(allgoalrate(allerrstart<=split)),mean(allgoalrate(allerrstart>split))],[std(noconserrs)/sqrt(length(noconserrs)), std(allgoalrate(allerrstart<=split))/sqrt(sum(allerrstart<=split)),std(allgoalrate(allerrstart>split))/sqrt(sum(allerrstart>split))],'k.');
    bar([a-.4 a-.2 a],[mean(noconserrs), mean(allgoalrate(allerrstart<=split)),mean(allgoalrate(allerrstart>split))],.5,'Facecolor',animcol(a,:));
    p(1) = ranksum(noconserrs,allgoalrate(allerrstart<=split)); p(2) = ranksum(noconserrs,allgoalrate(allerrstart>split)); 
    text([a-.4 a],[1.2 1.2],num2str(p','%.03f')); ylabel('currgoal replay rate')
    text(a-.4,2,sprintf('n=%d,%d,%d',length(noconserrs),sum(allerrstart<=split),sum(allerrstart>split)));
    nopers = vertcat(nopersrate{a}{:}); nopers = nopers(nopers(:,1)==1,2);
    pers1 = vertcat(pers1rate{a}{:}); pers1 = pers1(pers1(:,1)==1,2);
    pers2 = vertcat(pers2rate{a}{:}); pers2 = pers2(pers2(:,1)==1,2);
    subplot(1,2,2); hold on; title('no persev vs pers1 vs pers2')
    errorbar([a-.4 a-.2 a],[mean(nopers), mean(pers1),mean(pers2)],[std(nopers)/sqrt(length(nopers)), std(pers1)/sqrt(length(pers1)),std(pers2)/sqrt(length(pers2))],'k.');
    bar([a-.4 a-.2 a],[mean(nopers), mean(pers1),mean(pers2)],.5,'Facecolor',animcol(a,:));
    p(1) = ranksum(nopers,pers1); p(2) = ranksum(nopers,pers2); 
    text([a-.4 a],[1.2 1.2],num2str(p','%.02f')); ylabel('prevgoal replay rate'); 
    text(a-.4,1.7,sprintf('n=%d,%d,%d',length(nopers),length(pers1),length(pers2))); ylim([0 2.5])

    %   allearlycurves = vertcat(earlyerrcurve{a}{:});
%     allearlycurves = allearlycurves(sum(allearlycurves,2)~=0,:);
%     subplot(2,4,a); hold on; plot([0 0],[0 4],'r'); title([animals{a},' 4+ errors'])
%     %plot(repmat(-window:window,size(allcurves,1),1)',allcurves','Color',[.7 .7 .7]); 
%     %plot([-window:window],nanmean(allcurves),'Color',animcol(a,:),'Linewidth',2);
%     errorshadeline([-window:window],nanmean(allearlycurves),nanstd(allearlycurves)./sqrt(sum(~isnan(allearlycurves))),'clr',animcol(a,:),'lnstyle',':');
%     alllatecurves = vertcat(lateerrcurve{a}{:});
%     alllatecurves = alllatecurves(sum(alllatecurves,2)~=0,:);
%     %plot(repmat(-window:window,size(allcurves,1),1)',allcurves','Color',[.7 .7 .7]); plot([0 0],[0 4],'r');
%     %plot([-window:window],nanmean(allcurves),'Color',animcol(a,:),'Linewidth',2);
%     errorshadeline([-window:window],nanmean(alllatecurves),nanstd(alllatecurves)./sqrt(sum(~isnan(alllatecurves))),'clr',animcol(a,:),'lnstyle','-');
%     xlabel(sprintf('earlyn=%d,late n=%d',size(allearlycurves,1),size(alllatecurves,1)))
%     try
%     subplot(2,4,a+4); hold on; plot([0 0],[0 3],'r'); title('perseverative starts')
%     allnoperscurves = vertcat(noperscurve{a}{:}); allnoperscurves = allnoperscurves(sum(allnoperscurves,2)~=0,:);
%     errorshadeline([-window:window],nanmean(allnoperscurves),nanstd(allnoperscurves)./sqrt(sum(~isnan(allnoperscurves))),'clr',animcol(a,:),'lnstyle','-');
%     all1perscurves = vertcat(pers1curve{a}{:}); all1perscurves = all1perscurves(sum(all1perscurves,2)~=0,:);
%     errorshadeline([-window:window],nanmean(all1perscurves),nanstd(all1perscurves)./sqrt(sum(~isnan(all1perscurves))),'clr',animcol(a,:),'lnstyle','--');
%     all2perscurves = vertcat(pers2curve{a}{:}); all2perscurves = all2perscurves(sum(all2perscurves,2)~=0,:);
%     errorshadeline([-window:window],nanmean(all2perscurves),nanstd(all2perscurves)./sqrt(sum(~isnan(all2perscurves))),'clr',animcol(a,:),'lnstyle',':');
%     xlabel(sprintf('0,1,2n=%d,%d,%d',size(allnoperscurves,1),size(all1perscurves,1),size(all2perscurves,1)))
%     end
end


%% fit linear model of replayed arms to predict correct/incorrect (repeat only)
clearvars -except f animals animcol
contentthresh = .3;
figure;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);   
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(mod(tphasenum(:,1),1)>.85,:) = goals(find(mod(tphasenum(:,1),1)>.85)-1,:); % fix the last visit of cont (.9) to not reflect new goal yet
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        countspertrial = zeros(length(outers),4);
        valtrials = ~cellfun(@isempty,replays);
        countspertrial(valtrials,:) = cell2mat(cellfun(@(x,fut,pst,crg,prg) [sum(x==fut), sum(x==pst), sum(x==crg), sum(x==prg)], ...
                    replays(valtrials),num2cell(outers(valtrials)),num2cell(pastwlock(valtrials))',num2cell(goals(valtrials,1)'),...
                    num2cell(goals(valtrials,2))','un',0)'); 
        valtrials = tphasenum(:,1)>1 ; %& ~isnan(goals(:,2))
        % [future past currg prevg correct/err early/late goalnum]
        allrep{a}{e} = [countspertrial(valtrials,:), (mod(tphasenum(valtrials,1),1)==0 |mod(tphasenum(valtrials,1),1)>.85),tphasenum(valtrials,1)<5, tphasenum(valtrials,1)];   
    end
    repcat = vertcat(allrep{a}{:});
    corr = repcat(repcat(:,5)==1,:);
    subsamp = [repcat(repcat(:,5)==0,:);corr(randperm(size(corr,1),sum(repcat(:,5)==0)),:)]; %match number of corr and err trials
    folds = 5;
    cv = cvpartition(size(subsamp,1),'kfold',folds);
    for k = 1:folds
        mdl = fitglm(subsamp(cv.training(k),1),subsamp(cv.training(k),5),'linear','Distribution','binomial');
        sim = random(mdl,subsamp(cv.test(k),1));
        mcr_future(k) = mean(sim~=subsamp(cv.test(k),5));
        p_future(k) = table2array(mdl.Coefficients(2,4));
        mdl = fitglm(subsamp(cv.training(k),3),subsamp(cv.training(k),5),'linear','Distribution','binomial');
        sim = random(mdl,subsamp(cv.test(k),3));
        mcr_cg(k) = mean(sim~=subsamp(cv.test(k),5));
        p_cg(k) = table2array(mdl.Coefficients(2,4));
%         mdl = fitglm(subsamp(cv.training(k),[1:4]),subsamp(cv.training(k),5),'linear','Distribution','binomial');
%         sim = random(mdl,subsamp(cv.test(k),[1:4]));
%         mcr_all(k) = mean(sim~=subsamp(cv.test(k),5));
    end
    ci99 = tinv([.005 .995],folds-1); 
    mcr_futureCI = (std(mcr_future)/sqrt(folds))*ci99;
    mcr_cgCI = (std(mcr_cg)/sqrt(folds))*ci99;
    %mcr_allCI = (std(mcr_all)/sqrt(folds))*ci99;
    subplot(3,4,[1:2]);hold on; title('future early (incl1stcont')
    earlycorr = repcat(:,5)==1 & repcat(:,6)==1;
    latecorr = repcat(:,5)==1 & repcat(:,6)==0;
    earlyerr = repcat(:,5)==0 & repcat(:,6)==1;
    lateerr = repcat(:,5)==0 & repcat(:,6)==0;
    errorbar(a+[0 .3],[mean(repcat(earlycorr,1)),mean(repcat(earlyerr,1))],[std(repcat(earlycorr,1))./sqrt(sum(earlycorr)), std(repcat(earlyerr,1))./sqrt(sum(earlyerr))],'k.');
    bar(a+[0 .3],[mean(repcat(earlycorr,1)),mean(repcat(earlyerr,1))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(earlycorr,1),repcat(earlyerr,1)),sum(earlycorr),sum(earlyerr));
    text(a,1.5,wrds);  ylim([0 2])
    subplot(3,4,[3:4]);hold on; title('future late')
    errorbar(a+[0 .3],[mean(repcat(latecorr,1)),mean(repcat(lateerr,1))],[std(repcat(latecorr,1))./sqrt(sum(latecorr)), std(repcat(lateerr,1))./sqrt(sum(lateerr))],'k.');
    bar(a+[0 .3],[mean(repcat(latecorr,1)),mean(repcat(lateerr,1))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(latecorr,1),repcat(lateerr,1)),sum(latecorr),sum(lateerr));
    text(a,1.5,wrds);  ylim([0 2])
    subplot(3,4,[5:6]); hold on; title('currgoal early')
    errorbar(a+[0 .3],[mean(repcat(earlycorr,3)),mean(repcat(earlyerr,3))],[std(repcat(earlycorr,3))./sqrt(sum(earlycorr)), std(repcat(earlyerr,3))./sqrt(sum(earlyerr))],'k.');
    bar(a+[0 .3],[mean(repcat(earlycorr,3)),mean(repcat(earlyerr,3))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(earlycorr,3),repcat(earlyerr,3)),sum(earlycorr),sum(earlyerr));
    text(a,1.5,wrds);  ylim([0 2])
    subplot(3,4,[7 8]); hold on; title('currgoal late')
    errorbar(a+[0 .3],[mean(repcat(latecorr,3)),mean(repcat(lateerr,3))],[std(repcat(latecorr,3))./sqrt(sum(latecorr)), std(repcat(lateerr,3))./sqrt(sum(lateerr))],'k.');
    bar(a+[0 .3],[mean(repcat(latecorr,3)),mean(repcat(lateerr,3))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(latecorr,3),repcat(lateerr,3)),sum(latecorr),sum(lateerr));
    text(a,1.5,wrds);  ylim([0 2])
   
    subplot(3,4,[9 10]); hold on;
    ints = 2:16;
    [means,sds,counts] = grpstats(repcat(repcat(:,5)==1,3),ceil(repcat(repcat(:,5)==1,7)),{'mean','std','numel'});
    plot(ints(counts>=10),means(counts>=10),'.','Color',animcol(a,:));lsline %plot([2:16;2:16],[means+sds, means-sds]','Color',animcol(a,:));
    [r,p] = corrcoef(repcat(repcat(:,5)==1,3),ceil(repcat(repcat(:,5)==1,7)));
    wrds = sprintf('r2=%.03f,p=%.04f,n=%d',r(2)^2,p(2),sum(repcat(:,5)==1));
    text(1,1+a/5,wrds); ylim([0 2]); ylabel('goal replay rate'); xlabel('visit #'); title('corronly, >=10 trials')
%       subplot(3,4,[9 10]);hold on;
%     plot(a,mean(mcr_future),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a;a],mean(mcr_future)+mcr_futureCI','Color',animcol(a,:));
%     text(a,.6+a/15,['n=',num2str(size(subsamp,1))]);
%     subplot(3,4,[11 12]); hold on;
%     plot(a,mean(mcr_cg),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a;a],mean(mcr_cg)+mcr_cgCI','Color',animcol(a,:));

end
%subplot(3,4,[9 10]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('future only'); ylabel('misclassification rate')
%subplot(3,4,[11 12]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('currgoal only'); xlabel('99% CI')

%5testdata = [randi([1 12],100,1),zeros(100,1); randi([10 22],100,1),ones(100,1)];


%% 
figure
for a =1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        ripsizes{a}(e,:) = histcounts(f(a).output{1}(eps(e)).riptsz(:,3),[1:.5:10]); %,'Normalization','probability'
    end
    subplot(4,1,a); hold on
    bar(.2+[1:.5:9.5],mean(ripsizes{a}),'FaceColor',animcol(a,:),'FaceAlpha',.3)
end

% how many lockout trials contain a valid outer visit?
animals = {'jaq','roquefort','despereaux','montague'};  %,, 'remy',};%};
for a = 1:length(animals)
    destdir = sprintf('/mnt/stelmo/anna/%s/filterframework/',animals{a});
    
    %import rips etc
    trials = loaddatastruct(destdir,animals{a},'trials');
    task = loaddatastruct(destdir,animals{a},'task');
    eps = evaluatefilter(task,'isequal($type,''run'')'); %
    for de = 1:size(eps,1)
        d=eps(de,1); e = eps(de,2);
        count{a}(de,:) = [sum(trials{d}{e}.outerwell(trials{d}{e}.locktype>0)>0), sum(trials{d}{e}.outersuccess(trials{d}{e}.locktype>0))]; %,length(trials{d}{e}.outerwell)];
    end
end
figure; plot4a(count,'style','dots')

