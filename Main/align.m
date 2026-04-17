addpath('/Users/yl647/Documents/GitHub/TAP_playground/matlab')
subjects_folder = '/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS';
subj = 'q006';
sep = filesep;
coord = [-4.0739e+01, -2.3640e+01, 7.5479e+01];
which_pipeline = 1;
[brain, brain_tet_mesh, brain_surf_tetcenter, scalp, head_model_mesh, brain_vert_neigh]=get_meshSurfs(subjects_folder, subj, sep);
[target, scalp_normal] = get_target_normal(subjects_folder, sep, subj, coord, brain, scalp, head_model_mesh, which_pipeline, brain_vert_neigh);