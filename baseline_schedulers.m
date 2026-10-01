function assign = baseline_schedulers(method, tasks, servers)
%BASELINE_SCHEDULERS  Round-robin, greedy, and classical PSO baselines.
%   method: 'roundrobin' | 'greedy' | 'pso'

n = numel(tasks.c); K = numel(servers);
if n == 0, assign = []; return; end

switch lower(method)
    case 'roundrobin'
        assign = mod(0:n-1, K) + 1;

    case 'greedy'
        load_ = zeros(1,K); assign = zeros(1,n);
        [~, order] = sort(tasks.c, 'descend');    % largest-demand-first
        for j = order
            [~, s] = min(load_ ./ servers);
            assign(j) = s;
            load_(s) = load_(s) + tasks.c(j);
        end

    case 'pso'
        p = sim_core('params');
        w = 0.7; c1 = 1.5; c2 = 1.5;
        proj = @(X) min(max(round(X),1),K);
        X = 1 + (K-1)*rand(p.P, n);
        V = -1 + 2*rand(p.P, n);
        pbest = X; pbestVal = zeros(1,p.P);
        for i = 1:p.P
            r = sim_core('objective', tasks, proj(X(i,:)), servers, p);
            pbestVal(i) = r.F;
        end
        [gbestVal, idx] = min(pbestVal); gbest = pbest(idx,:);
        for t = 1:p.Tmax
            r1 = rand(p.P,n); r2 = rand(p.P,n);
            V = w*V + c1*r1.*(pbest - X) + c2*r2.*(repmat(gbest,p.P,1) - X);
            X = min(max(X + V, 1), K);
            for i = 1:p.P
                r = sim_core('objective', tasks, proj(X(i,:)), servers, p);
                if r.F < pbestVal(i)
                    pbestVal(i) = r.F; pbest(i,:) = X(i,:);
                    if r.F < gbestVal, gbestVal = r.F; gbest = X(i,:); end
                end
            end
        end
        assign = proj(gbest);

    otherwise
        error('unknown method "%s"', method);
end
end
