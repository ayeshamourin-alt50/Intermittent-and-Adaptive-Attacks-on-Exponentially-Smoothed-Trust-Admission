%VERIFY_AE_ISSUES  Verification of the two substantive editorial issues.
%
% (1) Ternary-dominance feasibility gap (Lemma 1). The claim
%     "R=0.5 feasible => R=0 feasible" is FALSE. Since
%     dS_next/dR = (1-alpha) > 0, R=0 yields a strictly LOWER next state,
%     so R=0 feasibility is the STRONGER condition. The corrected proof
%     case-splits on whether alpha*S >= Sth holds directly.
%
% (2) Detection-theoretic claim (Section IV-F). Thresholding the
%     exponentially smoothed S(t) is NOT the Neyman-Pearson optimal test:
%     the LRT sufficient statistic for i.i.d. Bernoulli is the UNWEIGHTED
%     count. The AUC gap below quantifies the cost of smoothing.

clear; rng(0);
alpha = 0.8; Sth = 0.65;

fprintf('(1) Ternary feasibility counterexample:\n');
for S = linspace(Sth, 1.0, 5000)
    if (alpha*S + (1-alpha)*0.5 >= Sth - 1e-12) && (alpha*S < Sth - 1e-12)
        fprintf('    S=%.4f: R=0.5 -> S_next=%.4f (feasible); ', S, alpha*S+(1-alpha)*0.5);
        fprintf('R=0 -> S_next=%.4f (INFEASIBLE, < %.2f)\n', alpha*S, Sth);
        fprintf('    Confirms "R=0.5 feasible => R=0 feasible" is FALSE.\n\n');
        break;
    end
end

fprintf('(2) Detection power comparison (alpha=%.1f, p_h=0.95, q=0.85, T=30):\n', alpha);
T = 30; N = 200000; p_h = 0.95; q = 0.85;
R0 = double(rand(N,T) < p_h);
R1 = double(rand(N,T) < q);
w  = (1-alpha)*alpha.^(T-1:-1:0)';
S0 = alpha^T*Sth + R0*w;   S1 = alpha^T*Sth + R1*w;
C0 = sum(R0,2);            C1 = sum(R1,2);
aS = aucLower(S0, S1);     aC = aucLower(C0, C1);
fprintf('    AUC, exponentially-smoothed S (system): %.4f\n', aS);
fprintf('    AUC, unweighted count (LRT statistic):  %.4f\n', aC);
fprintf('    Smoothing costs %.4f AUC of detection power.\n', aC - aS);

function a = aucLower(x0, x1)
    allv = [x1; x0]; r = tiedrank(allv); n1 = numel(x1);
    a = 1 - (sum(r(1:n1)) - n1*(n1+1)/2) / (n1*numel(x0));
end
