%% example behavior plot for fig. 1

animal = 'despereaux';
%ffpath = '/media/anna/whirlwindtemp3/remy/filterframework/';
ffpath = '/mnt/stelmo/anna/despereaux/filterframework/';
d = 15; e = 2;

trials = loaddatastruct(ffpath,animal,'trials');

%% plot behavior for entire epoch
figure; set(gcf,'Position',[286 678 1547 231]); hold on; 
starts = [1:length(trials{d}{e}.starttime)]';
ends = [starts(2):starts(end)+1]';
locktrials = trials{d}{e}.locktype>0;
x = reshape([starts(locktrials), starts(locktrials), ends(locktrials), ends(locktrials)]',[],1);
y = reshape(repmat([0 8 8 0]',1,sum(locktrials)),[],1);    
area(x,y,'FaceColor',[.2 .2 .2],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6]);
riptrials = trials{d}{e}.trialtype==1 & trials{d}{e}.locktype==0;
x = reshape([starts(riptrials), starts(riptrials), ends(riptrials), ends(riptrials)]',[],1);
y = reshape(repmat([0 8 8 0]',1,sum(riptrials)),[],1);    
area(x,y,'FaceColor',[0 0 1],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6])
waittrials = trials{d}{e}.trialtype==2 & trials{d}{e}.locktype==0;
x = reshape([starts(waittrials), starts(waittrials), ends(waittrials), ends(waittrials)]',[],1);
y = reshape(repmat([0 8 8 0]',1,sum(waittrials)),[],1);    
area(x,y,'FaceColor',[0 .5 .5],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6])
valout = trials{d}{e}.outerwell>0;
plot(starts(valout)+.5,trials{d}{e}.outerwell(valout)-7.5,'k.','MarkerSize',15)
rewout = trials{d}{e}.outersuccess==1;
plot(starts(rewout)+.5,trials{d}{e}.outerwell(rewout)-7.5,'y.','MarkerSize',8)
plot(repmat([0 ends(end)],7,1)',repmat([1:7]',1,2)','Color',[.6 .6 .6],'Linewidth',.5)
title(sprintf('%s d%d e%d',animal,d,e))
set(gca,'ytick',.5:1:7.5); set(gca,'yticklabel',{'1','2','3','4','5','6','7','8'})
ylabel('arm'); xlabel('trial'); axis tight;

%% just check that pos data and trials data line up 
pos = loaddatastruct(ffpath,animal,'pos',[d e]);
figure; set(gcf,'Position',[286 678 1547 231]); hold on; 
plot(pos{d}{e}.data(:,1),pos{d}{e}.data(:,9),'k')
hometimes = trials{d}{e}.starttime(trials{d}{e}.locktype==0);
plot(hometimes,zeros(sum(trials{d}{e}.locktype==0),1),'k.')
locktrials = trials{d}{e}.locktype>0;
x = reshape([trials{d}{e}.starttime(locktrials), trials{d}{e}.starttime(locktrials), trials{d}{e}.endtime(locktrials), trials{d}{e}.endtime(locktrials)]',[],1);
y = reshape(repmat([0 9 9 0]',1,sum(locktrials)),[],1);    
area(x,y,'FaceColor',[.2 .2 .2],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6]);
riptrials = trials{d}{e}.trialtype==1 & trials{d}{e}.locktype==0;
x = reshape([trials{d}{e}.RWstart(riptrials), trials{d}{e}.RWstart(riptrials), trials{d}{e}.RWend(riptrials), trials{d}{e}.RWend(riptrials)]',[],1);
y = reshape(repmat([0 9 9 0]',1,sum(riptrials)),[],1);    
area(x,y,'FaceColor',[0 1 0],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6])
waittrials = trials{d}{e}.trialtype==2 & trials{d}{e}.locktype==0;
x = reshape([trials{d}{e}.RWstart(waittrials), trials{d}{e}.RWstart(waittrials), trials{d}{e}.RWend(waittrials), trials{d}{e}.RWend(waittrials)]',[],1);
y = reshape(repmat([0 9 9 0]',1,sum(waittrials)),[],1);    
area(x,y,'FaceColor',[0 0 1],'FaceAlpha',.3,'EdgeColor',[.6 .6 .6])

rips = loaddatastruct(ffpath,animal,'ca1rippleskons',[d e]);


%%

figure; hold on; plot(homedios,ones(length(homedios),1),'.')
plot(uptimesall(upwellsall==1),.01+ones(sum(upwellsall==1),1),'.')