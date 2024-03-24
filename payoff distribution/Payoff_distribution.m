clear;clc;close all
%% Importing data
load('Beta_parameter_data.mat');
load('Energy_load_data.mat');
Price=[0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.4;...
    0.6 0.6 0.6 0.6 0.6 0.6 0.6 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.7 0.6]*10^(-3);
Time=5; %Time∈[1,24], it represents 24 trading cycles from 1:00 to 24:00, where Time=5 indicates the trading time from 5:00 to 6:00.
eta=Price(1,Time);%The retail price of energy set by prosumers
mu=Price(2,Time);%The penalty price of energy caused by breach of contract
N=50;%Prosumer的数目
if Time>=5 && Time<=21 %Day time
    Type=zeros(N,2);%The first column indicates whether the user owns RES, and the second column indicates whether the user owns BESS
    % Initialize RES
    A_type=[10,12,14,16,18,20,0,0,0,0];
    k=0.3+0.1*rand(1,N);
    A=zeros(1,N);
    temp1=randi([1,10],[1,N]);
    for i=1:length(temp1)
        A(i)=A_type(temp1(i));
    end
    Type(A>0,1)=1;
    % Initialize BESS
    E_max=[4000,4200,4400,4600,4800,5000,0,0,0,0];
    E=zeros(1,N);
    temp2=randi([1,10],[1,N]);
    for i=1:length(temp2)
        if A_type(temp1(i))+E_max(temp2(i))==0
            E(i)=E_max(randi([1,6],1))*(0.3+0.2*rand);
        else
            E(i)=E_max(temp2(i))*(0.3+0.2*rand);
        end
    end
    Type(E>0,2)=1;
    % Initialize prosumer energy load
    alpha=Beta_parameter_data(Time,1);
    beta=Beta_parameter_data(Time,2);
    normalized=120;
    L=Energy_load_data(1:N,Time)';
    LL=(normalized*k.*A*alpha)/(alpha+beta)+E-L;
    break_index=find(LL<20);
    L(break_index)=L(break_index)-abs(LL(break_index)*1.5);
    % Initialize contract capacity
    rand_temp=normrnd((mu+eta)/(2*mu),1,1,10*N);
    rand_index=find(rand_temp>0 & rand_temp<(eta+mu)/mu);
    coeff=rand_temp(rand_index(1:N));
    e=((normalized*k.*A*alpha)/(alpha+beta)+E-L).*coeff;
    h=e+L-E;
    %% Calculate the payoff in non-cooperative scenario
    V_ncoop=zeros(1,N);%Initialize the payoff in non-cooperative scenario
    index1=setdiff(find(Type(:,1))',find(Type(:,2))');%Type 1 prosumer
    index2=setdiff(find(Type(:,2))',find(Type(:,1))');%Type 2 prosumer
    index3=setdiff(1:N,[index1,index2]);%Type 3 prosumer
    delta=zeros(1,N);
    delta(index1)=k(index1).*A(index1);
    delta(index3)=k(index3).*A(index3);
    lambda=zeros(1,N);
    lambda(index1)=h(index1)./delta(index1);
    lambda(index3)=h(index3)./delta(index3);
    % Type 1
    for j1=index1
        f1 = @(x) (h(j1)-delta(j1)*normalized*x).*betapdf(x,alpha,beta);
        V_ncoop(j1)=e(j1)*eta-integral(f1,0,lambda(j1)/normalized)*mu;
    end
    % Type 2
    for j2=index2
        if h(j2)<0
            V_ncoop(j2)=e(j2)*eta;%h<0 means the energy of BESS is sufficient to fulfill the contract.
        else
            V_ncoop(j2)=e(j2)*eta-h(j2)*mu;%h>0 means the energy of BESS is not sufficient to fulfill the contract, resulting in default costs
        end
    end
    % Type 3
    for j3=index3
        if h(j3)<0
            V_ncoop(j3)=e(j3)*eta;
        else
            f3 = @(x) (h(j3)-delta(j3)*normalized*x).*betapdf(x,alpha,beta);%第三类prosumer的平均收益的函数
            V_ncoop(j3)=e(j3)*eta-integral(f3,0,lambda(j3)/normalized)*mu;%更新第三类prosumer的纯利润
        end
    end
    Sum_ncoop=sum(V_ncoop);
    %% Calculate the payoff in cooperative scenario
    H=sum(h);
    Delta=sum(k.*A);
    Lambda=H/Delta;
    if H<0
        Sum_coop=sum(e*eta);
    else
        F = @(x) (H-Delta*normalized*x).*betapdf(x,alpha,beta);
        Sum_coop=sum(e*eta)-integral(F,0,Lambda/normalized)*mu;
    end
    %% Calculate the payoff distribution by using the Shapley value method
    m=10^4;% m is the number of sample size, and the larger the sample size for random sampling, the more accurate the estimation of the Shapley value
    TV=zeros(1,N);%Initialize the Shapley value
    for i=1:m
        disp([num2str(i/m*100),'%']);%Calculation process
        Perm=randperm(N);%Generate a random permutation
        for j=1:N
            index=find(Perm==j);%Find the index of prosumer j in the permutation
            S_index=sort(Perm(1:index-1));%Extract the set of prosumers before prosumer j in the permutation, sort them, and identify the small alliance that prosumer j did not participate in
            S_type=Type(S_index,:);%Find the type information of all prosumers in the set that does not include j
            Temp_in1=setdiff(find(S_type(:,1))',find(S_type(:,2))');%Relative index of the type 1 prosumers
            Temp_in2=setdiff(find(S_type(:,2))',find(S_type(:,1))');%Relative index of the type 2 prosumers
            Temp_in3=setdiff(1:length(S_index),[Temp_in1,Temp_in2]);%Relative index of the type 3 prosumers
            Index1=S_index(Temp_in1);
            Index2=S_index(Temp_in2);
            Index3=S_index(Temp_in3);
            H=sum(h(S_index));%The total energy deficit of the prosumer coalition S_index
            %% When prosumer j does not join the coalition
            if isempty([Index1,Index3])
                if H<0
                    V=sum(e(S_index).*eta);
                else
                    V=sum(e(S_index).*eta)-H*mu;
                end
            else
                Delta=sum(k(S_index).*A(S_index));
                Lambda=H/Delta;
                F = @(x) (H-Delta*normalized*x).*betapdf(x,alpha,beta);
                V=sum(e(S_index)*eta)-integral(F,0,Lambda/normalized)*mu;
            end
            if Type(j,1)==1 && Type(j,2)==0 %Type 1
                Index1_p=[Index1,j];Index2_p=Index2;Index3_p=Index3;
            elseif Type(j,1)==0 && Type(j,2)==1 %Type 2
                Index1_p=Index1;Index2_p=[Index2,j];Index3_p=Index3;
            else %Type 3
                Index1_p=Index1;Index2_p=Index2;Index3_p=[Index3,j];
            end
            H_p=sum(h([S_index,j]));
            %% When prosumer j joins the coalition
            if isempty([Index1_p,Index3_p])
                if H_p<0
                    Vp=sum(e([S_index,j]).*eta);
                else
                    Vp=sum(e([S_index,j]).*eta)-H_p*mu;
                end
            else
                Delta_p=sum(k([S_index,j]).*A([S_index,j]));
                Lambda_p=H_p/Delta_p;
                F = @(x) (H_p-Delta_p*normalized*x).*betapdf(x,alpha,beta);%包含第一和第三类参与者合作后平均收益的函数
                Vp=sum(e([S_index,j])*eta)-integral(F,0,Lambda_p/normalized)*mu;%小联盟所有prosumer在合作时的纯利润之和
            end
            TV(j)=TV(j)+(Vp-V);%Calculate the average marginal contribution of j
        end
    end
    Shapley=TV/m;%Estimate the Shapely value
    V_Shapley=Sum_coop*Shapley/sum(Shapley);%Distribute payoff based on the estimated Shapley values
    Delta_V=V_Shapley-V_ncoop;%Calculate the increased payoff
    %% plot
    plot_payoff(N,V_Shapley,V_ncoop);
else %% Night time
    % Initialize parameters
    Type=zeros(N,2);%The first list indicates whether the prosumer has RES, and the second list indicates whether the prosumer has BESS
    Type(:,2)=1;%Prosumers trading at night all have BESS
    % Initialize BESS
    E_max=[4000,4200,4400,4600,4800,5000,0,0,0,0];
    E=E_max(randi([1,6],1,N))*(0.3+0.2*rand);
    alpha=Beta_parameter_data(Time,1);
    beta=Beta_parameter_data(Time,2);
    L=Energy_load_data(1:N,Time)';%The energy load of prosumers (real data)
    LL=E-L;%Calculate prosumer's actual net power
    break_index=find(LL<0);%Exception handling
    L(break_index)=L(break_index)-abs(LL(break_index)*1.5);
    rand_temp=normrnd((mu+eta)/(2*mu),1,1,10*N);
    rand_index=find(rand_temp>0 & rand_temp<(eta+mu)/mu);
    coeff=rand_temp(rand_index(1:N));
    e=(E-L).*coeff;
    h=e+L-E;
    V_ncoop=zeros(1,N);%Initialize payoff
    %% Compute the collective payoffs of the prosumer in the noncooperative scenario
    index1=setdiff(find(Type(:,1))',find(Type(:,2))');%Index of type 1 prosumer
    index2=setdiff(find(Type(:,2))',find(Type(:,1))');%Index of type 2 prosumer
    index3=setdiff(1:N,[index1,index2]);%Index of type 3 prosumer
    % Type 2 prosumer
    for j2=index2
        if h(j2)<0
            V_ncoop(j2)=e(j2)*eta;
        else
            V_ncoop(j2)=e(j2)*eta-h(j2)*mu;
        end
    end
    %% Compute the collective payoffs of the prosumer in the cooperative scenario
    H=sum(h);
    if H<0
        Sum_coop=sum(e*eta);
    else
        Sum_coop=sum(e*eta)-H*mu;%The collective payoffs for all prosumers in the cooperative scenario
    end
    %% estimation for Shapely value
    m=10^4;%The number of all samples
    TV=zeros(1,N);%Initialize total marginal contribution
    for i=1:m
        disp([num2str(i/m*100),'%']);%Calculate progress
        Perm=randperm(N);%Generate a random permutation
        for j=1:N
            index=find(Perm==j);%Find the index of prosumer j in the permutation
            S_index=sort(Perm(1:index-1));%Extract the set of prosumers before prosumer j in the permutation, sort them, and identify the small alliance that prosumer j did not participate in
            S_type=Type(S_index,:);%Find the type information of all prosumers in the set that does not include j
            Temp_in1=setdiff(find(S_type(:,1))',find(S_type(:,2))');%Relative index of the type 1 prosumers
            Temp_in2=setdiff(find(S_type(:,2))',find(S_type(:,1))');%Relative index of the type 2 prosumers
            Temp_in3=setdiff(1:length(S_index),[Temp_in1,Temp_in2]);%Relative index of the type 3 prosumers
            Index1=S_index(Temp_in1);
            Index2=S_index(Temp_in2);
            Index3=S_index(Temp_in3);
            H=sum(h(S_index));%The total energy deficit of the prosumer coalition S_index
            % When prosumer j does not join the coalition
            if isempty([Index1,Index3])
                if H<0
                    V=sum(e(S_index).*eta);
                else
                    V=sum(e(S_index).*eta)-H*mu;
                end
            else
                Delta=sum(k(S_index).*A(S_index));
                Lambda=H/Delta;
                F = @(x) (H-Delta*normalized*x).*betapdf(x,alpha,beta);
                V=sum(e(S_index)*eta)-integral(F,0,Lambda/normalized)*mu;
            end
            if Type(j,1)==1 && Type(j,2)==0
                Index1_p=[Index1,j];Index2_p=Index2;Index3_p=Index3;
            elseif Type(j,1)==0 && Type(j,2)==1
                Index1_p=Index1;Index2_p=[Index2,j];Index3_p=Index3;
            else
                Index1_p=Index1;Index2_p=Index2;Index3_p=[Index3,j];
            end
            H_p=sum(h([S_index,j]));
            %% When prosumer j joins the coalition
            if isempty([Index1_p,Index3_p])
                if H_p<0
                    Vp=sum(e([S_index,j]).*eta);
                else
                    Vp=sum(e([S_index,j]).*eta)-H_p*mu;
                end
            else
                Delta_p=sum(k([S_index,j]).*A([S_index,j]));
                Lambda_p=H_p/Delta_p;
                F = @(x) (H_p-Delta_p*normalized*x).*betapdf(x,alpha,beta);
                Vp=sum(e([S_index,j])*eta)-integral(F,0,Lambda_p/normalized)*mu;
            end
            TV(j)=TV(j)+(Vp-V);%Calculate the total marginal contribution of j
        end
    end
    Shapley=TV/m;%Estimation of the Shapely value
    V_Shapley=Sum_coop*Shapley/sum(Shapley);%Calculate the payoff distribution based on the estimated Shapely value
    %% plot
    plot_payoff(N,V_Shapley,V_ncoop);
end