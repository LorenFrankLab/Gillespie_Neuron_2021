%% Sungod Manu: generate plot of decode + rips
% main fig examples: despereaux 8_2; local 1942.5

% run on 1 rat at a time
animals = {'jaq'}; %{'remy','gus','bernard','fievel'}; %
%animals = {'jaq','roquefort','despereaux'};  %,, 'remy',};%};

%epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal_nodelay'') | isequal($environment,''hybrid2'') | isequal($environment,''hybrid3''))'];
%epochfilter{1} = ['$ripthresh>0  & $ripthresh<16 &(isequal($environment,''goal'') | isequal($environment,''hybrid2'') | isequal($environment,''hybrid3''))'];
%epochfilter{1} = ['$ripthresh>=16 & (isequal($environment,''goal'') | isequal($environment,''hybrid2'') | isequal($environment,''hybrid3''))'];
epochfilter{1} = ['$session==15 & isequal($type,''run'')'];

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epochbehaveanal';

% manually specify the tetrode to add
tet = [18,20,24]; % desp
%tet = [12,18,27]; % jaq
%tet = [6 14 18]; % roqui
%tet = [2 7 12]; %monty

f = createfilter('animal',animals,'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
f = setfilterfunction(f, 'dfa_plotremotecontent_sg', {'remotedecodesv3','ripdecodesv3','trials'},'animal',animals{1},'posterior',1,'v',3,'tet',tet,'span','full');
f = runfilter(f);

%fname ='/media/anna/whirlwindtemp2/ffresults/Decodequant20200120_Ctrldelay.mat';
%save(fname,'f','-v7.3')



%% 
pos = loaddatastruct('/mnt/stelmo/anna/despereaux/filterframework/','despereaux','pos',[8 2])
ex = find(pos{8}{2}.data(:,1)>5215 & pos{8}{2}.data(:,1)<5265);
figure; hold on
plot(pos{8}{2}.data(:,6),pos{8}{2}.data(:,7),'Color',[.8 .8 .8]);
plot(pos{8}{2}.data(ex,6),pos{8}{2}.data(ex,7),'m'); axis square
title('desp8_2 example 5215-5265s')