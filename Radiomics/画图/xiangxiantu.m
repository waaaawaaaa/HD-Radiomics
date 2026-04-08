% 需要分组的数据，size 11*4
group1 = [2.5971    3.3004    2.5300    1.4816;...
    4.5358    4.3818    2.3258    1.6239; ...
    3.9728    3.9066    2.5668    2.3065; ...
    4.8788    3.7533    2.3690    1.6233; ...
    4.0810    4.0487    2.3443    1.4953; ...
    4.3254    3.1829    3.5859    2.6255; ...
    3.2180    3.9221    2.9497    1.9923; ...
    4.6776    3.8937    3.2284    2.2298; ...
    3.3915    3.8000    3.7869    1.9339; ...
    4.2484    4.1819    1.8148    1.8452; ...
    4.8277    4.1940    2.9338    1.7708]
group2 = [4.5730    4.3172    3.1523    1.6662; ...
    5.7332    4.9923    3.2012    2.1913; ...
    4.5736    4.8696    3.3527    3.0092; ...
    5.5416    4.6020    2.7714    2.0871; ...
    5.3273    4.0853    3.2455    2.2208; ...
    5.2967    5.4538    4.0582    3.1677; ...
    4.0403    4.4890    3.4762    2.7582; ...
    3.6837    5.6476    4.2450    2.8042; ...
    5.0343    5.1616    5.1146    2.1429; ...
    5.2017    4.6968    2.6056    2.2122; ...
    5.9474    5.7000    3.9155    2.2271]
% 边框颜色，都一样，用黑色
edgecolor1 = [0,0,0];
edgecolor2 = [0,0,0];
% 箱线图框内填充颜色
filledcolor1 = [46,114,188]/255;
filledcolor2 = [206,85,255]/255; 
% 注意这里和方法1的颜色填充顺序是反过来，先filledcolor2再filledcolor1,因为后面代码findobj先索引到的是最右侧的颜色分组
filledcolor = [repmat(filledcolor2, size(group1,2), 1); repmat(filledcolor1, size(group2,2), 1)]
pos1 = 0.8:3:9.8;
pos2 = 1.4:3:10.4;
box_1 = boxplot(group1,'positions',pos1,'Colors',edgecolor1,'Widths',0.4,'Symbol','o','OutlierSize',5)
set(box_1,'LineWidth',1.5);
hold on;
box_2 = boxplot(group2,'positions',pos2,'Colors',edgecolor2,'Widths',0.4,'Symbol','o','OutlierSize',5)
set(box_2,'LineWidth',1.5);
set(gca,'XTick', (pos1+pos2)/2, 'XTickLabel', ["Group1", "Group2","Group3","Group4"],'Xlim',[0 12],'Ylim',[0 7]);
plot(pos1, mean(group1), '-*', 'Color', filledcolor1)
plot(pos2, mean(group2), '-*','Color',filledcolor2)
hold off
% 这里findobj返回的box的顺序是从最右侧到最左侧，不清楚可以取出一个box通过看XData和YData坐标来知道
boxobj = findobj(gca, 'Tag', 'Box')
% m = []
% n = []
for i = 1:length(boxobj)
    patch(get(boxobj(i), 'XData'), get(boxobj(i), 'YData'), filledcolor(i,:), 'FaceAlpha', 0.5)
%     m = [m, get(boxobj(i), 'XData')]   
%     n = [n, get(boxobj(i), 'YData')]
end
% m1 = reshape(m,[],length(boxobj))
% m2 = m1'
% n1 = reshape(n,[],length(boxobj))
% n2 = n1'
% plot(m2(1,:),n2(1,:),'-o')
% patch(m2(1,:),n2(1,:),'r')
% a = get(boxobj(1),'XData')
% b = get(boxobj(1),'YData')
% patch(a,b,'red')
leg = get(gca, 'Children')
l = legend([leg(1),leg(5)], ["A_ratio","B_ratio"])
set(l,'Interpreter','none') %防止下划线_被误解析，或者可用strrep
ylabel('Ratio')
set(gca,'XGrid','off','YGrid','on', 'LineWidth', 2, 'Fontsize', 11)
% savefig(gcf,'boxplot_ratio.fig');
% print(gcf, '-dpdf', 'boxplot_ratio.pdf')  % 保存为pdf文件