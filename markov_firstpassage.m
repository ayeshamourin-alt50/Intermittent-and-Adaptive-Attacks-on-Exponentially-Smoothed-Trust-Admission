%MARKOV_FIRSTPASSAGE  First-passage-time analysis via absorbing Markov chain.
%   Reproduces Section IV-C / Table III. Discretises [Sth,1] into M+1 states
%   plus an absorbing "breached" state, giving:
%       P(breach by round T) = 1 - e0' * Q^T * 1
%       E[rounds to breach]  = e0' * (I-Q)^-1 * 1
%   Cross-validated against direct Monte Carlo at three parameter settings.
%
%   Expected at (0.8,0.65,0.85): E[rounds]=22.06, P(breach by 50)=0.8639.

clear; rng(99);
settings = [0.8 0.65 0.85; 0.9 0.60 0.80; 0.7 0.50 0.75];
Ts = [5 10 20 30 50 100];
M = 400; N = 300000;

for s = 1:size(settings,1)
    alpha = settings(s,1); Sth = settings(s,2); q = settings(s,3);
    [mk, expRounds] = markovCurve(alpha, Sth, q, M, Ts);
    mc = mcCurve(alpha, Sth, q, Ts, N);
    fprintf('alpha=%.2f Sth=%.2f q=%.2f  E[rounds to breach]=%.2f\n', ...
            alpha, Sth, q, expRounds);
    for i = 1:numel(Ts)
        fprintf('   T=%3d: markov=%.4f  mc=%.4f  diff=%.4f\n', ...
                Ts(i), mk(i), mc(i), abs(mk(i)-mc(i)));
    end
    fprintf('\n');
end

function [out, expRounds] = markovCurve(alpha, Sth, q, M, Ts)
    grid = linspace(Sth, 1.0, M+1);
    Q = zeros(M+1, M+1);
    for i = 1:M+1
        sUp = alpha*grid(i) + (1-alpha);
        sDn = alpha*grid(i);
        if sUp >= Sth
            [~, iu] = min(abs(grid - sUp)); Q(i,iu) = Q(i,iu) + q;
        end
        if sDn >= Sth
            [~, id] = min(abs(grid - sDn)); Q(i,id) = Q(i,id) + (1-q);
        end
    end
    cur = zeros(1, M+1); cur(1) = 1.0;
    out = zeros(1, numel(Ts)); k = 1;
    for t = 1:max(Ts)
        cur = cur * Q;
        if any(Ts == t), out(k) = 1 - sum(cur); k = k + 1; end
    end
    v = (eye(M+1) - Q) \ ones(M+1,1);
    expRounds = v(1);          % expected rounds from starting state S(0)=Sth
end

function out = mcCurve(alpha, Sth, q, Ts, N)
    S = Sth*ones(1,N); breachedBy = -ones(1,N);
    out = zeros(1, numel(Ts)); k = 1;
    for t = 1:max(Ts)
        R = double(rand(1,N) < q);
        S = alpha*S + (1-alpha)*R;
        newly = (S < Sth - 1e-9) & (breachedBy == -1);
        breachedBy(newly) = t;
        if any(Ts == t)
            out(k) = mean(breachedBy ~= -1 & breachedBy <= t); k = k + 1;
        end
    end
end
