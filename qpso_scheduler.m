function [xbest, trace] = qpso_scheduler(tasks, servers, p, useLocalAttractor)
%QPSO_SCHEDULER  Algorithm 1: trust-aware QPSO task scheduling.
%
%   [xbest, trace] = QPSO_SCHEDULER(tasks, servers, p) runs the full
%   algorithm including the local-attractor step.
%
%   Setting useLocalAttractor = false reproduces the ablation of
%   Section VI-A: without the per-particle blend of personal-best and
%   global-best, every particle is pulled toward the same mean-best
%   point, swarm diversity collapses, and the fitness trace stays flat.
%
%   tasks   struct with fields c, d, sigma (see sim_core)
%   servers 1xK vector of capacities
%   p       parameter struct from sim_core('params')

if nargin < 4, useLocalAttractor = true; end

n = numel(tasks.c); K = numel(servers);
if n == 0, xbest = []; trace = 0; return; end

proj = @(X) min(max(round(X), 1), K);

% --- initialise swarm uniformly over {1..K}^n ---
X = 1 + (K-1)*rand(p.P, n);
pbest = X;
pbestVal = zeros(1, p.P);
for i = 1:p.P
    r = sim_core('objective', tasks, proj(X(i,:)), servers, p);
    pbestVal(i) = r.F;
end
[gbestVal, idx] = min(pbestVal);
gbest = pbest(idx, :);
trace = gbestVal;

for t = 1:p.Tmax
    p_mb = mean(pbest, 1);                    % population mean-best
    for i = 1:p.P
        if useLocalAttractor
            phi = rand(1, n);
            p_i = phi.*pbest(i,:) + (1-phi).*gbest;   % local attractor
        else
            p_i = p_mb;                                % ablated variant
        end
        u    = min(max(rand(1,n), 1e-6), 1-1e-6);
        sgn  = 2*randi([0 1], 1, n) - 1;               % uniform {-1,+1}
        X(i,:) = p_i + sgn .* (p.beta*abs(p_mb - X(i,:))) .* log(1./u);
        X(i,:) = min(max(X(i,:), 1), K);
        r = sim_core('objective', tasks, proj(X(i,:)), servers, p);
        if r.F < pbestVal(i)
            pbestVal(i) = r.F; pbest(i,:) = X(i,:);
            if r.F < gbestVal
                gbestVal = r.F; gbest = X(i,:);
            end
        end
    end
    trace(end+1) = gbestVal; %#ok<AGROW>
end

xbest = proj(gbest);
end
