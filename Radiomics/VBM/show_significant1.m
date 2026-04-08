clc; clear; close all;

% 输入参数
seqs = {'T2Mapping','T2star_Mapping','T1W','T2W','T2W_FLAIR'};
seqs_VBM = {'T2Mapping_2STEP','T2star_Mapping_2STEP','T1W','T2W','T2W_FLAIR'};

% 存储每个 seq 的横向拼接图像
all_seq_results = cell(1, length(seqs));

for s = 1:length(seqs)
    seq = seqs{s}; % T1W, T2W, T2W_FLAIR, T2Mapping, T2star_Mapping
    test_names = {'hc_vs_pre_hd','hc_vs_hd','pre_hd_vs_hd'};
    file_root = ['H:\重建数据\mapping_unet_best\VBM\' seqs_VBM{s}];
    % 根据当前 seq 设置 template_file
    switch seq
        case 'T2Mapping'
            template_file = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m\T2Mapping\sub001_HC_T2Mapping_2PD.nii.gz';
        
        case 'T2star_Mapping'
            template_file = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2s\T2star_Mapping\sub001_HC_T2star_Mapping_2PD.nii.gz';
        
        otherwise
            template_file = ['H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_1vs1\' seq '\sub001_HC_' seq '_InverseWarped.nii.gz'];
    end

    % 加载标准脑模板
    template = load_nii(template_file);
    template_data = template.img; % 模板数据
    if s<3
        template_data = template_data/2;
    else
        template_min = min(template_data(:));
        template_max = max(template_data(:));
        template_data = (template_data - template_min) / (template_max - template_min);
    end
%     % 归一化 template_slice 的值到 [0, 1] 范围
%     template_min = min(template_data(:));
%     template_max = max(template_data(:));
%     template_data = (template_data - template_min) / (template_max - template_min);
    
    % 预分配一个 cell 来存储每个 test_name 的拼接图
    all_results = cell(1, length(test_names));
    
    % 遍历每个对比条件
    for i = 1:length(test_names)
        test_name = test_names{i};
        
    %     % 使用 fslmaths 提取显著性区域 (p < 0.01 对应 -thr 0.99)
    %     input_file = fullfile(file_root, ['randomise_results_class_0_1_2_tfce_corrp_tstat', num2str(i), '.nii.gz']);
    %     output_file = fullfile(file_root, [test_name, '_significant.nii.gz']);
    %     cmd = sprintf('fslmaths %s -thr 0.99 %s', input_file, output_file);
    %     system(cmd); % 执行命令行指令
        
        % 显著性区域文件
        significant_file = fullfile(file_root, ['005_' test_name, '_significant.nii.gz']);
        
        % 加载显著性区域
        sig_data = load_nii(significant_file).img; % 显著性区域数据
        
        % 确保 sig_data 和 template_data 的尺寸一致
        if ~isequal(size(template_data), size(sig_data))
            error('模板数据和显著性区域数据的尺寸不一致，请检查配准是否正确！');
        end
        
       
        sig_data(sig_data == 0) = NaN; % 将 0 值设置为 NaN，避免显示
    
        % 提取三个方向的切片
        axial_bg   = squeeze(template_data(26:220, 26:220, 125));     % Axial
        sagittal_bg = squeeze(template_data(128, 26:220, 26:220));   % Sagittal
        coronal_bg  = squeeze(template_data(26:220, 128, 26:220));    % Coronal
    
        % 提取显著性区域切片
        axial_sig   = squeeze(sig_data(26:220, 26:220, 125));     % Axial
        sagittal_sig = squeeze(sig_data(128, 26:220, 26:220));   % Sagittal
        coronal_sig  = squeeze(sig_data(26:220, 128, 26:220));    % Coronal    
        
        % 定义图像处理函数：先 flipud，再 rot90
        process = @(x) rot90(flipud(x), 1);
        
        % 处理模板图像
        axial_bg_p   = process(axial_bg);
        coronal_bg_p = process(coronal_bg);
        sagittal_bg_p = process(sagittal_bg);  % 注意这里使用 coronal_bg 是为了保持一致维度
        
        % 处理显著性区域图像
        axial_sig_p   = process(axial_sig);
        coronal_sig_p = process(coronal_sig);
        sagittal_sig_p = process(sagittal_sig);
        
        % 拼接背景图像和显著性图像
        bg_combined = horzcat(axial_bg_p, coronal_bg_p, sagittal_bg_p);
        sig_combined = horzcat(axial_sig_p, coronal_sig_p, sagittal_sig_p);
    
        sig_combined(sig_combined == 0) = NaN; % 将 0 值设置为 NaN，避免显示
    
        template_rgb = cat(3, bg_combined, bg_combined, bg_combined);
        sig_combined_normalized = (sig_combined - 0.95) / 1;
    
        sig_combined_normalized(isnan(sig_combined_normalized)) = 0; % 处理 NaN 值 % 处理 NaN 值
        
        % 将 sig_slice_normalized 转换为 hot 颜色映射的 RGB 图像
        sig_hot = ind2rgb(uint8(rescale(sig_combined_normalized) * 255), hot(256)); % 使用 hot 颜色映射
        sig_rgb = im2double(sig_hot); % 确保数据类型为 double
    
        % 合成最终结果
        result = imadd(template_rgb, 0.5 * sig_rgb);
        % 存入 cell
        all_results{i} = result;
    end
    
    % 设置白线的宽度（像素）
    white_line_width = 2;
    
    % 获取图像大小（假设所有图像尺寸一致）
    [rows, cols, ~] = size(all_results{1});
    
    % 初始化最终图像为第一个 test 图像
    final_result = all_results{1};
    
    % 在每两个图像之间插入白线
    for i = 2:length(all_results)
        % 创建一个白色的竖线图像（与图像高度一致）
        white_line = ones(rows, white_line_width, 3);  % RGB 白色线
        
        % 将当前图像拼接到最终图像中，并加上白线
        final_result = horzcat(final_result, white_line, all_results{i});
    end

    % 保存当前 seq 的图像
    all_seq_results{s} = final_result;
    
end
% 垂直拼接所有 seq 的图像 + 白线分隔
white_line_height = 2;
final_vertical_result = all_seq_results{1};

for i = 2:length(all_seq_results)
    % 创建白色横线
    [~, cols, ~] = size(all_seq_results{i});
    white_line = ones(white_line_height, cols, 3);
    
    % 垂直拼接
    final_vertical_result = vertcat(final_vertical_result, white_line, all_seq_results{i});
end

% 显示最终图像
figure;
imshow(final_vertical_result);