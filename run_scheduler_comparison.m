%RUN_SCHEDULER_COMPARISON  Scenarios A-E over multiple seeds (Table VII).
%   A: round-robin, no trust filter    D: classical PSO + blockchain
%   B: greedy + blockchain             (E: DQN baseline is Python-only,
%   C: QPSO  + blockchain               see pipeline_code/train_dqn.py)
%
%   Also runs the Section VI-A ablation: QPSO with and without the
%   local-attractor step, to confirm the step is necessary.

clear; rng(1000);
p = sim_core('params');
nSeeds = 15;
res = struct('A',[],'B',[],'C',[],'D',[]);
traceWith = []; traceWithout = [];

for seed = 1:nSeeds
    rng(1000 + seed);
    % --- devices: 20% persistent attackers, 5 trust rounds elapsed ---
    N = p.N; malFrac = 0.20;
    isMal = false(1,N); isMal(randperm(N, round(N*malFrac))) = true;
    devS = p.Sth*ones(1,N);
    for t = 1:5
        R = double(~isMal);                     % persistent: R=0 if malicious
        devS = sim_core('trustUpdate', devS, p.alpha, R);
    end
    lambda = 5 + 10*rand(1,N);
    servers = sim_core('makeServers', p.K);

    tasksAll = sim_core('genTasks', devS, -1, lambda, p.tau);   % no filter
    tasks    = sim_core('genTasks', devS, p.Sth, lambda, p.tau); % filtered

    aA = baseline_schedulers('roundrobin', tasksAll, servers);
    rA = sim_core('objective', tasksAll, aA, servers, p);
    aB = baseline_schedulers('greedy', tasks, servers);
    rB = sim_core('objective', tasks, aB, servers, p);
    [aC, tr] = qpso_scheduler(tasks, servers, p, true);
    rC = sim_core('objective', tasks, aC, servers, p);
    aD = baseline_schedulers('pso', tasks, servers);
    rD = sim_core('objective', tasks, aD, servers, p);

    res.A(end+1) = rA.success; res.B(end+1) = rB.success;
    res.C(end+1) = rC.success; res.D(end+1) = rD.success;

    if seed == 1
        traceWith = tr;
        [~, traceWithout] = qpso_scheduler(tasks, servers, p, false);
    end
    fprintf('seed %2d done (n_tasks=%d)\n', seed, numel(tasks.c));
end

fprintf('\n=== Scenario comparison (mean +/- std over %d seeds) ===\n', nSeeds);
f = fieldnames(res);
names = {'A: RR no-trust','B: Greedy+BC','C: QPSO+BC','D: PSO+BC'};
for i = 1:numel(f)
    v = res.(f{i})*100;
    fprintf('  %-16s %6.1f +/- %4.1f %%\n', names{i}, mean(v), std(v));
end

fprintf('\n=== Paired t-tests (uncorrected) ===\n');
[~,pCD] = ttest(res.C, res.D);
[~,pCB] = ttest(res.C, res.B);
[~,pBA] = ttest(res.B, res.A);
fprintf('  C vs D (QPSO vs PSO):     p = %.4f\n', pCD);
fprintf('  C vs B (QPSO vs Greedy):  p = %.4f\n', pCB);
fprintf('  B vs A (trust filter):    p = %.6f\n', pBA);
fprintf('  NOTE: apply Holm-Bonferroni across all pairwise tests (Table VIII).\n');

fprintf('\n=== Section VI-A ablation: local-attractor step ===\n');
fprintf('  With local attractor:    F start=%.4f end=%.4f  improved: %s\n', ...
        traceWith(1), traceWith(end), string(traceWith(end) < traceWith(1)));
fprintf('  Without (ablated):       F start=%.4f end=%.4f  improved: %s\n', ...
        traceWithout(1), traceWithout(end), string(traceWithout(end) < traceWithout(1)));

figure; hold on;
plot(0:numel(traceWithout)-1, traceWithout, 'Color',[.55 .59 .66], 'LineWidth',1.8);
plot(0:numel(traceWith)-1,    traceWith,    'r', 'LineWidth',1.8);
xlabel('iteration t'); ylabel('F(g_{best})');
legend('without local attractor','with local attractor (Alg. 1)');
title('QPSO convergence'); grid on; hold off;
