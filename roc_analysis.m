%ROC_ANALYSIS  Detection / false-alarm trade-off (Section IV-F, Fig. 3).
%   H0 (honest):    R ~ Bernoulli(p_h)
%   H1 (malicious): R ~ Bernoulli(q)
%   Decision rule:  flag H1 iff S(t) <= Sth
%
%   IMPORTANT (Remark 6): thresholding the exponentially-smoothed S(t) is
%   NOT the Neyman-Pearson optimal test. The likelihood-ratio sufficient
%   statistic for i.i.d. Bernoulli is the UNWEIGHTED count. This script
%   also quantifies that gap in AUC.

clear; rng(7);
alpha = 0.8; T = 60; N = 100000;
p_h = 0.95; qLevels = [0.75 0.85 0.92];
SthGrid = linspace(0.50, 0.90, 25);

pfa = zeros(1, numel(SthGrid));
pd  = zeros(numel(qLevels), numel(SthGrid));
for i = 1:numel(SthGrid)
    Sth = SthGrid(i);
    pfa(i) = flagProb(p_h, Sth, alpha, T, N);
    for j = 1:numel(qLevels)
        pd(j,i) = flagProb(qLevels(j), Sth, alpha, T, N);
    end
end

fprintf('=== Best threshold within this constrained family (p_h=0.95) ===\n');
for target = [0.01 0.05 0.10 0.20]
    feas = SthGrid(pfa <= target);
    if isempty(feas), fprintf('  alpha_FA=%.2f : none feasible\n', target); continue; end
    SthStar = max(feas); k = find(SthGrid == SthStar, 1);
    fprintf('  alpha_FA=%.2f : Sth*=%.3f  P_FA=%.4f  P_D=[%.4f %.4f %.4f]\n', ...
            target, SthStar, pfa(k), pd(1,k), pd(2,k), pd(3,k));
end

figure;
subplot(1,2,1); hold on;
cols = {'r','m','g'};
for j = 1:numel(qLevels)
    plot(pfa, pd(j,:), ['-o' cols{j}], 'LineWidth', 1.5, ...
         'DisplayName', sprintf('q=%.2f', qLevels(j)));
end
plot([0 1],[0 1],'k:','DisplayName','chance');
xlabel('P_{FA}'); ylabel('P_D'); title('(a) ROC: threshold sweep');
legend('Location','southeast'); grid on; hold off;

subplot(1,2,2); hold on;
plot(SthGrid, pfa, '-ob', 'LineWidth', 1.5, 'DisplayName', 'P_{FA} (honest)');
for j = 1:numel(qLevels)
    plot(SthGrid, pd(j,:), ['-o' cols{j}], 'LineWidth', 1.5, ...
         'DisplayName', sprintf('P_D (q=%.2f)', qLevels(j)));
end
xline(0.65,'--k','DisplayName','S_{th}=0.65');
xlabel('S_{th}'); ylabel('Probability'); title('(b) Error rates vs threshold');
legend('Location','northwest'); grid on; hold off;

function p = flagProb(rate, Sth, alpha, T, N)
    S = Sth*ones(1,N);
    for t = 1:T
        R = double(rand(1,N) < rate);
        S = alpha*S + (1-alpha)*R;
    end
    p = mean(S <= Sth);
end
