% 配准步骤
% 2025/01/13   zhumengying

% 前面得到了mapping图，全部转成nii格式
% 先对结构像进行偏移场校正，对所有图都重定位和去颅骨
% 对结构像归一化 用99%的值

%结构像的配准
%先全部配准到T2 FLAIR,在将模版配过来

ants_jiaqianxiang    %结构像的配准   先将T1W T2W配准到T2 FLAIR，再使用PD的T1W R2共同配准到受试者的T2 FLAIR T2W

ants_t2m
ants_t2s