%VERIFY_THEOREM2  Monte Carlo validation of Theorem 2 (intermittent attacker).
%   Reproduces Fig. 2 of the manuscript. Checks:
%     (1) E[S(t)] matches the closed form q + alpha^t (S0 - q)
%     (2) Var[S(t)] matches q(1-q)(1-alpha)/(1+alpha) * (1-alpha^(2t))
%     (3) q=0 corner case reproduces the persistent-attacker corollary
%     (4) the Hoeffding bound of Theorem 2(ii) holds everywhere
%
%   Expected (alpha=0.8, Sth=0.65): all bounds hold, zero violations.

clear; rng(2026);
alpha = 0.8; Sth = 0.65; S0 = Sth; Tmax = 50; N = 200000;

theoryMean = @(t, q, a) q + a.^t .* (S0 - q);
theoryVar  = @(t, q, a) q*(1-q)*(1-a)/(1+a) * (1 - a.^(2*t));
bound = @(t, D, a) exp(-2*D^2*(1+a).*(1-a.^t) ./ ((1-a).*(1+a.^t)));

fprintf('=== CHECK 1-2: mean / variance vs Monte Carlo (q=0.85) ===\n');
q = 0.85; traj = simTraj(q, alpha, S0, Tmax, N);
fprintf('%4s %12s %12s %12s %12s\n','t','emp_mean','theory_mean','emp_var','theory_var');
for t = [0 1 2 5 10 20 50]
    fprintf('%4d %12.5f %12.5f %12.6f %12.6f\n', t, ...
        mean(traj(t+1,:)), theoryMean(t,q,alpha), ...
        var(traj(t+1,:)),  theoryVar(t,q,alpha));
end

fprintf('\n=== CHECK 3: q=0 corner case (persistent attacker) ===\n');
t0 = simTraj(0.0, alpha, S0, 1, 1000);
fprintf('Expected S(1) = alpha*Sth = %.4f\n', alpha*Sth);
fprintf('Simulated: min=%.4f max=%.4f | P(S(1)<Sth) = %.1f%%\n', ...
    min(t0(2,:)), max(t0(2,:)), 100*mean(t0(2,:) < Sth));

fprintf('\n=== CHECK 4: does the Hoeffding bound hold everywhere? ===\n');
allOK = true;
for a = [0.8 0.95]
    for q = [0.75 0.85 0.95]
        D = q - Sth;
        tr = simTraj(q, a, S0, Tmax, N);
        emp = mean(tr <= Sth, 2)';
        bd  = bound(0:Tmax, D, a);
        viol = emp > bd + 0.01;      % 0.01 tolerance for MC noise
        ok = ~any(viol); allOK = allOK && ok;
        fprintf('  alpha=%.2f q=%.2f (D=%.2f) steady bound=%.4f  [%s]\n', ...
            a, q, D, exp(-2*D^2*(1+a)/(1-a)), string(ok));
    end
end
fprintf('\nALL BOUNDS HOLD EVERYWHERE: %s\n', string(allOK));

function traj = simTraj(q, alpha, S0, T, n)
    S = S0*ones(1,n); traj = zeros(T+1,n); traj(1,:) = S;
    for t = 1:T
        R = double(rand(1,n) < q);
        S = alpha*S + (1-alpha)*R;
        traj(t+1,:) = S;
    end
end
