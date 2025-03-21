# -*- mode:python; -*-
#
# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Generate java test rules from given test_files.

Instead of having to create one test rule per test in the BUILD file, this rule
provides a handy way to create a bunch of test rules for the specified test
files.

"""

load("@rules_java//java:defs.bzl", "java_test")

def java_tests(
        name,
        test_files,
        deps,
        exclude_tests = [],
        default_test_size = "small",
        small_tests = [],
        medium_tests = [],
        large_tests = [],
        enormous_tests = [],
        resources = [],
        flaky_tests = [],
        tags = [],
        prefix = "",
        jvm_flags = [],
        args = [],
        visibility = None,
        shard_count = 1):
    """Create Java tests for the given files.

    Args:
        name: the unique name of this target.
        test_files: the tests.
        deps: the list of other libraries to be linked in to the target.
        exclude_tests: the tests to exclude.
        default_test_size: the default test size.
        small_tests: the small tests.
        medium_tests: the medium tests.
        large_tests: the large tests.
        enormous_tests: the enormous tests.
        resources: the list of data files to include in the test jar.
        flaky_tests: the tests to mark as flaky.
        tags: the tags to add.
        prefix: the prefix to prepend before the test names.
        jvm_flags: the list of flags to embed in the wrapper script generated for running the tests.
        args: the arguments to add to <b>--test_arg</b>
        visibility: the visibility of the created java_tests.
        shard_count: the number of parallel shards to use to run the test.
    """
    for test in _get_test_names(test_files):
        if test in exclude_tests:
            continue
        test_size = default_test_size
        if test in small_tests:
            test_size = "small"
        if test in medium_tests:
            test_size = "medium"
        if test in large_tests:
            test_size = "large"
        if test in enormous_tests:
            test_size = "enormous"
        flaky = 0
        if (test in flaky_tests) or ("flaky" in tags):
            flaky = 1
        java_class = _package_from_path(
            native.package_name() + "/" + _strip_right(test, ".java"),
        )
        package = java_class[:java_class.rfind(".")]
        java_test(
            name = prefix + test,
            runtime_deps = deps,
            resources = resources,
            size = test_size,
            jvm_flags = jvm_flags,
            args = args,
            flaky = flaky,
            tags = tags,
            test_class = java_class,
            visibility = visibility,
            shard_count = shard_count,
        )

def _get_test_names(test_files):
    test_names = []
    for test_file in test_files:
        if not test_file.endswith("Test.java"):
            continue
        test_names += [test_file[:-5]]
    return test_names

def _package_from_path(package_path, src_impls = None):
    src_impls = src_impls or ["javatests/", "java/"]
    for src_impl in src_impls:
        if not src_impl.endswith("/"):
            src_impl += "/"
        index = _index_of_end(package_path, src_impl)
        if index >= 0:
            package_path = package_path[index:]
            break
    return package_path.replace("/", ".")

def _strip_right(str, suffix):
    """Returns str without the suffix if it ends with suffix."""
    if str.endswith(suffix):
        return str[0:len(str) - len(suffix)]
    else:
        return str

def _index_of_end(str, part):
    """If part is in str, return the index of the first character after part.

    Returns:
       -1 if part is not in str.
    """
    index = str.find(part)
    if index >= 0:
        return index + len(part)
    return -1

def java_test_methods(
        name,
        test_file,
        test_methods,
        deps,
        size = "small",
        resources = [],
        tags = [],
        jvm_flags = [],
        visibility = None,
        shard_count = 1):
    """Create individual Java test targets for each test method in a test class.

    Args:
        name: base name for the test targets
        test_file: the test file (without .java extension)
        test_methods: list of test method names to create targets for
        deps: the list of dependencies
        size: test size
        resources: the list of data files to include in the test jar
        tags: the tags to add
        jvm_flags: the list of flags for the JVM
        visibility: the visibility of the created java_tests
        shard_count: the number of parallel shards to use
    """
    java_class = _package_from_path(
        native.package_name() + "/" + test_file,
    )

    for method in test_methods:
        java_test(
            name = name + "_" + method,
            runtime_deps = deps,
            resources = resources,
            size = size,
            jvm_flags = jvm_flags,
            tags = tags,
            test_class = java_class,
            args = ["--test_filter=" + java_class + "#" + method],
            visibility = visibility,
            shard_count = shard_count,
        )
