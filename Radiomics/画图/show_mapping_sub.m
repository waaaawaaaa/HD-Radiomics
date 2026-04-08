% 查看nii文件  一个受试者五个模态的图像
% 2024/12/14 zhumengying

% 配准前
clc;clear;close all;
% 指定图像文件路径
file_root = 'H:\重建数据\mapping_unet_best\qulugu\';
seqs = {'T2Mapping', 'T2star_Mapping', 'T1W', 'T2W', 'T2W_FLAIR'};

% 去掉 '_T2Mapping_brain' 部分
base_name = 'sub006';  %sub002_HC  sub003   sub006
% 将下划线替换为空格
filename_title = strrep(base_name, '_', ' ');

figure('Position', [0, 40, 900, 500]);  % 设置图像大小
% 使用 tiledlayout 创建一个紧密排布的布局
tiledlayout(5, 1, 'TileSpacing', 'none', 'Padding', 'none'); % 'none' 去除间隙
for s = 1:length(seqs)
    if s <3

        inputFile = fullfile(file_root, seqs{s}, [base_name, '_' seqs{s} '_brain.nii.gz']);
    else
        inputFile = fullfile('H:\重建数据\mapping_unet_best\normalize_99', seqs{s}, [base_name, '_' seqs{s} '_normalized.nii.gz']);
    end

    if exist(inputFile, 'file')
        % 读取NIfTI格式图像文件
        nii_data = niftiread(inputFile);

    else
        % 文件不存在，跳过
        fprintf('File not found: %s\n', inputFile);
        continue; % 跳过当前循环，继续下一个
    end
    
    % 获取图像的尺寸和切片数
    [dim1, dim2, num_slices] = size(nii_data)        
    
    % 初始化大图像
    h_small = dim1;
    w_small = dim2;
    h_big = 1 * h_small;  % 大图像的高度
    w_big = 7 * w_small;  % 大图像的宽度
    big_image = zeros(h_big, w_big);

    if strcmp(seqs{s}, 'T2Mapping') || strcmp(seqs{s}, 'T2star_Mapping')
        slices = [18,15,13,12,11,9,7,5,3];  %mapping间隔是3正好对应结构像间隔2张
    else
        slices = [16,14,13,12,11,10,9,8,6];
    end
    
    % 拼接图像
    count = 1;
    for row = 1:2
        for col = 1:11
            if count <= length(slices)
                % 获取当前切片
                slice = rot90(squeeze(nii_data(:, :, slices(count))));
                
                % 计算在大图像中的位置
                start_row = (row - 1) * h_small + 1;
                end_row = row * h_small;
                start_col = (col - 1) * w_small + 1;
                end_col = col * w_small;
                
                % 将切片放入大图像
                big_image(start_row:end_row, start_col:end_col) = slice;
                
                % 更新计数器
                count = count + 1;
            end
        end
    end
    
    nexttile;
    if strcmp(seqs{s}, 'T2Mapping') || strcmp(seqs{s}, 'T2star_Mapping')
%         big_image
        imshow(big_image, [0 2]); % 设置显示范围
        colormap jet;colorbar;
    else
        imshow(big_image, [0 1]); % 设置显示范围
        colorbar;
    end
end
% sgtitle(filename_title,'FontSize', 11); % 整个大图的标题