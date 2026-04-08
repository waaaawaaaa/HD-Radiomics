
% % 自定义自然排序函数
% function sortedArray = customNatsort(array)
%     % 提取字符串中的数字部分
%     numbers = cellfun(@(x) sscanf(x, '%*[^0123456789]%d'), array);
%     
%     % 根据数字部分排序
%     [~, idx] = sort(numbers);
%     sortedArray = array(idx);
% end

%利用名字中的数字进行对结构体再排序
files = dir('D:\*.png');
for i = 1 : numel(files)
numsort(i)=str2num(files(i).name(2:eval('length(files(i).name)-4')));
end
[~,ind]=sort(numsort);
newfiles=files(index);
%也可以一个一个赋值
%for i = 1 : numel(files)
% newfiles(i)=files(ind(i));   
%end
