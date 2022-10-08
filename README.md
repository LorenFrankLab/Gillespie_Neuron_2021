Code for doing analysis and generating figures for Gillespie et al, "Hippocampal replay represents specific past experiences rather than a plan for subsequent choice" Neuron 2021. Please contact Anna Gillespie (anna.gillespie@ucsf.edu) with any questions about this codebase.

Franklab repos needed:

for data processing: trodes2ff_shared 

for analysis: filterframework_shared 

Context:
Data acquired 2018-2020 using trodes1.6.3 and 30-tet DKR drive version for 4 rats: Jaq, Roquefort, Despereaux, Montague
Data was extracted using D. Liu's python extractor to run Trodes export functions, then processed and analysed in Matlab 2015b

Figures were saved in as pdf or eps and formatted in Adobe Illustrator

Data in NWB format is available on the DANDI Archive: https://dandiarchive.org/dandiset/000115/draft

saved outputs (f) included:

	- dfs_ripcontent -> ctrl_ripcontent.mat [EDIT: too big for github, please download from figshare(https://figshare.com/articles/dataset/ctrl_ripcontent_fixed_mat/21300147)]
	- dfs_ripcontent_ripspeed -> ctrl_ripcontent_ripspeed.mat [EDIT: too big for github, please request if needed]
	- dfs_ripcontent_movement -> ctrl_movementquant_full2state_all_withtrialwise.mat

Code to generate figures:

Figure 1: 

    - B,C - plot_behavior_example.m, desp15_2 
	- D - dfs_ripcontent.m, part 1
    - E,F - dfs_ripcontent.m, part 2
	
Figure 2:

	- A,B - dfs_plotripcontent.m, span=full, despereaux session 8
	- C,D,E - dfs_plotripcontent.m, span=rips, despereaux session 8, tets 25,26,30
	- F - dfs_ripcontent.m, part 3
	
Figure 3:

	- A - dfs_ripcontent.m, part 3
	- B,C - dfs_ripcontent.m, part 4 
	- D,E - dfs_ripcontent.m, part 5
	
Figure 4:

	- A,B - dfs_ripcontent.m, part 5
	- C - dfs_ripcontent.m, part 6

Figure 5:

	- A - dfs_ripcontent.m, part 7
	- B,C,D - dfs_ripcontent.m, part 6
	- E - dfs_ripcontent.m, part 8
	- Correlations (in text, no fig) - dfs_ripcontent.m, part 16
	
Figure 6: dfs_ripcontent.m, part 9

Figure 7: dfs_ripcontent.m, part 8

Figure 8:

	- A - dfs_ripcontent.m, part 10
	- B - dfs_ripcontent.m, part 5
	
Supplementary Fig 1: 

	- A - dfs_ripcontent.m, part 11
	- C - dfs_ripcontent.m, part 12
	
Supplementary Fig 2: clusterless_schematic.m

Supplementary Fig 3:
	
	- A-C - dfs_ripcontent_movement.m, part 2
	- D-F - dfs_ripcontent_movement.m, part 6
	- G - dfs_ripcontent.m, part 3
	- H - dfs_ripcontent.m, part 13

Supplementary Fig 4: dfs_plotripcontent, span=rips, run once per rat (day/ep/rip noted on fig)

Supplementary Fig 5: 

	- first run dfs_ripfeatures.m to calc tetwise features (slow! alternativately, load saved output)
	- then dfs_ripcontent.m, part 14 to visualize
	
Supplementary Fig 6: dfs_ripcontent.m, part 5

Supplementary Fig 7: dfs_ripcontent.m, part 6 (commented out)

Supplementary Fig 8: 

	- A-D - dfs_ripcontent_ripspeed.m
	- E-G - dfs_ripcontent.m, part 15

Control Analyses (not shown in figures):

	- Likelihoods (decode without state space model, 20ms bins): dfs_likcontent.m
	- Use MUA as event detection instead of SWRs: dfs_muacontent.m
	- Use 3-state decoder instead of 2-state to exclude stationary events: dfs_ripcontent_3state.m
	- Use more permissive content threshold: dfs_ripcontent_contentthresh
