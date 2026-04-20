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
%% make ROIs
msh = mesh_load_gmsh4(fullfile(mesh_path.folder, mesh_path.name));
GM = mesh_extract_regions(msh, 'region_idx', 2);
GM_centers = mesh_get_tetrahedron_centers(GM);
targets = mni2subject_coords(MNIs{:, :}, fullfile(mesh_path.folder, ['m2m_' subj]));
%% find ROI for each MNI
ROIs = cell(height(targets), 1);
for t = 1:length(targets)
    [dist, target] = min(pdist2(GM.nodes, targets(t, :)));
    if dist<5 % if target is close enough to GM, snap to GM and find ROI
        target = GM.nodes(target, :);
        ROIs{t} = find(pdist2(GM_centers, target)<5);
    end
end
%% find E-field per r for coil position and ROI
load(fullfile(subj_dir, 'FEM_1', 'Modes_110', [subj '_FEM_1.mat']), 'pp_standardized')
pp_standardized = pp_standardized*1e3;
subj = masterlist.Subject{k};
subj_dir = [out_loc filesep subj];

for t = 1:length(targets)
    if isempty(ROIs{t}) % skip empty ROIs
        continue
    end
    % search within 25mm of closest coil position
    [~, target] = min(pdist2(pp_standardized, targets(t, :)));
    coil_pos = find(pdist2(pp_standardized, pp_standardized(target, :))<25);
    C = reshape((coil_pos*360+(1:360)-360)', [], 1); % coil positions
    T = ROIs{t}
end
%%
E = zeros(sum(msh.tetrahedron_regions==2), 3);
for r = 1:110
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['B_' num2str(r) '.mat']), 'Bi')
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['Q_' num2str(r) '.mat']), 'Qi')
    for b = 1:3
        E(:, b) = E(:, b)+Qi(b:3:end)*Bi(N)';
    end
end