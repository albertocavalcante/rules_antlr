#!/bin/bash
# CI script extracted from GitHub Actions workflow

# Exit immediately if a command exits with a non-zero status
set -e

# Print commands before executing them
set -x

# Store bazelisk arguments
BAZEL_ARGS="$@"

# Verify Bazel installation
bazelisk $BAZEL_ARGS version

# Build examples
cd examples
bazelisk $BAZEL_ARGS build --config ci --toolchain_resolution_debug //antlr2/Cpp/... //antlr2/Calc/... //antlr2/Python/... //antlr3/Cpp/... //antlr3/Java/... //antlr3/Python2/... //antlr3/Python3/... //antlr4/Cpp/... //antlr4/Go/... //antlr4/Java/... //antlr4/Python2/... //antlr4/Python3/...
cd ..

# Build antlr4-opt
cd examples/antlr4-opt
bazelisk $BAZEL_ARGS build --config ci //...
cd ../..

# Run tests
bazelisk $BAZEL_ARGS test --config ci //...

# Shutdown Bazel
bazelisk $BAZEL_ARGS shutdown

echo "CI completed successfully!"
