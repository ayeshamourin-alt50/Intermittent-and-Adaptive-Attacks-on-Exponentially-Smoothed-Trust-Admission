function out = sim_core(action, varargin)
%SIM_CORE Core primitives for the trust-aware MEC simulation.
%   Shared helpers used by the scheduler and verification scripts.
%   Trust update (Eq. 1):  S(t+1) = alpha*S(t) + (1-alpha)*R(t)
%
%   Usage:
%     C = sim_core('makeServers', K, rng_seed)
%     T = sim_core('genTasks', devS, Sth, lambda, horizon)
%     S = sim_core('trustUpdate', S, alpha, R)
%
%   NOTE: calibration constants match the manuscript (Section VII).

switch lower(action)

    case 'params'
        p.alpha        = 0.8;      % trust smoothing parameter
        p.Sth          = 0.65;     % admission threshold
        p.K            = 10;       % MEC servers
        p.N            = 100;      % devices
        p.tau          = 0.1;      % scheduling round, seconds (100 ms)
        p.rhoCap       = 0.92;     % utilisation clip (stability)
        p.deadlineNorm = 80;       % ms
        p.energyNorm   = 0.00012;  % mJ reference ceiling
        p.powerCoeff   = 0.15;     % mJ per MI
        p.wl = 0.5; p.we = 0.3; p.wt = 0.2;
        p.P  = 30;                 % QPSO swarm size
        p.Tmax = 50;               % QPSO iterations
        p.beta = 0.75;             % contraction-expansion coefficient
        out = p;

    case 'makeservers'
        K = varargin{1};
        out = 5 + 5*rand(1,K);     % C_i ~ U[5,10] MIPS

    case 'trustupdate'
        S = varargin{1}; alpha = varargin{2}; R = varargin{3};
        out = alpha.*S + (1-alpha).*R;

    case 'gentasks'
        % devS: vector of device trust scores; admission-filtered
        devS = varargin{1}; Sth = varargin{2};
        lambda = varargin{3}; horizon = varargin{4};
        demand = []; deadline = []; sigma = [];
        for i = 1:numel(devS)
            n = poissrnd(lambda(i)*horizon);
            for j = 1:n
                if devS(i) < Sth, continue; end          % admission filter
                demand(end+1)   = 0.02 + 0.07*rand;      %#ok<AGROW> MI
                deadline(end+1) = 20 + 60*rand;          %#ok<AGROW> ms
                sigma(end+1)    = devS(i);               %#ok<AGROW>
            end
        end
        out.c = demand; out.d = deadline; out.sigma = sigma;

    case 'queueingdelay'
        % M/M/1-style mean-waiting-time scaling (Eq. 7), Kleinrock 1975
        tasks = varargin{1}; assign = varargin{2};
        servers = varargin{3}; p = varargin{4};
        K = numel(servers); n = numel(tasks.c);
        D = zeros(1,K);
        for j = 1:n, D(assign(j)) = D(assign(j)) + tasks.c(j); end
        rho = min(D ./ (servers*p.tau), p.rhoCap);
        delay = zeros(1,n);
        for j = 1:n
            s = assign(j);
            base = 1000*tasks.c(j)/servers(s);           % ms
            delay(j) = base * rho(s)/(1-rho(s));
        end
        out = delay;

    case 'objective'
        tasks = varargin{1}; assign = varargin{2};
        servers = varargin{3}; p = varargin{4};
        n = numel(tasks.c);
        if n == 0, out.F = 0; out.success = 1; out.latency = 0; return; end
        qd  = sim_core('queueingDelay', tasks, assign, servers, p);
        lat = zeros(1,n); en = zeros(1,n); suc = zeros(1,n);
        for j = 1:n
            proc   = 1000*tasks.c(j)/servers(assign(j));
            lat(j) = proc + qd(j);
            en(j)  = p.powerCoeff*tasks.c(j)/100;
            suc(j) = double(lat(j) <= tasks.d(j));
        end
        L = mean(lat)/p.deadlineNorm;
        E = mean(en)/p.energyNorm;
        sig = mean(tasks.sigma);
        out.F       = p.wl*L + p.we*E + p.wt*(1-sig);
        out.success = mean(suc);
        out.latency = mean(lat);
        out.energy  = mean(en);

    otherwise
        error('sim_core: unknown action "%s"', action);
end
end
