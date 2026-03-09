# Source Trust Report

## Trust Classification

**Overall trust level**: CONTROLLED

**Gate decision**: PASS

## Source Analysis

### src-001: 01-status-codes.md
- **Origin**: Test fixture in cogworks repository
- **Entity boundary**: Internal test asset
- **Trust signal**: Controlled test input, version-controlled, no external dependencies
- **Content nature**: HTTP status code guidance (401 vs 403 semantics)
- **Execution surface**: None - declarative guidance only
- **Risk signals**: None detected

### src-002: 02-token-handling.md
- **Origin**: Test fixture in cogworks repository
- **Entity boundary**: Internal test asset
- **Trust signal**: Controlled test input, version-controlled, no external dependencies
- **Content nature**: Token lifecycle and error classification guidance
- **Execution surface**: None - declarative guidance only
- **Risk signals**: None detected

## Cross-Source Analysis

**Contradictions**: None detected. Both sources consistently distinguish authentication failures (401) from authorization failures (403).

**Derivative relationships**: src-002 extends the conceptual framework from src-001 by adding token lifecycle considerations.

**Entity boundary coherence**: Both sources originate from the same test fixture directory and represent a single controlled knowledge domain.

## Trust Decision Rationale

These sources are test fixtures within the cogworks repository, specifically designed as controlled validation inputs. They contain declarative API guidance with no executable code or external dependencies. The content is internally consistent and represents a single coherent knowledge domain about HTTP authentication and authorization semantics.

The sources are suitable for synthesis into skill artifacts without additional trust mitigation.
