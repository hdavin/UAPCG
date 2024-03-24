clear;clc;close all
cd 'solar radiation data'\
Solar_data=readtable('Solar_AUS_EAST.xls');
Solar=Solar_data(:,5);
Solar=table2array(Solar);
cd ..

%% The hourly radiation intensity of the sun over the course of a year.
Day=365; % Number of days
generation=zeros(Day,24);% The (i, j) entry represents the solar radiation intensity for the jth hour of the ith day.
for i=1:Day
    generation(i,:)=Solar(24*(i-1)+1:24*i,1);
end
%% Parameter estimation for the beta distribution.
Beta_parameter_data=zeros(24,2); % Initialize solar radiation distribution parameters.
label_name={'8:00-9:00','9:00-10:00','10:00-11:00','11:00-12:00'};
figure
for i=5:21  %The moments of renewable energy generation
    data=generation(:,i)/max(generation(:,i));
    partition=30;% Number of intervals
    if 8<=i && i<=11 % Displaying the fitting results from 8:00 to 11:00.
        subplot(2,2,i-7)
        histfit(data,partition,'beta')
        title(label_name{i-7});
    end
    Beta_parameter_data(i,:) = betafit(data);
end
figure
for i=5:21  % The moments of renewable energy generation
    data=generation(:,i)/max(generation(:,i));
    if 8<=i && i<=11 % Displaying the QQ-plot from 8:00 to 11:00.
        subplot(2,2,i-7)
        gqqplot(data,'beta')
        title(label_name{i-7})
    end
end
save('Beta_parameter_data.mat','Beta_parameter_data');