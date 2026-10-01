%VERIFY_LEMMA1_TERNARY  Verification of Lemma 1 (ternary dominance).
%   Claim: allowing R = 0.5 never lets an attacker exceed the binary-
%   restricted greedy policy G's full-defection count.
%
%   IMPORTANT: feasibility must be checked at ALL T+1 states of a T-round
%   sequence (including the state AFTER the final action). Checking only
%   T of them produces a spurious apparent counterexample.
%
%   Also demonstrates the key subtlety in the proof: R=0.5 being feasible
%   does NOT imply R=0 is feasible, since dS_next/dR = (1-alpha) > 0.

clear; rng(0);
alpha = 0.8; Sth = 0.65;

fprintf('=== Feasibility direction check (proof Case A vs Case B) ===\n');
found = false;
for S = linspace(Sth, 1.0, 5000)
    if (alpha*S + (1-alpha)*0.5 >= Sth - 1e-12) && (alpha*S < Sth - 1e-12)
        fprintf('At S=%.4f:  R=0.5 -> %.4f (feasible)\n', S, alpha*S+(1-alpha)*0.5);
        fprintf('            R=0   -> %.4f (INFEASIBLE, < %.2f)\n', alpha*S, Sth);
        fprintf('Confirms "R=0.5 feasible => R=0 feasible" is FALSE.\n');
        found = true; break;
    end
end
if ~found, fprintf('no counterexample found (unexpected)\n'); end

T = 15;
gCount = greedyCount(alpha, Sth, T);
fprintf('\n=== Random ternary search (20000 samples, T=%d) ===\n', T);
best = -1; bestSeq = [];
for trial = 1:20000
    seq = randsample([0 0.5 1], T, true, [0.3 0.2 0.5]);
    [feasible, cnt] = evalSeq(seq, alpha, Sth);
    if feasible && cnt > best, best = cnt; bestSeq = seq; end
end
fprintf('Best ternary count: %d   Binary greedy G: %d   beats G: %s\n', ...
        best, gCount, string(best > gCount));
if ~isempty(bestSeq)
    fprintf('Best sequence uses R=0.5: %s\n', string(any(bestSeq==0.5)));
end

fprintf('\n=== Hand-crafted adversarial patterns exploiting R=0.5 ===\n');
pats = {repmat(0.5,1,10), [repmat([0.5 1],1,7) 0], [1 1 0.5 0], ...
        repmat([0.5 0.5 0],1,5), repmat([0 0.5 0.5 1],1,4)};
names = {'all-0.5 charging','alternate 0.5/1','0.5 before defect', ...
         'two 0.5s then defect','defect,0.5,0.5,1'};
for i = 1:numel(pats)
    [f, c] = evalSeq(pats{i}, alpha, Sth);
    g = greedyCount(alpha, Sth, numel(pats{i}));
    if f, s = sprintf('count=%d', c); else, s = 'INFEASIBLE'; end
    fprintf('  %-22s T=%2d  %-12s  G=%d  beats G: %s\n', ...
            names{i}, numel(pats{i}), s, g, string(f && c > g));
end

function [feasible, cnt] = evalSeq(seq, alpha, Sth)
    S = Sth; cnt = 0; states = S;
    for k = 1:numel(seq)
        if seq(k) == 0, cnt = cnt + 1; end
        S = alpha*S + (1-alpha)*seq(k);
        states(end+1) = S; %#ok<AGROW>
    end
    feasible = all(states >= Sth - 1e-9);   % ALL T+1 states
end
function c = greedyCount(alpha, Sth, T)
    S = Sth; c = 0;
    for t = 1:T
        if alpha*S >= Sth - 1e-12, R = 0; c = c + 1; else, R = 1; end
        S = alpha*S + (1-alpha)*R;
    end
end
