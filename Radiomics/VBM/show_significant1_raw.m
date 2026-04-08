clc; clear; close all;

% 输入参数
seq = 'T2W'; % T1W, T2W, T2W_FLAIR, T2Mapping, T2star_Mapping
test_names = {'hc_vs_hd','hc_vs_pre_hd','pre_hd_vs_hd'};
file_root = ['H:\重建数据\mapping_unet_best\VBM\' seq];
root_pd = 'H:\重建数据\fsl\';
PD_T1 = [root_pd 'HybraPD-main\PD_fix_hd\PD_template_T1_flip_pa.nii.gz'];
template_file = ['H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_1vs1\' seq '\sub001_HC_' seq '_InverseWarped.nii.gz'];

% 加载标准脑模板
template = load_nii(template_file);
template_data = template.img; % 模板数据

% 遍历每个对比条件
for i = 1:length(test_names)
    test_name = test_names{i};
    
%     % 使用 fslmaths 提取显著性区域 (p < 0.01 对应 -thr 0.99)
%     input_file = fullfile(file_root, ['randomise_results_class_0_1_2_tfce_corrp_tstat', num2str(i), '.nii.gz']);
%     output_file = fullfile(file_root, [test_name, '_significant.nii.gz']);
%     cmd = sprintf('fslmaths %s -thr 0.99 %s', input_file, output_file);
%     system(cmd); % 执行命令行指令
    
    % 显著性区域文件
    significant_file = fullfile(file_root, [test_name, '_significant.nii.gz']);
    
    % 加载显著性区域
    sig_data = load_nii(significant_file).img; % 显著性区域数据
    
    % 确保 sig_data 和 template_data 的尺寸一致
    if ~isequal(size(template_data), size(sig_data))
        error('模板数据和显著性区域数据的尺寸不一致，请检查配准是否正确！');
    end
    
    % 初始化 GIF 文件名
    gif_filename = fullfile(file_root, [test_name, '_significant.gif']);
    
    % 用于存储每一帧的图像
    frames = [];
    
    % 遍历中间的切片范围
    [x, y, z] = size(template_data);
    for slice = [109,123,130,139] % 显示中间的切片范围
        clf; % 清空当前图像
    
        % 提取当前切片
        template_slice = squeeze(template_data(:, :, slice)); % 模板切片
        sig_slice = squeeze(sig_data(:, :, slice)); % 显著性区域切片
    
        % 屏蔽掉 sig_slice 中值为 0 的区域
        sig_slice(sig_slice == 0) = NaN; % 将 0 值设置为 NaN，避免显示
    
        % 归一化 template_slice 的值到 [0, 1] 范围
        template_min = min(template_slice(:));
        template_max = max(template_slice(:));
        template_slice_normalized = (template_slice - template_min) / (template_max - template_min);
    
        % 找到非零区域的最小值和最大值
        sig_min = min(sig_slice(:), [], 'omitnan'); % 非零区域的最小值
        sig_max = max(sig_slice(:), [], 'omitnan'); % 非零区域的最大值
    
        % 归一化显著性区域的值到 [0, 1] 范围
        sig_slice_normalized = (sig_slice - sig_min) / (sig_max - sig_min);
        sig_slice_normalized(isnan(sig_slice_normalized)) = 0; % 处理 NaN 值
    
        % 将 template_slice_normalized 转换为灰度 RGB 图像
        template_rgb = cat(3, template_slice_normalized, template_slice_normalized, template_slice_normalized);
    
        % 将 sig_slice_normalized 转换为 hot 颜色映射的 RGB 图像
        sig_hot = ind2rgb(uint8(rescale(sig_slice_normalized) * 255), hot(256)); % 使用 hot 颜色映射
        sig_rgb = im2double(sig_hot); % 确保数据类型为 double
    
        % 合成最终结果
        result = imadd(template_rgb, 0.5 * sig_rgb);
        imshow(result);
    
        title(['Slice: ', num2str(slice)]);
        drawnow; % 更新图像
    
        % 分离背景和显著性区域的颜色
        % 创建一个掩码，用于区分背景和显著性区域
        mask = sig_slice_normalized > 0; % 显著性区域的掩码
        combined_rgb = template_rgb; % 初始化为背景
        combined_rgb(repmat(mask, [1, 1, 3])) = sig_rgb(repmat(mask, [1, 1, 3])); % 叠加显著性区域
    
        % 将结果转换为索引图像
        % 使用灰度颜色表 + hot 颜色表的组合
        cmap = [gray(256); hot(256)]; % 组合颜色表
        cmap = unique(cmap, 'rows'); % 去重以避免重复颜色
        [img_ind, ~] = rgb2ind(combined_rgb, cmap, 'nodither'); % 使用组合颜色表
        frames{end+1} = uint8(img_ind); % 存储当前帧
    
        pause(0.1); % 暂停以观察动画效果
    end
    
    % 保存为 GIF 文件
    imwrite(frames{1}, cmap, gif_filename, 'LoopCount', Inf, 'DelayTime', 0.1); % 写入第一帧
    for j = 2:length(frames)
        imwrite(frames{j}, cmap, gif_filename, 'WriteMode', 'append', 'DelayTime', 0.4); % 追加后续帧
    end
    
    disp(['GIF 文件已保存为: ', gif_filename]);
end