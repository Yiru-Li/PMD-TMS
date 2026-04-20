clear all
masterlist = readtable('/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Data/Head_Model_Masterlist_20250514.csv');
% limit to biphasic RMT
masterlist = masterlist(strcmp(masterlist.Waveform, 'Biphasic'), :);
% adjust filepaths
masterlist.Location = strrep(masterlist.Location, 'smb://duhsnas-pri/dusom_psych/Private/IRB', '/Volumes');
masterlist.Location = strrep(masterlist.Location, 'smb://munin6.biac.duke.edu', '/Volumes');
out_loc = '/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS';
%%
k = 3;
subj = masterlist.Subject{k};
subjects_folder = masterlist.Location{k};
mesh_path = '';
while isempty(mesh_path)
    subjects_folder = [subjects_folder filesep '*'];
    mesh_path = dir([subjects_folder filesep subj '.msh']);
end
MT = masterlist.MT(k);
dIdtmax = 149.77e6;
dIdt = dIdtmax*MT/100;
%%
subj_dir = [out_loc filesep subj];
msh = mesh_load_gmsh4(fullfile(subj_dir, [subj '.msh']));
subj_coords = mni2subject_coords([-43, -89, -8], fullfile(subj_dir, ['m2m_' subj]));
GM_centers = mesh_get_tetrahedron_centers(msh);
GM_centers = GM_centers(msh.tetrahedron_regions==2, :);
GM_vols = mesh_get_tetrahedron_sizes(msh);
GM_vols = GM_vols(msh.tetrahedron_regions==2);
% limit ROI to 5mm radius sphere
ROI = find(pdist2(subj_coords, GM_centers)<5)';
%% PMD-TMS results
% [~, I] = min(pdist2(pp_standardized, [-4.0739e+01, -2.3640e+01, 7.5479e+01]/1e3));
I = 11642;
N = I*360;
E = zeros(length(GM_centers), 3);
tic
for r = 1:110
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['B_' num2str(r) '.mat']), 'Bi')
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['Q_' num2str(r) '.mat']), 'Qi')
    for b = 1:3
        E(:, b) = E(:, b)+Qi(b:3:end)*Bi(N)';
    end
end
msh.element_data{1}.tetdata = zeros(length(msh.tetrahedron_regions), 3);
msh.element_data{1}.tetdata(msh.tetrahedron_regions==2, :) = E*dIdt;
msh.element_data{1}.tridata = [];
msh.element_data{1}.name = 'E';

msh.element_data{2}.tetdata = zeros(size(msh.tetrahedron_regions));
msh.element_data{2}.tetdata(msh.tetrahedron_regions==2) = pdist2([0 0 0], E*dIdt);
msh.element_data{2}.tridata = [];
msh.element_data{2}.name = 'magnE';
toc
mesh_save_gmsh4(msh, [subj '_test.msh'])
%% SimNIBS run
% General information

S = sim_struct('SESSION');
S.fnamehead = fullfile(mesh_path.folder, mesh_path.name); % head mesh
S.pathfem = 'tms'; %Folder for the simulation output

% Define TMS simulation
S.poslist{1} = sim_struct('TMSLIST');
S.poslist{1}.fnamecoil = '/Users/yl647/Applications/SimNIBS-4.0/simnibs_env/lib/python3.9/site-packages/simnibs/resources/coil_models/Drakaki_BrainStim_2022/MagVenture_Cool-B65.ccd';

%Define Position
load(fullfile(subj_dir, 'FEM_1', 'Modes_110', 'q007_FEM_1.mat'), 'Anor_standardized')
% Anor_standardized(:, :, I)
S.poslist{1}.pos(1).matsimnibs(:, [1 3]) = -Anor_standardized(:, [1 3], I);
S.poslist{1}.pos(1).matsimnibs(:, 2) = Anor_standardized(:, 2, I);
S.poslist{1}.pos(1).matsimnibs(1:3, 4) = Anor_standardized(1:3, 4, I)*1e3;
S.poslist{1, 1}.pos.didt = dIdt;
clear Anor_standardized

% Run Simulation
run_simnibs(S);
%%
SimNIBS_results = mesh_load_gmsh4('tms/q007_TMS_1-0001_MagVenture_Cool-B65_scalar.msh');
GM = mesh_extract_regions(SimNIBS_results, 'region_idx', 2);
scatter(GM.element_data{2, 1}.tetdata, msh.element_data{2}.tetdata(msh.tetrahedron_regions==2))