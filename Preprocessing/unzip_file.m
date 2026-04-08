%整理并解压原始文件，sub001并没有患者名+日期的那个文件夹，手动补上
%2024/03/04 zhumengying

folderPath = 'G:\重建数据\亨廷顿舞蹈症'; % 指定文件夹路径

files = dir(folderPath); % 获取文件夹下的所有文件和文件夹信息

for i = 1:numel(files)
    if files(i).isdir && ~startsWith(files(i).name, '.') % 检查是否为文件夹且不是隐藏文件夹
        fprintf('文件名：%s\n', files(i).name); % 显示文件名
        subFolderPath = fullfile(folderPath, files(i).name); % 获取子文件夹路径
        subFiles = dir(subFolderPath); % 获取子文件夹下的所有文件和文件夹信息

        for j = 1:numel(subFiles)
            [~,~,fileExt] = fileparts(subFiles(j).name); % 获取文件扩展名
        
            if strcmp(fileExt, '.zip') % 如果是zip压缩包
                unzip(fullfile(subFolderPath, subFiles(j).name), subFolderPath); % 解压缩文件到同一子文件夹中
                delete(fullfile(subFolderPath, subFiles(j).name)); % 删除原始的压缩包文件
                fprintf('已解压缩并删除压缩包文件\n');
            end
        end
        
    end
end

