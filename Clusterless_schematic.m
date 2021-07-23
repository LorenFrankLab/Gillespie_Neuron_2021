animal='despereaux';
destdir = '/mnt/stelmo/anna/despereaux/filterframework/';
d=6;
e=2;
t=3; % 2 20 
marks = loaddatastruct(destdir, animal,'marks',[d e ]);
pos = loaddatastruct(destdir, animal,'pos',[d e ]);

linposfile = sprintf('%sdecoding/%s_%d_%d_shuffle_0_linearposition_v2.nc', destdir, animal, d, e); 
linpos = ncread(linposfile,'linpos_flat')+1;
linvel = ncread(linposfile,'linvel_flat');
linposts = ncread(linposfile,'time');

immobilefilter = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
immoperiods = kk_evaluatetimefilter(destdir,animal, {immobilefilter}, [d e]);
immospikes = isExcluded(marks{d}{e}{t}.times, immoperiods{d}{e});    
% correct for gaps between arms
nodatarows = histcounts(linpos,[1:max(linpos)+1])==0;
correction = cumsum(nodatarows);
linposcorr = double(linpos)'-correction(linpos);
bounds = .5+find(diff(correction(~nodatarows))>0);

starttime = 3000; %
endtime = 7500; %
markinds = marks{d}{e}{t}.times>=starttime & marks{d}{e}{t}.times<=endtime & ~immospikes;

posinds = linposts>=starttime & linposts<=endtime;
posatmarktimes = linposcorr(lookup(marks{d}{e}{t}.times(markinds),linposts));
%edges = [0 10 27 44 76 92 108 124 140]; 
%segatmarktimes = discretize(posatmarktimes,edges);
%segs = discretize(linpos,edges);

figure; set(gcf,'Position',[86 179 1804 739])
subplot(1,3,1); hold on
subsetpos = linposts>=6850 & linposts<=7250;
scatter(pos{d}{e}.data(subsetpos & posinds & linvel>=4,7),pos{d}{e}.data(subsetpos & posinds & linvel>=4,6),10,linposcorr(subsetpos & posinds & linvel>=4),'filled')
set(gca,'YDir','reverse'); ylabel('x (cm; rev)'); xlabel('y (cm)');
title(sprintf('%s d%d e%d t%d',animal,d,e,t)); 
subplot(1,3,2);  
scatter(linposts(subsetpos & posinds & linvel>=4)-starttime,linposcorr(subsetpos & posinds & linvel>=4),10,linposcorr(subsetpos & posinds & linvel>=4),'filled') %segs
ylabel('linearized pos'); xlabel('time (s)'); axis square tight; colorbar
%scatter(marks{d}{e}{t}.times(markinds),posatmarktimes,10,segatmarktimes)

figure % save separately otherwise too big
scatter(marks{d}{e}{t}.marks(markinds,1),marks{d}{e}{t}.marks(markinds,3),10,posatmarktimes,'filled'); colorbar %,'MarkerFaceAlpha',.5
xlabel('ch2 amplitude (uV)'); ylabel('ch3 amplitude (uV)'); ylim([-200 1000]); xlim([-200 800]); 

%% plot spike raster 
tetinfo = loaddatastruct(destdir, animal,'tetinfo',[d e]);
tets = evaluatefilter(tetinfo{d}{e},'isequal($area,''ca1'')'); %
rips = loaddatastruct(destdir, animal,'ca1rippleskons',[d e]);
immoevents = isExcluded(rips{d}{e}{1}.starttime, immoperiods{d}{e}) & isExcluded(rips{d}{e}{1}.endtime, immoperiods{d}{e});    
valrips = isExcluded(rips{d}{e}{1}.starttime, immoperiods{d}{e}) & isExcluded(rips{d}{e}{1}.endtime, immoperiods{d}{e}) ;    
riptsz = [rips{d}{e}{1}.starttime(valrips), rips{d}{e}{1}.endtime(valrips), rips{d}{e}{1}.maxthresh(valrips)];

figure; hold on;
startend = [5678.892 5682.892];
ripinds = riptsz(:,1)>startend(1) & riptsz(:,2)<startend(2);
for t = 1:length(tets)
    spktimes = marks{d}{e}{tets(t)}.times(marks{d}{e}{tets(t)}.times>=startend(1) & marks{d}{e}{tets(t)}.times<=startend(2));
    plot([spktimes'; spktimes'],repmat([t-.9;t],1,length(spktimes)),'k')
end
patch([riptsz(ripinds,1:2), fliplr(riptsz(ripinds,1:2))],[0 0 t t]','k','FaceAlpha',.1,'EdgeColor','none');
axis tight; ylabel('tets'); title(sprintf('%s d%d e%d',animal, d, e)); 


%% plot velocity
figure;
posinds = linposts>=startend(1) & linposts<=startend(2);
plot(linposts(posinds),linvel(posinds),'k'); 
patch([riptsz(ripinds,1:2), fliplr(riptsz(ripinds,1:2))],[0 0 75 75]','k','FaceAlpha',.1,'EdgeColor','none');
axis tight; ylabel('velocity (cm/s)'); title(sprintf('%s d%d e%d',animal, d, e)); ylim([0 75]); set(gca,'ytick',[0 25 50 75])
