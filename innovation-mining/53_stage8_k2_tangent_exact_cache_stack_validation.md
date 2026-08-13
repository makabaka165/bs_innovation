# Stage8 K2 Tangent Exact Cache Stack Validation

## Outcome

- Completion: `STAGE8_K2_TANGENT_EXACT_CACHE_STACK_VALIDATION_COMPLETE`
- Correctness: `PASS_C_D_72_OF_72`
- Performance: `MEASURED_CACHE_STACK_NONPOSITIVE`
- Final recommendation: `DO_NOT_RETAIN_NONPOSITIVE_LAYERS`
- Production default: `CACHE_OFF`

## Measured WARM result

- Paired point saving: -0.3211301 s
- One-sided 95% lower bound: -0.61869 s
- Runtime reduction: -0.092790%
- Speedup ratio: 0.999072962
- AB / BA points: -0.31764125 s / -0.18683145 s

## Exposure and correctness

- Pass C/D: 72/72; CACHE_OFF qualification: 72/72
- Integrated C1 hook: 0 hit, 5904 miss; collision=0; truth leakage=0
- C2-C4: rejected because no frozen additive seam.
- C5R/C5P/C6/C7: rejected because the legal scope had no exact reuse evidence.

## Theory boundaries (not interchangeable)

- `0.600809%`: conditional direct-G to lookup increment.
- `3.715591%`: C1 + structural gross zero-C2-C4-overhead hypothesis.
- `3.765156%`: adds a zero-incremental-C5R-hit-cost hypothesis.
- `3.952132%`: additive known-exposure G-dictionary zero-lookup ceiling.
- `4.001697%`: additive known-exposure primitive zero-hit-cost ceiling.
- `4.345031%`: prior structural+G-only+cache model, not a cache-only target.

## Lifecycle

- COLD_BUILD_72_TRIALS_NONPOSITIVE
- COLD_LOAD_72_TRIALS_NONPOSITIVE
- COLD_BUILD_NO_BREAK_EVEN
- COLD_LOAD_NO_BREAK_EVEN

## Provenance

- Integration commit: `e4ae31d260560833f38e5c1cd30472f7e44ad079`
- Evidence write base: `92e2c419436adb806b10ce19eba0f2dce4dbb077`
- Run ID: `6e55badf77595e7ea563648f29672863d0f4fa7780d64fb12045dff4f7a6633c`
- Freeze chain: `39681c3e6bf55c4ffc39635b7957e32905b4eac380a60c0579be31cfce29623f`
- Screening status: `MEASURED_SAVING_NONPOSITIVE_SCREENING`

No causal cache/Tangent synergy or deployment justification is claimed.
