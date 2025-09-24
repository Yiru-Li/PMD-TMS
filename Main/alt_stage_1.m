function alt_stage_1(subj, th_hair, segment, total)
arguments
    subj char
    th_hair double
    segment {mustBeInteger}
    total {mustBeInteger}
end
FEMORD = 1;
NModes = 110;
start_time = tic;
addpath(fullfile('..', 'PMD_code'));
addpath(fullfile('..', 'PMD_code','TMS_code'));
addpath('/Users/yl647/Documents/GitHub/Tetra-Code') % tetra code path
output_folder = fullfile('..', 'Cluster', subj);
pathparts = strsplit(output_folder,filesep);
subject_folder = pathparts{end};

if ~exist(fullfile(output_folder,['FEM_',num2str(FEMORD)],['Modes_',num2str(NModes)]),'dir')
    mkdir(fullfile(output_folder,['FEM_',num2str(FEMORD)],['Modes_',num2str(NModes)]))
end
save_file = fullfile(output_folder,['FEM_',num2str(FEMORD)],['Modes_',num2str(NModes)],[subject_folder,'_FEM_',num2str(FEMORD),'.mat']);
msh_file = fullfile(output_folder, [subj '.msh']);
[p,te2p,conductivity,reg,M] = load_msh_data(msh_file,'mesh_load_gmsh4');
% [pp_standardized,Anor_standardized,tri_standardized,nhat_standardized] = generate_sample_coil_placement(msh_file,m2m_dir,...
%     th_hair,patch_angle,sphere_density,eeg_mni_source_file);
if ~isfile(fullfile(output_folder, 'Tetra_code', 'tet_code_thinned.mat'))
    warning('off');
    fit_tetra_func(msh_file)
    warning('on');
    msh = mesh_load_gmsh4(msh_file);
    TC = readtable(fullfile(output_folder, 'Tetra_code', 'tet_code2MNI_lookup_extended.xlsx'), ...
        'Sheet', 'Reference', 'Range', 'B:D');
    skin_surf_nodes = msh.nodes(unique(msh.triangles(msh.triangle_regions==1005)), :);
    DT = delaunayTriangulation(skin_surf_nodes);
    % all Tetra Code coil locations
    [pp_standardized, nhat_standardized] = projectPointsToMeshSurfaceWithNormals(TC{:, :}, DT);
    pp_standardized = pp_standardized/1e3+nhat_standardized*th_hair;
    % reduce density of point cloud (especially around the ear)
    [pp_standardized, thin_idx] = radiusThinning(pp_standardized, 1e-3);
    nhat_standardized = nhat_standardized(thin_idx, :);
    save(fullfile(output_folder, 'Tetra_code', 'tet_code_thinned.mat'), 'pp_standardized', 'nhat_standardized')
else
    load(fullfile(output_folder, 'Tetra_code', 'tet_code_thinned.mat'))
end
% further limit to chunk
chunk_size = ceil(length(pp_standardized)/total);
chunk = (1+(segment-1)*chunk_size):min(segment*chunk_size, length(pp_standardized));
pp_standardized = pp_standardized(chunk, :);
nhat_standardized = nhat_standardized(chunk, :);
% calculate Anor
AnorX = zeros(size(nhat_standardized));
AnorX(:,1)=1-nhat_standardized(:,1).*nhat_standardized(:,1);
AnorX(:,2)=-nhat_standardized(:,1).*nhat_standardized(:,2);
AnorX(:,3)=-nhat_standardized(:,1).*nhat_standardized(:,3);
AnorX = AnorX./vecnorm(AnorX, 2, 2);
AnorY=cross(nhat_standardized,AnorX);

Anor_standardized = zeros(4, 4, length(pp_standardized));
Anor_standardized(1:3,1,:)=reshape(AnorX',3, 1, []);
Anor_standardized(1:3,2,:)=reshape(AnorY',3, 1, []);
Anor_standardized(1:3,3,:)=reshape(nhat_standardized',3, 1, []);
Anor_standardized(1:3,4,:)=reshape(pp_standardized',3, 1, []);
Anor_standardized(4,4,:)=1;
%load the coil model
[rcoil,kcoil,coil_model,coil_tri] = load_coil_model(fullfile(fileparts(output_folder), 'PMD_code'),fullfile(fileparts(output_folder), 'MagVenture_Cool-B65.mat'),1);
N_coil_dipoles=[17,17,2]; % the number of dipoles along x,y and z = 17 by 17 by 2 is recommended

%select only those tetrahedrons within GM
teid=1:numel(te2p)/4;
teid=teid(conductivity(1,teid)==.275);
nc=size(pp_standardized,1)*360;
w=randn(nc,NModes);%random matrix
stage_1_Time = toc(start_time);
save(save_file,'stage_1_Time','p','te2p','reg','conductivity','teid','NModes','FEMORD','pp_standardized','Anor_standardized',...
    'w','nhat_standardized','rcoil','kcoil','coil_tri','coil_model','N_coil_dipoles','-v7.3'); % no 'tri_standardized'
end
%% functions
function [closestPoints, normals] = projectPointsToMeshSurfaceWithNormals(P_array, DT)
% Input:
%   P_array: N x 3 matrix of query points
%   DT: delaunayTriangulation object
% Output:
%   closestPoints: N x 3 array of projected points on surface
%   normals: N x 3 array of outward unit normals

% Get mesh surface triangles
surfaceTriangles = freeBoundary(DT);  % M x 3
vertices = DT.Points;

% Precompute triangle data
numTriangles = size(surfaceTriangles, 1);
triangles = cell(numTriangles, 1);
normalsAll = zeros(numTriangles, 3);

for a = 1:numTriangles
    idx = surfaceTriangles(a, :);
    tri = vertices(idx, :);  % 3x3 matrix: [A; B; C]
    triangles{a} = tri;

    % Compute outward normal (assumed right-hand rule)
    AB = tri(2, :) - tri(1, :);
    AC = tri(3, :) - tri(1, :);
    n = cross(AB, AC);
    n = n / norm(n);  % Normalize
    if dot(n, tri(1, :))<0
        n = -n;
    end
    normalsAll(a, :) = n;
end

% Project each query point
minDist = Inf(height(P_array), 1);
closestPoints = NaN(size(P_array));
normals = NaN(size(P_array));
for a = 1:numTriangles
    tri = triangles{a};
    A = tri(1, :);
    B = tri(2, :);
    C = tri(3, :);

    [P_proj, dist, P_idx] = projectPointsOntoTriangle(P_array, A, B, C);
    for b = 1:height(P_idx)
        if minDist(P_idx(b))>abs(dist(b))
            minDist(P_idx(b)) = abs(dist(b));
            closestPoints(P_idx(b), :) = P_proj(b, :);
            normals(P_idx(b), :) = normalsAll(a, :);
        end
    end
end
end

function [P_proj, dist, P_idx] = projectPointsOntoTriangle(P, A, B, C)
% Project P onto the plane of triangle ABC
n = cross(B - A, C - A);
n = n / norm(n);
v = P - A;
dist = dot(v, repmat(n, height(v), 1), 2);
P_proj = P - dist * n;

% Barycentric coordinates
v0 = B - A;
v1 = C - A;
v2 = P_proj - A;

d00 = dot(v0, v0);
d01 = dot(v0, v1);
d11 = dot(v1, v1);
d20 = dot(v2, repmat(v0, height(v2), 1), 2);
d21 = dot(v2, repmat(v1, height(v2), 1), 2);

denom = d00 * d11 - d01 * d01;
u = (d11 * d20 - d01 * d21) / denom;
v = (d00 * d21 - d01 * d20) / denom;

P_idx = find(u >= 0 & v >= 0 & (u + v) <= 1);
P_proj = P_proj(P_idx, :);
dist = dist(P_idx, :);
end

function [pts_thinned, i_idx] = radiusThinning(pts, d_max)
M = size(pts, 1);
remaining = true(M, 1);
pts_thinned = [];
i_idx = [];

kdTree = KDTreeSearcher(pts);

for i = 1:M
    if remaining(i)
        pi = pts(i, :);
        pts_thinned(end+1, :) = pi;
        i_idx(end+1) = i;

        % Find neighbors within radius
        idx = rangesearch(kdTree, pi, d_max);
        remaining(idx{1}(1:end-1)) = false;  % Mark as used
    end
end
end