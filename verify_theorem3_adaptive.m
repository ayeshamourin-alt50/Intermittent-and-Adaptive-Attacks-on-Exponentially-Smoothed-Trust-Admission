%VERIFY_THEOREM3_ADAPTIVE  Verification of Theorem 3 (adaptive attacker).
%   Greedy policy G: defect (R=0) iff alpha*S >= Sth, else behave (R=1).
%   Checks:
%     (i)   G never breaches the threshold
%     (ii)  G matches or beats every random feasible alternative policy
%     (iii) alpha > Sth is necessary AND sufficient for any defection
%
%   Expected at alpha=0.8, Sth=0.65: exact period-4 cycle (1,1,1,0),
%   sustaining a 25% defection rate with zero detection probability.

clear; rng(0);
alpha = 0.8; Sth = 0.65; T = 300;

[Rs, Smin] = greedyG(alpha, Sth, T);
fprintf('=== Theorem 3 at alpha=%.2f, Sth=%.2f ===\n', alpha, Sth);
fprintf('Defections in %d rounds: %d (rate %.3f)\n', T, sum(Rs==0), mean(Rs==0));
fprintf('Minimum S reached: %.6f  (Sth = %.2f)  never breached: %s\n', ...
        Smin, Sth, string(Smin >= Sth - 1e-9));
fprintf('Steady-state pattern (last 12 rounds of R): %s\n', mat2str(Rs(end-11:end)));

fprintf('\n=== (ii) optimality vs 500 random feasible policies ===\n');
gCount = sum(Rs==0); beaten = false;
for trial = 1:500
    S = Sth; cnt = 0; feasible = true;
    for t = 1:T
        canDefect = (alpha*S >= Sth - 1e-12);
        if canDefect && rand < 0.5, R = 0; else, R = 1; end
        if R == 0, cnt = cnt + 1; end
        S = alpha*S + (1-alpha)*R;
        if S < Sth - 1e-9, feasible = false; break; end
    end
    if feasible && cnt > gCount, beaten = true; break; end
end
fprintf('G >= all 500 random feasible alternatives: %s\n', string(~beaten));

fprintf('\n=== (iii) necessary AND sufficient condition alpha > Sth ===\n');
for pair = [0.6 0.65; 0.9 0.65]'
    a = pair(1); s = pair(2);
    [R2, ~] = greedyG(a, s, 2000);
    fprintf('  alpha=%.2f Sth=%.2f (alpha%sSth): defections = %d\n', ...
        a, s, ternary(a>s,'>','<='), sum(R2==0));
end

function [Rs, Smin] = greedyG(alpha, Sth, T)
    S = Sth; Rs = zeros(1,T); Smin = S;
    for t = 1:T
        if alpha*S >= Sth - 1e-12, R = 0; else, R = 1; end
        Rs(t) = R;
        S = alpha*S + (1-alpha)*R;
        Smin = min(Smin, S);
    end
end
function s = ternary(c, a, b)
    if c
        s = a;
    else
        s = b;
    end
end
