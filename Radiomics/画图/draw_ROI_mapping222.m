% 画出前面整理好的ROC，mapping背景显示为jet，再在上面画出roi
% 2025/04/18 zhumengying

clc; clear;close all;

% 设置输入文件路径
seq = 'T2Mapping';
input_file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m';
input_file_seq = ['H:\重建数据\mapping_unet_best\qulugu\' seq];  %去颅骨后T2mapping的路径，只是作为叠在底下的文件
filename = 'sub011_HC';

% 定义合并后的ROI
roiInfo = struct('Value', { 301, ...  % Pu
                            303, ...  % Ca
                            309, ...  % GPe
                            311, ...  % GPi
                            313, ...  % SN
                            317, ...  % RN
                            323, ...  % TH
                            333}, ... % DN
                 'Name', {'Pu', 'Ca', 'GPe', 'GPi', 'SN', 'RN', 'TH', 'DN'});

% 定义颜色映射
colorMap = double([
    195, 147, 152;   % 绿色
    252, 218, 186;   % 蓝色
    167, 210, 186;   % 黄色
    208, 202, 222;   % 品红色
    251, 180, 99;   % 青色
    244, 127, 114;    % 橙色
    171, 198, 228;   % 红色
    128, 177, 211   % 灰色
])/255;

atlasFile_gz = fullfile(input_file_root, 'ROI_processed', seq, 'T2_腐蚀1', [filename '_processedROI.nii.gz']);

% 读取 NIfTI 文件数据
atlas = niftiread(atlasFile_gz);
atlasRounded = round(atlas);
seqFile = [input_file_seq '\' filename '_' seq '_brain.nii.gz'];
seq_image = niftiread(seqFile);

% 读取头文件信息
atlasInfo = niftiinfo(atlasFile_gz);

% 创建一个与 seq_image 尺寸相同的全零 RGB 图像
[height, width, slices] = size(seq_image); % 获取 seq_image 的尺寸
rgbImage = zeros(height, width, 3, slices, 'uint8'); % 创建全零数组，数据类型为 uint8

for z = 1:slices
% 假设 seq_image 是灰度图像（3维数据）
    seq_gray = seq_image(:,:,z); % 如果 seq_image 已经是灰度图像，直接赋值
    
    % 归一化灰度值到 [0, 1] 范围
    seq_normalized = double(seq_gray) / 2;
    
    % 获取 jet 颜色映射
    jet_map = jet(256); % jet 颜色映射表，包含 256 种颜色
    
    % 将归一化的灰度值映射到 jet 颜色映射
    seq_rgb= ind2rgb(gray2ind(seq_normalized, 256), jet_map);
     % 将双精度浮点数转换为 uint8 类型
    seq_rgb_uint8 = uint8(seq_rgb * 255); % 将 [0, 1] 范围的值缩放到 [0, 255]
    
    % 将 RGB 图像存储到 rgbImage 中
%     rgbImage(:, :, :, z) = seq_rgb_uint8; % 调整维度顺序以匹配 [height, width, 3, slices]
end

% figure(),imshow(squeeze(rgbImage(:,:,:,12)));

% 提取 ROI 并使用不同颜色表示
for j = 1:length(roiInfo)
    roiValues = roiInfo(j).Value; % 直接使用数值数组
    pro_roiMask = ismember(atlasRounded, roiValues); % 创建ROI掩膜
    % 更新 RGB 图像
    for k = 1:3 % 遍历 RGB 三个通道
        % 提取当前通道的图像数据
        current_channel = rgbImage(:, :, k, :); % 大小为 [height, width, slices]
        
        % 计算替换值：基于 colorMap(j, k)
        replacement_value = uint8(255 * colorMap(j, k)); % 单个通道的颜色值
        
        % 更新非零像素
        for z = 12% 1:size(current_channel, 4) % 遍历每个切片
            mask = pro_roiMask(:, :, z) ~= 0; % 获取当前切片的掩码
%                 imshow(mask)
            
            % 确保只更新满足 mask 条件的像素
            temp_slice = current_channel(:, :, z); % 提取当前切片
            temp_slice(mask) = replacement_value; % 替换非零像素
            current_channel(:, :, z) = temp_slice; % 写回当前切片
        end
        
        % 将更新后的通道数据写回 rgbImage
        rgbImage(:, :, k, :) = current_channel;
    end
end
    
% 限制 RGB 值在 [0, 255] 范围内
rgbImage = min(rgbImage, 255);
figure(),imshow(squeeze(rgbImage(:,:,:,12)),[]);

% figure(),imshow3D(rgbImage);
    