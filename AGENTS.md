# AGENTS.md - rules_antlr

## Repository Context
- **Forked revival** of abandoned marcohu/rules_antlr (inactive since 2022)
- **Active modernization** by Alberto Cavalcante for 2025 Bazel ecosystem
- **Target**: Transfer to bazel-contrib organization after modernization
- **Legacy system** transitioning to modern Bazel patterns

## Tech Stack
- **⚠️ WORKSPACE Legacy**: Uses deprecated WORKSPACE system (NOT bzlmod)
- Bazel build system, Java 11+, ANTLR 2/3/4
- Multi-language targets: Java, C++, Go, Python2/3, Swift, C#, ObjC
- Bzlmod support in active development (PR #35)

## Project Structure
```
antlr/                    # Core Bazel rules (.bzl files)
├── antlr2.bzl           # ANTLR 2 rule definition
├── antlr3.bzl           # ANTLR 3 rule definition
├── antlr4.bzl           # ANTLR 4 rule definition
├── impl.bzl             # Common implementation
├── lang.bzl             # Language constants and utilities
├── repositories.bzl     # Dependency management
src/main/java/           # Java tool wrapper
src/test/                # Unit tests
src/it/                  # Integration tests
examples/                # Multi-language demos
docs/                    # Generated docs (DO NOT EDIT)
```

## Commands
- `./build.sh` - Build all + generate docs
- `./ci.sh [args]` - Full CI pipeline with security checks
- `bazelisk build //...` - Build all targets
- `bazelisk test //...` - Run test suite
- `bazelisk test --config ci //...` - CI configuration

## Rule Usage Patterns
```starlark
load("@rules_antlr//antlr:antlr4.bzl", "antlr")

antlr(
    name = "parser",
    srcs = ["Hello.g4"],
    package = "com.example",
    language = "Java",  # Optional: Java, Cpp, CSharp, Go, JavaScript, Python2, Python3, Swift
)
```

## Language Detection
- **Convention-based**: `src/main/antlr4/` → Java namespace from path
- **Package attribute**: Explicit namespace override
- **Language attribute**: Target language override

## Output Patterns
- **Java**: `.srcjar` archive
- **C++**: Headers (`.inc`) + sources (`.cc`) + includes
- **Others**: Directory with generated files

## Core Constraints
- **Import rule**: All import files must be in same directory
- **Provider pattern**: Uses custom `AntlrInfo` provider
- **Version management**: SHA256-verified dependencies

## Dependencies Setup
```starlark
# WORKSPACE.bazel (legacy)
http_archive(
    name = "rules_antlr",
    urls = ["https://github.com/albertocavalcante/rules_antlr/releases/download/vX.Y.Z/rules_antlr-vX.Y.Z.tar.gz",
)

load("@rules_antlr//antlr:repositories.bzl", "rules_antlr_dependencies")
rules_antlr_dependencies("4.8")  # or 2, 3, specific version
```

## Testing Strategy
- **Unit tests**: Java classes in `src/test/`
- **Integration tests**: Full workflow tests in `src/it/`
- **Example validation**: All examples must build and run
- **CI matrix**: Multiple Bazel versions, OS combinations

## Version Support
- **ANTLR 4**: 4.7.1, 4.7.2, 4.8, 4.9.1, 4.9.2
- **ANTLR 3**: 3.5.2
- **ANTLR 2**: 2.7.7
- **Optimized ANTLR**: TunnelVision Labs fork support (versions 4.7.1, 4.7.2, 4.7.3, 4.7.4)

## Code Conventions
- **Starlark**: 4-space indentation, underscore for private functions
- **Java**: Standard Java conventions, package `org.antlr.bazel`
- **BUILD files**: Alphabetical attribute ordering, explicit visibility

## CI/CD & Release Management
- **GitHub Actions**: 3 committed workflows (ci.yml, release-drafter.yml, bisect.yml)
- **Release Drafter**: Manual release workflow with emoji-based labeling
- **Security model**: Authorization-gated CI with pull_request_target
- **Debugging**: Bazel bisect tool for version regression testing
- **Release process**: Manual trigger → SHA256 calculation → draft release

## DO NOT TOUCH
- SHA256 hashes in `repositories.bzl` (security critical)
- Generated docs in `docs/` (updated via build.sh)
- Committed CI workflows (security-reviewed, not local proposals)
- Test fixture grammars in `src/it/resources/`

## Current Development
- **Bzlmod support** actively being implemented (Issue #34, PR #35)
- **Dual compatibility** strategy - maintain WORKSPACE while adding bzlmod
- **Community contributions** welcome for bzlmod implementation

## Modernization Goals
- ✅ Bzlmod support in progress (PR #35 by @peakschris)
- Latest Bazel/ANTLR compatibility
- Bazel-contrib standards compliance
- Maintain backward compatibility during transition

## 2025 Context
- Bzlmod is now default in Bazel 8.0+ (this project uses legacy WORKSPACE)
- WORKSPACE removal planned for Bazel 9
- This ruleset needs bzlmod migration for future compatibility
- Most 2025 Bazel projects expect MODULE.bazel support
