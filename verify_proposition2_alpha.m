%VERIFY_PROPOSITION2_ALPHA  Verification of Proposition 2.
%   B(alpha) = exp[-2*D^2*(1+alpha)/(1-alpha)]
%   (i)  B is strictly decreasing:  dB/dalpha = -4 D^2 B /(1-alpha)^2 < 0
%   (ii) |dB/dalpha| is NOT monotone: it peaks at alpha* = 1 - 2 D^2,
%        with peak value exp[2(D^2-1)]/D^2, then DIMINISHES as alpha -> 1.
%
%   NOTE: (ii) is the corrected statement. A naive argument that the
%   tightening "accelerates" as alpha -> 1 is invalid, because B(alpha)
%   itself decreases super-exponentially near alpha = 1.

clear;
D = 0.2;                                   % margin q - Sth
B = @(a) exp(-2*D^2*(1+a)./(1-a));
h = @(a) 4*D^2*B(a)./(1-a).^2;             % |dB/dalpha|

fprintf('=== (i) closed-form derivative vs finite differences, D=%.2f ===\n', D);
fprintf('%8s %16s %16s %10s\n','alpha','numerical','closed form','match');
for a = [0.5 0.7 0.8 0.9 0.95]
    hstep = 1e-6;
    numd = (B(a+hstep) - B(a-hstep)) / (2*hstep);
    ana  = -4*D^2*B(a)/(1-a)^2;
    fprintf('%8.2f %16.6f %16.6f %10s\n', a, numd, ana, ...
        string(abs(numd-ana) < 1e-4));
end

fprintf('\n=== (ii) turning point alpha* = 1 - 2*D^2 ===\n');
aStar = 1 - 2*D^2;
fprintf('Predicted alpha*  = %.6f\n', aStar);
grid = linspace(0.01, 0.99, 20000);
[~, k] = max(h(grid));
fprintf('Numerical argmax  = %.6f   match: %s\n', grid(k), ...
        string(abs(grid(k)-aStar) < 1e-3));
fprintf('Closed-form peak h(alpha*) = exp[2(D^2-1)]/D^2 = %.4f\n', ...
        exp(2*(D^2-1))/D^2);
fprintf('Numerical peak             = %.4f\n', h(grid(k)));

fprintf('\n=== h(alpha) rises then falls (confirms non-monotonicity) ===\n');
for a = [0.5 0.7 0.8 0.85 0.90 0.92 0.94 0.95 0.97]
    fprintf('  alpha=%.2f : h = %.4f\n', a, h(a));
end
