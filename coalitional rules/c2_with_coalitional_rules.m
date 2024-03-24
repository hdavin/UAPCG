clear;clc;close all
%% load data
load('Beta_parameter_data.mat');
load('Energy_load_data.mat');% Real energy load data
Price=[0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.4;...
    0.6 0.6 0.6 0.6 0.6 0.6 0.6 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.6]*10^(-3);
Prosumer=100;%The number of prosumers
TT=[1 9 2 10 3 11 4 12];%Time interval
for n=1:length(TT)
    Time=TT(n);
    eta=Price(1,Time);%The retail price of energy set by prosumers
    mu=Price(2,Time);%The penalty price of energy caused by breach of contract
    %% Day time
    if Time>=5 && Time<=21
        %% Initialize RES
        Type=zeros(Prosumer,2);%The first list indicates whether a prosumer owns RES，the second list indicates whether a prosumer owns BESS
        A_type=[10,12,14,16,18,20,0,0,0,0];%Common sizes for residential solar panels, ranging from 10-20 square meters, with 0 square meters indicating no solar panels installed
        k=0.3+0.1*rand(1,Prosumer);%The energy conversion efficiency of a prosumer's solar panels is between 30% and 40%
        A=zeros(1,Prosumer);%Initialize the area of the solar panel
        temp1=randi([1,10],[1,Prosumer]);%Randomly allocate solar panels
        for i=1:length(temp1)
            A(i)=A_type(temp1(i));%Randomly set the size of prosumer's solar panel, where A=0 indicates a prosumer does not have RES
        end
        Type(A>0,1)=1;%Mark prosumers with Battery as "1"
        %% Initialize BESS
        E_max=[4000,4200,4400,4600,4800,5000,0,0,0,0];%The upper limit of energy storage for batteries is set to 2-3 kWh, where 0 indicates no BESS is installed
        E=zeros(1,Prosumer);%Initialize battery energy
        temp2=randi([1,10],[1,Prosumer]);
        for i=1:length(temp2)
            if A_type(temp1(i))+E_max(temp2(i))==0 %Exception handling: prosumers without RES and BESS
                E(i)=E_max(randi([1,6],1))*(0.3+0.2*rand);
            else
                E(i)=E_max(temp2(i))*(0.3+0.2*rand);
            end
        end
        Type(E>0,2)=1;%Mark prosumers with Battery as "1"
        alpha=Beta_parameter_data(Time,1);
        beta=Beta_parameter_data(Time,2);
        %L=1000*rand(1,N);% The energy load of prosumers (random data)
        L=Energy_load_data(1:Prosumer,Time)'; %The energy load of prosumers (real data)
        LL=(100*k.*A*alpha)/(alpha+beta)+E-L;%Calculate prosumer's actual net power
        break_index=find(LL<0);%Exception handling
        L(break_index)=L(break_index)-abs(LL(break_index)*1.5);
        %% Coalitional rules
        rand_temp=normrnd((mu+eta)/(2*mu),1,1,10*Prosumer);
        rand_index=find(rand_temp>0 & rand_temp<(eta+mu)/mu);
        coeff=rand_temp(rand_index(1:Prosumer)); %Energy load prediction relative error (following normal distribution)
        e=((100*k.*A*alpha)/(alpha+beta)+E-L).*coeff;%%The predict results of net power
        h=e+L-E;
        Day_Sum_coop=zeros(1,Prosumer);%Initialize the collective payoff in the cooperative scenario
        Day_Sum_ncoop=zeros(1,Prosumer);%Initialize the collective payoff in the noncooperative scenario
        for P=2:Prosumer
            temp_N=P;
            V_ncoop=zeros(1,temp_N);
            temp_h=h(1:temp_N);
            temp_Type=Type(1:temp_N,:);
            temp_k=k(1:temp_N);
            temp_A=A(1:temp_N);
            temp_e=e(1:temp_N);
            %% Noncooperative scenario
            index1=setdiff(find(temp_Type(:,1))',find(temp_Type(:,2))');%Index of type 1 prosumer
            index2=setdiff(find(temp_Type(:,2))',find(temp_Type(:,1))');%Index of type 2 prosumer
            index3=setdiff(1:temp_N,[index1,index2]);%Index of type 3 prosumer
            delta=zeros(1,temp_N);
            delta(index1)=temp_k(index1).*temp_A(index1);
            delta(index3)=temp_k(index3).*temp_A(index3);
            lambda=zeros(1,temp_N);
            lambda(index1)=temp_h(index1)./delta(index1);
            lambda(index3)=temp_h(index3)./delta(index3);
            normalized=120;  %Normalization factor
            % Type 1 prosumer
            for j1=index1
                f1 = @(x) (temp_h(j1)-delta(j1)*normalized*x).*betapdf(x,alpha,beta);%Profit function
                V_ncoop(j1)=temp_e(j1)*eta-integral(f1,0,lambda(j1)/normalized)*mu;%Profit value
            end
            % Type 2 prosumer
            for j2=index2
                if temp_h(j2)<0 
                    V_ncoop(j2)=temp_e(j2)*eta;%Profit value, h<0 indicates that the battery energy is sufficient to fulfill the contract
                else
                    V_ncoop(j2)=temp_e(j2)*eta-temp_h(j2)*mu;
                end
            end
            % Type 3 prosumer
            for j3=index3
                if h(j3)<0
                    V_ncoop(j3)=temp_e(j3)*eta; %Profit value
                else
                    f3 = @(x) (temp_h(j3)-delta(j3)*normalized*x).*betapdf(x,alpha,beta);
                    V_ncoop(j3)=temp_e(j3)*eta-integral(f3,0,lambda(j3)/normalized)*mu;
                end
            end
            Day_Sum_ncoop(P)=sum(V_ncoop);%The collective payoffs of the prosumer in the noncooperative scenario
            %% Cooperative scenario
            H=sum(temp_h);%The total energy deficit of the prosumer coalition
            Delta=sum(temp_k.*temp_A);
            Lambda=H/Delta;
            if H<0
                Day_Sum_coop(P)=sum(temp_e*eta);
            else
                F = @(x) (H-Delta*normalized*x).*betapdf(x,alpha,beta);%Profit function
                Day_Sum_coop(P)=sum(temp_e*eta)-integral(F,0,Lambda/normalized)*mu;%The collective payoffs of the prosumer in the cooperative scenario
            end
        end
        %% plot
        subplot(4,2,n)
        plot(1:Prosumer,Day_Sum_coop(1:Prosumer),'r-',LineWidth=1);hold on
        plot(1:Prosumer,Day_Sum_ncoop(1:Prosumer),'k--',LineWidth=1);hold on
        legend(strcat('T=',num2str(TT(n))),'Location','NorthWest' );
        axis([1 Prosumer 0 max(Day_Sum_coop)+10])
    else 
        %% Night time
        Type=zeros(Prosumer,2);%The first list indicates whether a prosumer owns RES，the second list indicates whether a prosumer owns BESS
        Type(:,2)=1;%Prosumers involved in night-time trading all have BESS
        %% Initialize BESS
        E_max=[4000,4200,4400,4600,4800,5000,0,0,0,0];%The upper limit of energy storage for batteries is set to 2-3 kWh, where 0 indicates no BESS is installed
        E=E_max(randi([1,6],1,Prosumer))*(0.3+0.2*rand);%Randomize BESS
        L=Energy_load_data(1:Prosumer,Time)';%The energy load of prosumers (real data)
        LL=E-L;%Calculate prosumer's actual net power
        break_index=find(LL<0);%Exception handling
        L(break_index)=L(break_index)-abs(LL(break_index)*1.5);
        rand_temp=normrnd((mu+eta)/(2*mu),1,1,10*Prosumer);
        rand_index=find(rand_temp>0 & rand_temp<(eta+mu)/mu);
        coeff=rand_temp(rand_index(1:Prosumer)); %Energy load prediction relative error (following normal distribution)
        e=(E-L).*coeff;%The predict results of net power
        h=e+L-E;
        Night_Sum_coop=zeros(1,Prosumer);%Initialize the collective payoffs of the prosumer in the cooperative scenario
        Night_Sum_ncoop=zeros(1,Prosumer);%Initialize the collective payoffs of the prosumer in the noncooperative scenario
        for P=2:Prosumer
            temp_N=P;
            V_ncoop=zeros(1,temp_N);
            temp_h=h(1:temp_N);
            temp_Type=Type(1:temp_N,:);
            temp_e=e(1:temp_N);
            %% Compute the collective payoffs of the prosumer in the noncooperative scenario
            Night_Sum_ncoop(P)=sum(temp_e*eta)- sum(temp_h(temp_h>0)*mu);
            %% Compute the collective payoffs of the prosumer in the cooperative scenario
            H=sum(temp_h);%The total energy deficit of the prosumer coalition
            if H<0
                Night_Sum_coop(P)=sum(temp_e*eta);
            else
                Night_Sum_coop(P)=sum(temp_e*eta)-H*mu;
            end
        end
        %% plot
        subplot(4,2,n)
        plot(1:Prosumer,Night_Sum_coop(1:Prosumer),'b-',LineWidth=1);hold on
        plot(1:Prosumer,Night_Sum_ncoop(1:Prosumer),'k--',LineWidth=1);hold on
        legend(strcat('T=',num2str(TT(n))),'Location','NorthWest' );
        axis([1 Prosumer 0 max(Night_Sum_coop)+10])
    end
    set(gca, 'FontName', 'Times New Roman')
    set(gca, 'FontSize', 10)
end
