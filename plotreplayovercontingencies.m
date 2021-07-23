%%  measure replay rate of an arm during contingencies before during/after it is goal
% assumes that f from dfs_ripcontent is pre-run

clearvars -except f animals animcol
figure; set(gcf,'Position',[675 1 1202 973]);  plt=1;
contentthresh = .3;
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
        end
        % smoothing is ok here bc this is just used for visualizing the curves across trial, not quantification per phase
        countspertrial{a}{e} = zeros(8,length(outers));
        countspertrial{a}{e}(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        for r = 1:8; countspertrial{a}{e}(r,:) = smoothvect(countspertrial{a}{e}(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        
        figure; hold on; set(gcf,'Position',[219 273 1702 450])
        subplot(2,1,1);
        plot(countspertrial{a}{e}'); title(sprintf('%s e%d',animals{a},e))
        plot(((countspertrial{a}{e}>0).*repmat([1:8]',1,size(countspertrial{a}{e},2)))','k.'); ylim([.5 9])
        plot(((countspertrial{a}{e}>1).*repmat([1:8]',1,size(countspertrial{a}{e},2)))','k.','MarkerSize',15);
        plot(((countspertrial{a}{e}>2).*repmat([1:8]',1,size(countspertrial{a}{e},2)))','k.','MarkerSize',25);
        plot(find(tphasenum(:,1)>=1),goals(tphasenum(:,1)>=1),'s','MarkerFaceColor',[1 1 0],'MarkerEdgeColor',[1 1 0],'MarkerSize',20)
        subplot(2,1,2); plot(vispertrial')
        plot((vispertrial.*repmat([1:8]',1,size(vispertrial,2)))','k.'); ylim([.5 9])
    end
end