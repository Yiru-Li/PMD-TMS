clear all
masterlist = readtable('/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Data/Head_Model_Masterlist_20250514.csv');
% limit to biphasic RMT
masterlist = masterlist(strcmp(masterlist.Waveform, 'Biphasic'), :);
% adjust filepaths
masterlist.Location = strrep(masterlist.Location, 'smb://duhsnas-pri/dusom_psych/Private/IRB', '/Volumes');
masterlist.Location = strrep(masterlist.Location, 'smb://munin6.biac.duke.edu', '/Volumes');
cluster_user = 'yl647@cluster.biac.duke.edu';
cluster_loc = '/Volumes/Data/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/';
out_loc = '/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS';
% MNI coordinates to evaluate
MNIs = readtable('MNI_coords_5mm.xlsx');
MNIs = MNIs(:, contains(MNIs.Properties.VariableNames, 'MNI'));
% coil info
dIdtmax = 149.77e6;
%% mesh info
k = 3;
subj = masterlist.Subject{k};
subjects_folder = masterlist.Location{k};
mesh_path = '';
while isempty(mesh_path)
    subjects_folder = [subjects_folder filesep '*'];
    mesh_path = dir([subjects_folder filesep subj '.msh']);
end
MT = masterlist.MT(k);
dIdt = dIdtmax*MT/100;
%% Find targets
msh = mesh_load_gmsh4(fullfile(mesh_path.folder, mesh_path.name));
GM = mesh_extract_regions(msh, 'region_idx', 2);
GM_centers = mesh_get_tetrahedron_centers(GM);
GM_sizes = mesh_get_tetrahedron_sizes(GM);
targets = mni2subject_coords(MNIs{:, :}, fullfile(mesh_path.folder, ['m2m_' subj]));
load(fullfile(out_loc, subj, 'FEM_1', 'Modes_110', [subj '_FEM_1.mat']), 'pp_standardized')
save('tmp.mat')
%% run on cluster
copyfile(fullfile(out_loc, subj, 'FEM_1', 'Modes_110', 'B_*'), cluster_loc)
copyfile(fullfile(out_loc, subj, 'FEM_1', 'Modes_110', 'Q_*'), cluster_loc)
system(['ssh ' cluster_user ' qsub PMD-TMS/run_cluster_optimize.sh']);