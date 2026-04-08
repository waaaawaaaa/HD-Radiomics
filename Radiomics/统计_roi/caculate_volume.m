% 从volumes计算体积
% Volume = numVoxels * voxelVolume;
% voxelVolume = 三个方向的分辨率相乘
%对于oled的数据来说分辨率是220/256×220/256×4

function Volume = caculate_volume(numVoxels)
    % Resolution of each voxel
    dx = 220/256; % Voxel size in x-direction (e.g., in mm)
    dy = 220/256; % Voxel size in y-direction (e.g., in mm)
    dz = 4; % Voxel size in z-direction (e.g., in mm)
    Volume = numVoxels*dx*dy*dz;
    
    % 还可以除以脑的总体积，算出一个标准化的相对体积
    % v_total = 

end