clear;clc;close all
%% load data
load('Beta_parameter_data.mat');
load('Energy_load_data.mat');% Real energy load data
Price=[0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.4;...
    0.6 0.6 0.6 0.6 0.6 0.6 0.6 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.6]*10^(-3);
Prosumer=100;%The number of prosumers
Time=24;%The number of time intervals
normalized=120;%Normalization factor
A_type=[10,12,14,16,18,20,0,0,0,0];%Common sizes for residential solar panels, ranging from 10-20 square meters, with 0 square meters indicating no solar panels installed
Sum_coop=zeros(Prosumer,Time); % Initialize collective payoffs of the prosumer in the cooperative scenario
TT=[1 9 2 10 3 11 4 12];%Time interval
for N=1:Prosumer
    %% Initialize RES
    Type=zeros(N,2);%The first list indicates whether a prosumer owns RES，the second list indicates whether a prosumer owns BESS
    k=0.3+0.1*rand(1,N);%The energy conversion efficiency of a prosumer's solar panels is between 30% and 40%.
    A=zeros(1,N);%Initialize the area of the solar panel
    temp1=randi([1,10],[1,N]);%Randomly allocate solar panels
    for i=1:length(temp1)
        A(i)=A_type(temp1(i));%Randomly set the size of prosumer's solar panel, where A=0 indicates a prosumer does not have RES
    end
    Type(A>0,1)=1;%Mark prosumers who have RES as "1".
    %% Initialize BESS
    E_max=[4000,4200,4400,4600,4800,5000,0,0,0,0];%The upper limit of energy storage for batteries is set to 2-3 kWh, where 0 indicates no BESS is installed
    E=zeros(1,N);%Initialize battery energy
    temp2=randi([1,10],[1,N]);
    for i=1:length(temp2)
        if A_type(temp1(i))+E_max(temp2(i))==0 %Exception handling: prosumers without RES and BESS
            E(i)=E_max(randi([1,6],1))*(0.3+0.2*rand);
        else
            E(i)=E_max(temp2(i))*(0.3+0.2*rand);%Randomly set initial energy storage for prosumers' BESS.
        end
    end
    Type(E>0,2)=1;%Mark prosumers with Battery as "1"
    %L=1000*rand(1,N);% The energy load of prosumers (random data)
    L=Energy_load_data(1:N,Time)'; %The energy load of prosumers (real data)
    %%
    for n=1:length(TT)
        eta=Price(1,Time);%The retail price of energy set by prosumers
        mu=Price(2,Time);%The penalty price of energy caused by breach of contract
        %% Day time
        if Time>=5 && Time <=21
            alpha=Beta_parameter_data(Time,1);
            beta=Beta_parameter_data(Time,2);
            rand_temp=normrnd((mu+eta)/(2*mu),1,1,1000*N);
            rand_index=find(rand_temp>0);
            coeff=rand_temp(rand_index(1:N)); %Energy load prediction relative error (following normal distribution).
            e=((normalized*k.*A*alpha)/(alpha+beta)+E-L).*coeff;%The predict results of net power
            h=e+L-E;
            % Calculate the collective payoff.
            H=sum(h);%The total energy deficit of the prosumer coalition
            Delta=sum(k.*A);
            Lambda=H/Delta;
            if H<0
                Sum_coop(N,Time)=sum(e*eta);
            else
                F = @(x) (H-Delta*normalized*x).*betapdf(x,alpha,beta);%The function of expected payoff after cooperation.
                Sum_coop(N,Time)=sum(e*eta)-integral(F,0,Lambda/normalized)*mu;%The collective payoffs of the prosumer coalition.
            end
        else 
            %% Night time
            rand_temp=normrnd((mu+eta)/(2*mu),1,1,1000*N);
            rand_index=find(rand_temp>0);
            coeff=rand_temp(rand_index(1:N));%Energy load prediction relative error (following normal distribution)
            e=(E-L).*coeff;%The predict results of net power
            h=e+L-E;
            H=sum(h);%The total energy deficit of the prosumer coalition
            if H<0
                Sum_coop(N,Time)=sum(e*eta);
            else
                Sum_coop(N,Time)=sum(e*eta)-H*mu;%The collective payoffs of the prosumer coalition
            end
        end
    end
end
%% plot
for i=1:length(TT)
    subplot(4,2,i)
    X=1:Prosumer;
    Y=Sum_coop(1:Prosumer,TT(i));
    if TT(i)<5
        plot(X,Y,'b-','LineWidth',1);
        axis([1 Prosumer 0 50])
    else
        plot(X,Y,'r-','LineWidth',1);
        axis([1 Prosumer 0 70])
    end
    text(10,max(Y)-10,strcat(num2str(TT(i)),':00-',num2str(TT(i)+1),':00'));
    set(gca, 'FontName', 'Times New Roman')
    %set([hXLabel], 'FontName', 'Times New Roman')
    set(gca, 'FontSize', 10)
    %set([hXLabel],'Interpreter','tex', 'FontSize', 12)
    %set(hTitle, 'FontSize', 12, 'FontWeight' , 'bold')
end