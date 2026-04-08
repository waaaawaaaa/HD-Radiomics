% 计算仿真图像与模版的差异
% 用仿真数据的幅值
% 2024/04/29 zhumengying

% 训练文件夹路径和测试文件夹路径
file_root = '/DATA2023/zmy/smri_hd/OLED_T2/charles_output_mask/';
trainFolderPath = [file_root 'train/'];
testFolderPath = [file_root 'test/'];

% 计算训练文件夹中的 SSIM 和 PSNR
[trainSSIMMean, trainPSNRMean, trainNumFiles] = calculateFolderSSIM_PSNR(trainFolderPath, '训练');

% 计算测试文件夹中的 SSIM 和 PSNR
[testSSIMMean, testPSNRMean, testNumFiles] = calculateFolderSSIM_PSNR(testFolderPath, '测试');


function [ssimMean, psnrMean, numFiles] = calculateFolderSSIM_PSNR(folderPath, datasetType)
    % 获取文件夹下所有 .charles 文件的列表
    fileList = dir(fullfile(folderPath, '*.Charles'));
    
    % 初始化变量以存储 SSIM 值、PSNR值和文件数量
    ssimSum = 0;
    psnrSum = 0;
    numFiles = numel(fileList);
    
    % 遍历文件列表
    for i = 1:numFiles
        % 获取文件路径
        filePath = fullfile(folderPath, fileList(i).name);
        
        % 读取 .charles 文件
        data = 1*Binary2D_reader(filePath, 256, 256);
        
        % 提取数组
        real = squeeze(data(1,:,:));
        imag = squeeze(data(2,:,:));
        label = squeeze(data(3,:,:));
        
        % 构造复数数组
        complexArray = real + 1i * imag;
        
        % 计算幅值
        magnitudeArray = abs(complexArray)*2;

        
        % 计算 SSIM
        ssimValue = ssim(magnitudeArray, label);
        
        % 累加 SSIM 值
        ssimSum = ssimSum + ssimValue;
        
        % 计算 PSNR
        psnrValue = psnr(magnitudeArray, label);
        
        % 累加 PSNR 值
        psnrSum = psnrSum + psnrValue;
%         imshow([magnitudeArray label],[0,2]);colormap jet;colorbar;
    end
    
    % 计算 SSIM 和 PSNR 的均值
    ssimMean = ssimSum / numFiles;
    psnrMean = psnrSum / numFiles;
    
    % 输出结果
    fprintf('%s 文件夹中 SSIM 的均值: %.4f (共 %d 个文件)\n', datasetType, ssimMean, numFiles);
    fprintf('%s 文件夹中 PSNR 的均值: %.4f (共 %d 个文件)\n', datasetType, psnrMean, numFiles);
end


% function [ssimMean, numFiles] = calculateFolderSSIM(folderPath)
%     % 获取文件夹下所有 .charles 文件的列表
%     fileList = dir(fullfile(folderPath, '*.Charles'));
%     
%     % 初始化变量以存储 SSIM 值和文件数量
%     ssimSum = 0;
%     numFiles = numel(fileList);
%     
%     % 遍历文件列表
%     for i = 1:numFiles
%         % 获取文件路径
%         filePath = fullfile(folderPath, fileList(i).name);
%         
%         % 读取 .charles 文件
%         data = 1*Binary2D_reader(filePath, 256, 256);
%         
%         % 提取数组
%         real = squeeze(data(1,:,:));
%         imag = squeeze(data(2,:,:));
%         label = squeeze(data(3,:,:));
%         
%         % 构造复数数组
%         complexArray = real + 1i * imag;
%         
%         % 计算幅值
%         magnitudeArray = abs(complexArray)*2;
%         
%         % 计算 SSIM
%         ssimValue = ssim(magnitudeArray, label);
%         
%         % 累加 SSIM 值
%         ssimSum = ssimSum + ssimValue;
%     end
%     
%     % 计算 SSIM 的均值
%     ssimMean = ssimSum / numFiles;
% end

