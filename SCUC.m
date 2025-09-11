clc
clear all


nG = 3;    % number of generators
nT = 3;    % time periods
load_demand = [300 280 320];  % MW

% Generator data (a*P^2 + b*P + c)
a = [0.002 0.003 0.0015];
b = [10 15 8];
c = [100 120 80];
Pmin = [50 30 20];
Pmax = [200 150 100];
Ramp = [50 50 50];
StartupCost = [1000 800 600];

P = sdpvar(nG, nT, 'full');
u = binvar(nG, nT, 'full');

constraints = [];
startup = binvar(nG, nT, 'full');  % startup indicator
for t = 1:nT
    % Power balance
    constraints = [constraints, sum(P(:,t)) == load_demand(t)];
    
    for i = 1:nG
        % Generation limits
        constraints = [constraints, Pmin(i)*u(i,t) <= P(i,t) <= Pmax(i)*u(i,t)];
        
        % Ramping limits
        if t > 1
            constraints = [constraints, abs(P(i,t) - P(i,t-1)) <= Ramp(i)];
        end
    end
end
cost = 0;
cost = 0;
for t = 1:nT
    for i = 1:nG
        cost = cost + a(i)*P(i,t)^2 + b(i)*P(i,t) + c(i)*u(i,t);
        cost = cost + StartupCost(i)*startup(i,t);  % use startup var
    end
end
for i = 1:nG
    for t = 2:nT
        constraints = [constraints, startup(i,t) >= u(i,t) - u(i,t-1)];
    end
    constraints = [constraints, startup(i,1) == u(i,1)];  % first period
end
options = sdpsettings('solver','mosek','verbose',1);
optimize(constraints, cost, options);

% Display results
disp('Generation Schedule:');
value(P)

disp('Commitment Schedule:');
value(u)
