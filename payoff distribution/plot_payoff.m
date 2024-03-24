function plot_payoff(N,V_Shapley,V_ncoop)
X1 = 1:N;
X2 = 1:N;
% 定义因变量
Y1 = V_Shapley;
Y2 = V_ncoop;
% 定义绘图参数
MarkerType = 'o';
MarkerSize = 6;
LineWidth = 1.2;
LineStyle = '-';
% 绘制
st1 = stem(X1,Y1,...
    'MarkerEdgeColor','r',...      % 符号轮廓颜色
    'MarkerFaceColor','r',...      % 符号填充颜色
    'Marker',MarkerType,...       % 符号类型
    'MarkerSize',MarkerSize,...   % 符号尺寸
    'LineWidth',LineWidth,...     % 线宽
    'LineStyle',LineStyle,...     % 线型
    'Color','r');                  % 线的颜色
hold on
st2 = stem(X2,Y2,...
    'MarkerEdgeColor','b',...      % 符号轮廓颜色
    'Marker',MarkerType,...       % 符号类型
    'MarkerSize',MarkerSize,...   % 符号尺寸
    'LineWidth',LineWidth,...     % 线宽
    'LineStyle',LineStyle,...     % 线型
    'Color','b');                  % 线的颜色
hXLabel = xlabel('Prosumer index');
hYLabel = ylabel('Payoff of the prosumer');
% 坐标轴美化
set(gca, 'Box', 'on', ...                                         % 边框
    'XGrid', 'off', 'YGrid', 'off', ...                      % 网格
    'TickDir', 'in', 'TickLength', [.015 .015], ...          % 刻度
    'XMinorTick', 'off', 'YMinorTick', 'on', ...              % 小刻度
    'XColor', [.1 .1 .1],  'YColor', [.1 .1 .1],...          % 坐标轴颜色
    'XTick', 1:N/10:N,...                                    % 坐标区刻度、范围
    'XLim', [0 N+1],...
    'YTick', 0:0.2:2,...
    'YLim', [0 max(Y1)+0.5]);
legend([st1,st2],...
    'Coalition game', 'Non-cooperative','Location', 'NorthWest','FontSize', 14)
% 字体和字号
set(gca, 'FontName', 'Times New Roman')
set([hXLabel, hYLabel], 'FontName', 'Times New Roman')
set(gca, 'FontSize', 12)
set([hXLabel, hYLabel], 'FontSize', 14)
end