% 仿真数据和实采数据的噪声应该一致
% 所以这个代码用来计算实采数据的噪声。标准的算法应该使用水模，这里就大概算一下
% 2024/04/14  zhumengying
% 
% 信号取中间部分，噪声取周围四个角落的区域的噪声标准差平均值

% 读取 DICOM 文件
dcmFile = fullfile('G:\重建数据\extract\sub001\OLED_T2\I310');
MRI_image = dicomread(dcmFile);

% 定义ROI大小为 corner_size x corner_size
corner_size = 20; % 你可以根据实际情况调整大小

std_noise = mean_std_noise(MRI_image,corner_size);  %周围的噪声信号
mean_signal = anaylse_brain_mean(MRI_image);

% 计算 SNR
SNR = 0.66*mean_signal / mean_std_noise;  %感觉不应该乘以0.66，应该除以0.66，只是从幅值或者相位得到
% 飞利浦的背景被mask掉了

%噪声均值
function std_noise = mean_std_noise(MRI_image,corner_size)

    % 获取图像尺寸
    [image_height, image_width] = size(MRI_image);

    % 计算四个角落的ROI
    top_left_ROI = double(MRI_image(10:corner_size+10, 10:corner_size+10));
    top_right_ROI = double(MRI_image(10:corner_size+10, image_width-corner_size-9:end-10));
    bottom_left_ROI = double(MRI_image(image_height-corner_size-9:end-10, 10:corner_size+10));
    bottom_right_ROI = double(MRI_image(image_height-corner_size-9:end-10, image_width-corner_size-9:end-10));

%     A = zeros(image_height, image_width);
%     A(10:corner_size+10, 10:corner_size+10) = top_left_ROI;
%     A(10:corner_size+10, image_width-corner_size-9:end-10) = top_right_ROI;
%     A(image_height-corner_size-9:end-10, 10:corner_size+10) = bottom_left_ROI;
%     A(image_height-corner_size-9:end-10, image_width-corner_size-9:end-10) = bottom_right_ROI;
%     figure;imshow(A,[]);colormap jet;colorbar;

    
    % 计算每个ROI的标准差
    std_top_left = std(top_left_ROI(:));
    std_top_right = std(top_right_ROI(:));
    std_bottom_left = std(bottom_left_ROI(:));
    std_bottom_right = std(bottom_right_ROI(:));
    
    % 计算四个标准差的均值作为噪声估计
    std_noise = mean([std_top_left, std_top_right, std_bottom_left, std_bottom_right]);

end

function res = anaylse_brain_mean(x)
% %%%for signal  用于分析脑部图像的平均信号强度
%         imagesc(abs(x),[0,1]);colormap jet;colorbar;
    origin_image=abs(x);
    w=10;
    signal_pos = [   35,65,w,w;   
                     75,65,w,w; 
                     55,48,w,w;
                     55,80,w,w];  %其中每一行表示一个感兴趣区域的位置和大小
    [num_block,~] = size(signal_pos);
    for loopi = 1:num_block
        temp_col = signal_pos(loopi,1);
        temp_row = signal_pos(loopi,2);
        temp_w = signal_pos(loopi,3);
        temp_h = signal_pos(loopi,4);
        signal_Intense= origin_image(temp_row:temp_row+temp_h,temp_col:temp_col+temp_w);  %提取感兴趣区域的图像子区域。
        Intense(:,:)= abs(signal_Intense);
        mean_signal128(loopi) = mean(Intense(:));  %计算并保存子区域的平均信号强度
%             rectangle('position',signal_pos(loopi,:),'edgecolor','r');
    end
    mean_signal=mean(mean_signal128(:));  %计算所有感兴趣区域的平均信号强度
    res=mean_signal;
end