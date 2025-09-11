ccd_filename = '/Users/yl647/Applications/SimNIBS-4.0/simnibs_env/lib/python3.9/site-packages/simnibs/resources/coil_models/Drakaki_BrainStim_2022/MagVenture_Cool-B65.ccd';
ccd = readtable(ccd_filename, 'FileType', 'text');
rcoil = ccd{:, 1:3};
rcoil(:, [1 3]) = -rcoil(:, [1 3]); % flip coil from SimNIBS
kcoil = ccd{:, 4:6};
% %% dipole san check
% addpath('../Cluster/PMD_code');
% [rs,ks]=genfig8(.056/2,.087/2,.006,9);
% scatter3(rs(:, 1), rs(:, 2), rs(:, 3), 36, ks(:, 3))
% figure
% scatter3(rcoil(:, 1), rcoil(:, 2), rcoil(:, 3), 36, kcoil(:, 3))
rcoil = rcoil'; kcoil = kcoil'; % reshape
[~, coil_name] = fileparts(ccd_filename);
save([coil_name '.mat'], 'rcoil', 'kcoil')