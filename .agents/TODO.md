# rules_antlr Critical Bug Fixes - Multi-Agent TODO

## Executive Summary

This document outlines **19 critical vulnerabilities** discovered in the rules_antlr codebase requiring immediate attention:

- **15 Critical NPE Vulnerabilities** - Could cause JVM crashes during build
- **2 High-Priority Bazel Logic Errors** - Break compatibility with newer Bazel versions
- **2 Medium-Priority Resource Leaks** - Gradual system degradation

**Note**: TODO-005 was cancelled after validation - the claimed Starlark deprecation was incorrect.

Each TODO item is structured for autonomous sub-agent execution with detailed prompts, file locations, fix instructions, and verification steps.

## 🚀 Quick Start: Parallel Multi-Agent Workflow

### Setup Worktrees (One-time)
```bash
./setup-worktrees.sh              # Creates all git worktrees
```

### Launch Parallel Claude Sessions
```bash
./run-parallel-claude.sh critical # Start 4 critical NPE fix sessions (RECOMMENDED)
./run-parallel-claude.sh bazel    # Start 2 Bazel compatibility sessions
./run-parallel-claude.sh resource # Start 2 resource management sessions
./run-parallel-claude.sh all      # Start ALL 10 sessions (high resource usage)
```

### Attach to Individual Sessions
```bash
tmux attach -t rules-antlr-npe-env      # TODO-001
tmux attach -t rules-antlr-npe-builder  # TODO-002
tmux attach -t rules-antlr-npe-language # TODO-003
tmux attach -t rules-antlr-npe-utility  # TODO-004
```

---

## Sub-Agent TODO Items

### TODO-001: Environment Variable NPE Fixes (AntlrRules.java main method)
**Priority**: CRITICAL 🔴
**Agent Type**: NPE-Specialist
**Branch**: `fix/npe-environment-variables`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/npe-env fix/npe-environment-variables
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh critical
# Manual: cd ../rules_antlr-worktrees/npe-env && claude
# Attach: tmux attach -t rules-antlr-npe-env
```

**Problem**: Multiple environment variables accessed without null checks in `main()` method, causing NPE when variables not set.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/AntlrRules.java:88-99`

**Agent Prompt**:
```
Fix critical NPE vulnerabilities in AntlrRules.java main method. The following lines access environment variables and immediately call methods without null checks:

Line 90: env.get("TOOL_CLASSPATH").split(",")
Line 93: env.get("GRAMMARS").split(",")

These will throw NPE if environment variables are not set. Add defensive null checks and provide meaningful error messages.

Implementation steps:
1. Add null checks for each env.get() call
2. Throw IllegalStateException with descriptive message if required env vars missing
3. Consider providing default values where appropriate
4. Maintain existing builder pattern flow

Verification: Create test that calls main() with missing environment variables and verify proper error handling instead of NPE.
```

**Fix Strategy**:
```java
// Replace:
.classpath(env.get("TOOL_CLASSPATH").split(","))

// With:
.classpath(getRequiredEnvVar(env, "TOOL_CLASSPATH").split(","))

private static String getRequiredEnvVar(Map<String, String> env, String name) {
    String value = env.get(name);
    if (value == null) {
        throw new IllegalStateException("Required environment variable not set: " + name);
    }
    return value;
}
```

---

### TODO-002: Builder Method Parameter NPE Fixes
**Priority**: CRITICAL 🔴
**Agent Type**: NPE-Specialist
**Branch**: `fix/npe-builder-parameters`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/npe-builder fix/npe-builder-parameters
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh critical
# Manual: cd ../rules_antlr-worktrees/npe-builder && claude
# Attach: tmux attach -t rules-antlr-npe-builder
```

**Problem**: Builder methods call methods on parameters without null checks, causing NPE when null parameters passed.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/AntlrRules.java:129, 393, 401, 409, 426`

**Agent Prompt**:
```
Fix NPE vulnerabilities in AntlrRules builder methods. These methods call .isEmpty() or .trim() on parameters without null checks:

- encoding(String encoding) - Line 129: encoding.isEmpty()
- language(String language) - Line 393: language.isEmpty()
- layout(String layout) - Line 401: layout.isEmpty()
- namespace(String namespace) - Line 409: namespace.isEmpty()
- srcjar(String srcjar) - Line 426: srcjar.trim().isEmpty()

Add null guards at the beginning of each method. For null inputs, either return early with 'this' (no-op) or use appropriate default values.

Verification: Write unit tests passing null to each builder method and verify no NPE thrown.
```

**Fix Strategy**:
```java
AntlrRules encoding(String encoding) {
    if (encoding == null) return this; // or use default charset
    this.encoding = encoding.isEmpty() ? Charset.defaultCharset() : Charset.forName(encoding);
    return this;
}
```

---

### TODO-003: Language Path Conversion NPE Fixes
**Priority**: CRITICAL 🔴
**Agent Type**: NPE-Specialist
**Branch**: `fix/npe-language-path-conversion`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/npe-language fix/npe-language-path-conversion
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh critical
# Manual: cd ../rules_antlr-worktrees/npe-language && claude
# Attach: tmux attach -t rules-antlr-npe-language
```

**Problem**: Language enum methods call `path.toString()` without null checks across multiple language implementations.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/Language.java:28, 59, 92, 127, 173, 213, 246, 277, 311, 356`

**Agent Prompt**:
```
Fix NPE vulnerabilities in Language enum toId() methods. Multiple language implementations call path.toString() without null checks:

Affected methods in Language.java:
- C.toId() - Line 28
- CPP.toId() - Line 59
- CSHARP.toId() - Line 92
- GO.toId() - Line 127
- JAVA.toId() - Line 173
- JAVASCRIPT.toId() - Line 213
- OBJC.toId() - Line 246
- PYTHON.toId() - Line 277
- RUBY.toId() - Line 311
- SWIFT.toId() - Line 356

Add null check at beginning of each toId() method and throw IllegalArgumentException with descriptive message.

Verification: Test each language's toId() method with null Path parameter and verify proper exception thrown.
```

**Fix Strategy**:
```java
@Override
public String toId(Path path) {
    if (path == null) {
        throw new IllegalArgumentException("path cannot be null");
    }
    return path.toString().replaceAll("[/\\\\]", ".");
}
```

---

### TODO-004: Utility Method NPE Fixes
**Priority**: CRITICAL 🔴
**Agent Type**: NPE-Specialist
**Branch**: `fix/npe-utility-methods`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/npe-utility fix/npe-utility-methods
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh critical
# Manual: cd ../rules_antlr-worktrees/npe-utility && claude
# Attach: tmux attach -t rules-antlr-npe-utility
```

**Problem**: Switch statements in utility methods don't handle null inputs, causing NPE.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/Language.java:469`
- `src/main/java/org/antlr/bazel/Version.java:22`
- `src/main/java/org/antlr/bazel/Strings.java:26`

**Agent Prompt**:
```
Fix NPE vulnerabilities in utility methods that use switch statements without null checks:

1. Language.of(String name) - Line 469: Switch on name without null check
2. Version.of(String version) - Line 22: Switch on version without null check
3. Strings.stripFileExtension(String path) - Line 26: path.lastIndexOf() without null check

Add null checks before switch statements and string method calls. Throw IllegalArgumentException with descriptive messages.

Verification: Test each method with null parameter and verify proper exception handling.
```

**Fix Strategy**:
```java
public static Language of(String name) {
    if (name == null) {
        throw new IllegalArgumentException("language name cannot be null");
    }
    switch (name) {
        // existing cases...
    }
}
```

---

### TODO-005: ~~Bazel Starlark Dictionary Access Fix~~ [CANCELLED - INCORRECT]
**Priority**: ~~HIGH~~ CANCELLED ❌
**Agent Type**: ~~Bazel-Specialist~~
**Branch**: ~~`fix/bazel-dict-access`~~
**Dependencies**: None

**❌ CANCELLED: This TODO was based on incorrect information**

**Analysis**: Research shows that `dict.keys()[0]` is **NOT deprecated** in any Bazel version:
- ✅ Current Bazel 7.5.0 documentation confirms `dict.keys()` returns a **list** that supports indexing
- ❌ No evidence found of deprecation in Bazel 6.0+ in official docs or release notes
- ⚠️ Starlark issue #203 discusses potential future changes but they are **not implemented**

**Current Status**: The existing code `lib.keys()[0]` is **correct and valid** Bazel/Starlark syntax.

**Files to Modify**:
- ~~`antlr/impl.bzl:134`~~ - NO CHANGES NEEDED

**Original Incorrect Claim**:
~~"Dictionary key access uses deprecated syntax that breaks in Bazel 6.0+"~~ - **FALSE**

**Resolution**:
- No code changes required
- The proposed fix `list(lib.keys())[0]` would add unnecessary overhead
- Current implementation follows documented Bazel/Starlark patterns

---

### TODO-006: Bazel String Method Fix
**Priority**: HIGH 🟠
**Agent Type**: Bazel-Specialist
**Branch**: `fix/bazel-string-methods`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/bazel-string fix/bazel-string-methods
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh bazel
# Manual: cd ../rules_antlr-worktrees/bazel-string && claude
# Attach: tmux attach -t rules-antlr-bazel-string
```

**Problem**: Non-existent `.elems()` method called on strings in error messages.

**Files to Modify**:
- `antlr/repositories.bzl:198`
- `antlr/repositories.bzl:274`

**Agent Prompt**:
```
Fix Bazel Starlark errors in repositories.bzl. Two locations call non-existent .elems() method on strings:

Line 198: ".".join(str(version_or_language).elems())
Line 274: ".".join(str(version).elems())

The .elems() method doesn't exist on strings in Starlark. These should just use the string directly.

Fix by removing .elems() calls and wrapping in list:
".".join([str(version_or_language)])
".".join([str(version)])

Verification:
1. Test dependency loading with invalid versions to trigger error paths
2. Verify error messages are properly formatted
3. Ensure no Starlark runtime errors occur
```

---

### TODO-007: Resource Management - Process Stream Leaks
**Priority**: MEDIUM 🟡
**Agent Type**: Resource-Specialist
**Branch**: `fix/process-stream-leaks`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/resource-process fix/process-stream-leaks
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh resource
# Manual: cd ../rules_antlr-worktrees/resource-process && claude
# Attach: tmux attach -t rules-antlr-resource-process
```

**Problem**: Process InputStream not properly closed, causing file handle leaks during testing.

**Files to Modify**:
- `src/it/java/org/antlr/bazel/Command.java:104`

**Agent Prompt**:
```
Fix resource leak in Command.java build() method. Line 104 reads process InputStream without proper resource management:

output = new String(p.getInputStream().readAllBytes());

This can cause file handle leaks during integration testing. Use try-with-resources to ensure proper cleanup.

Fix by wrapping in try-with-resources:
try (InputStream is = p.getInputStream()) {
    output = new String(is.readAllBytes());
}

Verification:
1. Run integration tests and monitor file handle usage
2. Verify no resource leaks using tools like lsof
3. Test with multiple concurrent Command executions
```

---

### TODO-008: Resource Management - File Stream Leaks
**Priority**: MEDIUM 🟡
**Agent Type**: Resource-Specialist
**Branch**: `fix/file-stream-leaks`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/resource-file fix/file-stream-leaks
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh resource
# Manual: cd ../rules_antlr-worktrees/resource-file && claude
# Attach: tmux attach -t rules-antlr-resource-file
```

**Problem**: Files.walk() Stream not closed, causing file handle leaks in test setup.

**Files to Modify**:
- `src/it/java/org/antlr/bazel/TestWorkspace.java:67`

**Agent Prompt**:
```
Fix resource leak in TestWorkspace constructor. Line 67 uses Files.walk() without proper resource management:

Files.walk(examples)
    .filter(path -> !Files.isDirectory(path))
    .forEach(source -> { ... });

Files.walk() returns a Stream that must be closed to prevent file handle leaks. Use try-with-resources.

Fix by wrapping in try-with-resources:
try (Stream<Path> walk = Files.walk(examples)) {
    walk.filter(path -> !Files.isDirectory(path))
        .forEach(source -> { ... });
}

Verification:
1. Create multiple TestWorkspace instances and monitor file handles
2. Verify proper cleanup using resource monitoring tools
3. Test with large directory structures to amplify any leaks
```

---

### TODO-009: Array Bounds Safety Improvements
**Priority**: MEDIUM 🟡
**Agent Type**: Safety-Specialist
**Branch**: `fix/array-bounds-safety`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/safety-bounds fix/array-bounds-safety
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh quality
# Manual: cd ../rules_antlr-worktrees/safety-bounds && claude
# Attach: tmux attach -t rules-antlr-quality-bounds
```

**Problem**: Array access without bounds checking could cause IndexOutOfBoundsException.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/AntlrRules.java:553`

**Agent Prompt**:
```
Fix potential array bounds violation in expandSrcJarImports() method. Line 553 accesses args[i + 1] without checking if i+1 is within array bounds:

if (args[i].equals("-lib") && args[i + 1].endsWith(".srcjar"))

If "-lib" is the last argument, this throws ArrayIndexOutOfBoundsException.

Add bounds check:
if (args[i].equals("-lib") && i + 1 < args.length && args[i + 1].endsWith(".srcjar"))

Verification:
1. Test with args array ending in "-lib" to verify no exception
2. Test normal cases to ensure functionality preserved
3. Add unit test covering this edge case
```

---

### TODO-010: Error Message Quality Improvements
**Priority**: LOW 🟢
**Agent Type**: Quality-Specialist
**Branch**: `fix/error-message-quality`
**Dependencies**: None

**🔧 Worktree Setup**:
```bash
# Automatic (via script): ./setup-worktrees.sh
# Manual: git worktree add ../rules_antlr-worktrees/quality-messages fix/error-message-quality
```

**🤖 Claude Session**:
```bash
# Launch: ./run-parallel-claude.sh quality
# Manual: cd ../rules_antlr-worktrees/quality-messages && claude
# Attach: tmux attach -t rules-antlr-quality-messages
```

**Problem**: Missing spaces in error messages reduce readability.

**Files to Modify**:
- `src/main/java/org/antlr/bazel/Version.java:43`
- Similar patterns in other files

**Agent Prompt**:
```
Improve error message formatting by adding missing spaces. Line 43 in Version.java:

throw new IllegalArgumentException("Unknown version" + version);

Should be:
throw new IllegalArgumentException("Unknown version: " + version);

Search for similar patterns throughout codebase and fix consistently.

Verification:
1. Trigger error conditions and verify messages are properly formatted
2. Ensure consistent formatting across all error messages
3. Test error message readability in build logs
```

---

## Multi-Agent Orchestration Strategy

### ⚡ Active Workflow (Parallel with Worktrees)
```bash
# Phase 1: Critical NPE Fixes (4 parallel Claude sessions)
./run-parallel-claude.sh critical
# ├── TODO-001: Environment Variable NPE Fixes
# ├── TODO-002: Builder Method Parameter NPE Fixes
# ├── TODO-003: Language Path Conversion NPE Fixes
# └── TODO-004: Utility Method NPE Fixes

# Phase 2: High Priority Bazel Fixes (1 parallel Claude session)
./run-parallel-claude.sh bazel
# ├── TODO-005: [CANCELLED] Bazel Starlark Dictionary Access Fix
# └── TODO-006: Bazel String Method Fix

# Phase 3: Resource Management (2 parallel Claude sessions)
./run-parallel-claude.sh resource
# ├── TODO-007: Process Stream Resource Leak Fixes
# └── TODO-008: File Stream Resource Leak Fixes

# Phase 4: Quality Improvements (2 parallel Claude sessions)
./run-parallel-claude.sh quality
# ├── TODO-009: Array Bounds Safety Improvements
# └── TODO-010: Error Message Quality Improvements
```

### 🚀 Quick Start Commands
```bash
# Setup (one-time)
./setup-worktrees.sh

# Start critical fixes (RECOMMENDED first step)
./run-parallel-claude.sh critical

# Check session status
./run-parallel-claude.sh status

# Connect to specific sessions
tmux attach -t rules-antlr-npe-env      # TODO-001
tmux attach -t rules-antlr-npe-builder  # TODO-002
tmux attach -t rules-antlr-npe-language # TODO-003
tmux attach -t rules-antlr-npe-utility  # TODO-004
```

### Legacy Workflow (Sequential)
```bash
# Create worktrees for parallel development
git worktree add ../npe-fixes fix/npe-environment-variables
git worktree add ../bazel-fixes fix/bazel-dict-access
git worktree add ../resource-fixes fix/process-stream-leaks

# Assign agents to worktrees
NPE-Agent -> ../npe-fixes (TODO-001 through TODO-004)
Bazel-Agent -> ../bazel-fixes (TODO-005, TODO-006)
Resource-Agent -> ../resource-fixes (TODO-007, TODO-008)

# Each agent creates PR when complete
# Validation-Agent tests integration after merges
```

### Agent Specializations
- **NPE-Specialist**: Focuses on null pointer vulnerabilities, defensive programming
- **Bazel-Specialist**: Expert in Starlark syntax, Bazel version compatibility
- **Resource-Specialist**: Resource management, try-with-resources patterns
- **Safety-Specialist**: Bounds checking, edge case handling
- **Quality-Specialist**: Code style, error messages, documentation

### Verification Strategy
Each agent must:
1. Implement the fix following provided instructions
2. Add unit tests covering the vulnerability
3. Run existing test suite to ensure no regressions
4. Document the fix in commit message with vulnerability details

### Integration Testing
After all critical fixes (TODO-001 through TODO-008):
1. Run full integration test suite
2. Test with multiple Bazel versions (5.x, 6.x, 7.x)
3. Performance testing to ensure no degradation
4. Security review of all changes

---

## Notes for Future Development

This TODO structure is designed to enable:
- **Autonomous execution** by specialized AI agents
- **Parallel development** using git worktrees
- **Quality assurance** through detailed verification steps
- **Scalability** for larger codebases with hundreds of issues

Each TODO item serves as a complete specification that an agent can execute independently, making this approach suitable for distributed AI-powered code maintenance systems.