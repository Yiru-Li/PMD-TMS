clear all
masterlist = readtable('/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Data/Head_Model_Masterlist_20250514.csv');
% limit to biphasic RMT
masterlist = masterlist(strcmp(masterlist.Waveform, 'Biphasic'), :);
% adjust filepaths
masterlist.Location = strrep(masterlist.Location, 'smb://duhsnas-pri/dusom_psych/Private/IRB', '/Volumes');
masterlist.Location = strrep(masterlist.Location, 'smb://munin6.biac.duke.edu', '/Volumes');
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
%% Define ROI
subj_dir = ['/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS/' subj];
msh = mesh_load_gmsh4(fullfile(subj_dir, [subj '.msh']));
MNI_coords = readtable('MNI_coords_5mm.xlsx', 'Range', 'A:C');
subj_coords = mni2subject_coords(MNI_coords{:, :}, fullfile(subj_dir, ['m2m_' subj]));
GM_centers = mesh_get_tetrahedron_centers(msh);
GM_centers = GM_centers(msh.tetrahedron_regions==2, :);
GM_vols = mesh_get_tetrahedron_sizes(msh);
GM_vols = GM_vols(msh.tetrahedron_regions==2);
% limit ROI to 5mm radius sphere
ROI = find(pdist2(subj_coords, GM_centers)<5)';
%% PMD-TMS results
% [~, I] = min(pdist2(pp_standardized, [-4.0739e+01, -2.3640e+01, 7.5479e+01]/1e3));
I = 11642;
Anor_standardized(:, :, I)
N = I*360;
E = zeros(length(GM_centers), 3);
tic
for a = 2%:4
    for r = 1:110
        load(fullfile(subj_dir, num2str(a), ['B_' num2str(r) '.mat']), 'Bi')
        load(fullfile(subj_dir, num2str(a), ['q_' num2str(r) '.mat']), 'Qi')
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
end
toc
mesh_save_gmsh4(msh, [subj '_test.msh'])