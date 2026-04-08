% 手动修改去颅骨的mask
% 2025/04/19 zhumengying

clc;clear;close all
% 指定图像文件路径
sub='sub011_HC';  % sub011_HC  sub022
seq = 'T1W';  % T2W T1W T2W_FLAIR

file_root = ['H:\重建数据\mapping_unet_best\swapdim\' seq '\' sub];
filename = [sub '_' seq '_swapdim.nii.gz'];
out_root = ['H:\重建数据\mapping_unet_best\swapdim\' seq ];
% 拼接输出文件名
output_filename = fullfile(out_root, [sub '_' seq '_brain.nii']);
output_mask_filename = fullfile(out_root, [sub '_' seq '_brain_mask.nii']);

% 读取NIfTI格式图像文件
nii_data = niftiread(fullfile(file_root, filename));
nii_info = niftiinfo(fullfile(file_root, filename));

% 获取图像的尺寸和切片数
[dim1, dim2, num_slices] = size(nii_data);
nii_data_mask = zeros(size(nii_data), 'like', nii_data); % 初始化掩膜数据与原始数据类型一致
nii_mask = zeros(size(nii_data), 'like', nii_data); % 初始化掩膜数据与原始数据类型一致

% 只选择第 8、11、12、13 层
selected_slices = [9, 11, 12, 13];

% 遍历选定的切片并处理
for i = 1:length(selected_slices)
    slice_idx = selected_slices(i); % 当前切片索引
    slice_data = nii_data(:, :, slice_idx); % 提取当前切片数据
    
    % 显示当前切片，根据需要调整显示范围
    figure;
    imshow(slice_data, []); % 根据实际图像灰度范围调整 [0, 6000]，这里需要根据实际情况调整
    title(['Slice ', num2str(slice_idx)]);
    % 用户交互方式创建掩膜
    hfh_1 = imfreehand();
    brain_ROI_slice = createMask(hfh_1);

%     % 显示创建的掩膜
%     figure;
%     imagesc(brain_ROI_slice);
%     colormap gray;
%     title(['Mask for Slice ', num2str(slice_idx)]);

    % 将掩膜应用到切片数据上
    slice_data_mask = slice_data .* brain_ROI_slice;
    nii_data_mask(:,:,slice_idx) = slice_data_mask;
    nii_mask(:,:,slice_idx) = brain_ROI_slice;
end

% 将掩膜数据类型转换为 single，以匹配 single 中的数据类型
nii_data_mask = single(nii_data_mask);
figure();imshow3D(nii_data_mask)

% 保存修改后的 NIfTI 数据为新文件
niftiwrite(nii_data_mask, output_filename, nii_info, 'Compressed', true);
disp(['NIfTI 文件保存成功：', output_filename]);
% 保存修改后的 mask为新文件
niftiwrite(nii_mask, output_mask_filename, nii_info, 'Compressed', true);
disp(['NIfTI 文件保存成功：', output_mask_filename]);