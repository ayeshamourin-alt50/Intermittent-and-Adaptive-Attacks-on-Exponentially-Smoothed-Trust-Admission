# Intermittent-and-Adaptive-Attacks-on-Exponentially-Smoothed-Trust-Admission
MATLAB simulation code for Intermittent and Adaptive Attacks on Exponentially-Smoothed Trust Admission
# Code for "Intermittent and Adaptive Attacks on Exponentially-Smoothed Trust Admission"

MATLAB code accompanying the paper by A. S. Mourin, M. M. Uddin and M. S. Ahsan.
It verifies the theoretical results (Theorems 2-3, Lemma 1, Proposition 2),
the numerical first-passage analysis, the detection/ROC analysis, and the
scheduler comparison.
Archived on Zenodo; see the DOI badge below.

## Requirements
- MATLAB R2018b or later (uses `xline`)
- Statistics and Machine Learning Toolbox (`poissrnd`, `ttest`, `randsample`, `tiedrank`)
- No other toolboxes. Keep all files in the same folder.

## Files
| File | Purpose | Paper reference |
|---|---|---|
| `sim_core.m` | Shared primitives: parameters, trust update (Eq. 1), task generation, M/M/1-style delay (Eq. 7), objective (Eq. 2) | Sec. 2, 5.1 |
| `qpso_scheduler.m` | Trust-aware QPSO (Algorithm 1), with optional local-attractor ablation | Sec. 4, App. A |
| `baseline_schedulers.m` | Round-robin, greedy, classical PSO | Sec. 6.3 |
| `verify_theorem2.m` | Monte Carlo check of mean, variance and Hoeffding bound | Theorem 2, Fig. 2 |
| `verify_theorem3_adaptive.m` | Greedy adaptive attacker: no breach, optimality, alpha > Sth condition | Theorem 3 |
| `verify_lemma1_ternary.m` | Ternary dominance check | Lemma 1 |
| `verify_proposition2_alpha.m` | Derivative and turning point alpha* = 1 - 2*Delta^2 | Proposition 2 |
| `markov_firstpassage.m` | Absorbing Markov chain vs Monte Carlo | Sec. 3.3, Table 2 |
| `roc_analysis.m` | ROC / false-alarm vs detection trade-off | Sec. 3.6, 6.2, Fig. 3 |
| `verify_remark10_lemma1_check.m` | AUC gap, smoothed vs unweighted count; feasibility counterexample | Remark 10 |
| `run_scheduler_comparison.m` | Scenarios A-D over 15 seeds, t-tests, local-attractor ablation | Table 5, Fig. 9 |

## Usage
Run any script directly from the MATLAB command window, e.g.
`>> verify_theorem2`. Each script sets its own random seed.

Expected key outputs:
- `markov_firstpassage`: at (alpha, Sth, q) = (0.8, 0.65, 0.85), E[rounds to breach] = 22.06, P(breach by 50) = 0.8639
- `verify_theorem3_adaptive`: period-4 cycle (1,1,1,0), 25% defection, no breach
- `verify_proposition2_alpha`: alpha* = 0.92 for Delta = 0.2
- `run_scheduler_comparison`: prints mean +/- std for scenarios A-D and uncorrected paired t-tests.
  Holm-Bonferroni correction (Table 6) is applied separately.
  Runtime is several minutes (PSO/QPSO loops).

## Not included in this repository
The DQN baseline (Scenario E), PBFT message-complexity simulator, SimPy
resource bookkeeping, and the attacker-model/parameter-sweep figures
(Figs. 5-8, Table 7) were produced with a separate Python pipeline
[add here: included in /python, or "available on request"].

## Citation
See `CITATION.cff`. If you use this code, please cite the paper and the Zenodo DOI.

## License
MIT
