clear;clc;close all
unzip("prosumer energy load.zip")
%% Calculate the energy load of prosumers.
close all
Times=[1 24];
Users=1:100; % 100 prosumers
Energy_load_data=[];% Initialize the energy load of prosumer.
for j=Users
    disp(['Progress: ',num2str(j/length(Users)*100),'%'])
    cd 'prosumer energy load'\
    cd(strcat('user',num2str(j)));
    load(strcat('user',num2str(j),'.mat'));
    for i=Times
        for k1=1:length(userData)
            temp1(k1,1)=str2double(userData{k1,5});
            temp1(k1,2)=str2double(userData{k1,7});
        end
        for k2=1:48
            index1=find(temp1(:,1)==k2);
            temp2(1:length(index1),k2)=temp1(index1,2);
        end
        consumption=zeros(size(temp2,1),24);
        for k3=1:24
            consumption(:,k3)=temp2(:,2*(k3-1)+1)+temp2(:,2*k3);%Merge the half-hour energy load records into hourly records
        end
    end
    temp3=max(consumption);
    Index=find(temp3<1500 & temp3>0);
    Energy_load_data=[Energy_load_data;consumption(Index,:)];
    cd ..;cd ..
end
save('Energy_load_data.mat','Energy_load_data');