clear all
msh = mesh_load_gmsh4('/Volumes/Data/Neacsiu/NATURE.01/Analysis/NA44865/44865_mesh_output/NA44865_mri2mesh/targetpost/DLPFC_HT0.00/NA44865_mri2mesh_TMS_optimize_MagVenture_Cool-B65.msh');
ROI = msh.element_data{5, 1}.tetdata;
load('/Volumes/Data/Neacsiu/NATURE.01/Analysis/NA44865/44865_mesh_output/NA44865_mri2mesh/targetpost/DLPFC_HT0.00/simnibs_simulation_20240827-142526.mat', 'target', 'target_size');
tet_centers = mesh_get_tetrahedron_centers(msh);
sum((pdist2(mesh_get_tetrahedron_centers(msh), target)<5) & msh.tetrahedron_regions==2)
sum(msh.element_data{5, 1}.tetdata)
isequal((pdist2(mesh_get_tetrahedron_centers(msh), target)<5) & msh.tetrahedron_regions==2, logical(msh.element_data{5, 1}.tetdata))
% SimNIBS ROI inclusion/exclusion is defined with respect to tetrahedron centers