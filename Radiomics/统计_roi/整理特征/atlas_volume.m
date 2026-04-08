% 计算一下标准脑我需要8个roi的体积
% 2025/06/21 zhumengying
% 计算8个ROI的体积，按左右半球分开，并显示总计

roiInfo = struct('Value', { [301, 302], ...  % Pu
                            [303, 304], ...  % Ca
                            [309, 310], ...  % GPe
                            [311, 312], ...  % GPi
                            [313, 314, 315, 316], ...  % SN
                            [317, 318], ...  % RN
                            [323, 324, 325, 326, 327, 328, 329, 330, 331, 332], ...  % TH
                            [333, 334]}, ... % DN
                 'Name', {'Pu', 'Ca', 'GPe', 'GPi', 'SN', 'RN', 'TH', 'DN'});

% 加载 atlas
nii = load_untouch_nii('H:\重建数据\fsl\HybraPD-main\PD_template_label_Whole.nii.gz');
atlas_data = nii.img;

% 获取体素大小（mm³）
voxel_size = prod(nii.hdr.dime.pixdim(2:4));

% 输出表头
fprintf('ROI Name\tLeft (cm³)\tRight (cm³)\tTotal (cm³)\n');

% 遍历每个 ROI
for i = 1:length(roiInfo)
    labels = roiInfo(i).Value;      % 当前 ROI 所有 label
    name   = roiInfo(i).Name;       % ROI 名称
    
    left_labels  = labels(mod(labels, 2) == 0);   % 偶数标签为左侧
    right_labels = labels(mod(labels, 2) == 1);   % 奇数标签为右侧
    
    % 提取左右 mask
    mask_left  = ismember(atlas_data, left_labels);
    mask_right = ismember(atlas_data, right_labels);
    
    % 统计体素数
    num_voxels_left  = sum(mask_left(:));
    num_voxels_right = sum(mask_right(:));
    num_voxels_total = num_voxels_left + num_voxels_right;
    
    % 换算成 cm³
    vol_left  = num_voxels_left * voxel_size / 1000;
    vol_right = num_voxels_right * voxel_size / 1000;
    vol_total = num_voxels_total * voxel_size / 1000;
    
    % 输出结果
    fprintf('%-6s\t%.3f\t\t%.3f\t\t%.3f\n', name, vol_left, vol_right, vol_total);
end