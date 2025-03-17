package org.antlr.bazel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;
import java.io.UncheckedIOException;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;


/**
 * TestWorkspace creates an isolated test environment for running Bazel operations.
 * This class is crucial for tests that need to verify Bazel behavior with specific
 * workspace configurations without interfering with the main repository.
 *
 * It allows two modes of operation:
 * 1. A complete copy of the examples directory (empty=false)
 * 2. An empty workspace where files must be manually added (empty=true)
 *
 * The class handles the complexity of path resolution between the test workspace
 * and the actual repository, which is particularly important in CI environments
 * where directory structures can differ from local development.
 */
class TestWorkspace
{
    /** The workspace root directory path. Created as a temporary directory. */
    public final Path root;

    /**
     * Creates a new TestWorkspace with the examples directory copied into it.
     *
     * @throws IOException if an I/O error occurs during workspace creation.
     */
    public TestWorkspace() throws IOException
    {
        this(false);
    }

    /**
     * Creates a new TestWorkspace object.
     * 
     * @param empty If true, creates an empty workspace without copying example files.
     *              If false, copies all files from the examples directory into the workspace.
     *              
     * @throws IOException if an I/O error occurs during workspace creation.
     */
    public TestWorkspace(boolean empty) throws IOException
    {
        // Locate the examples directory, which may differ between local and CI environments
        Path examples = Projects.path("examples");
        assertTrue(Files.exists(examples));
        
        // Create a fresh, isolated temporary directory to serve as our workspace root
        // This provides a clean environment for each test run
        root = Files.createTempDirectory("antlr_test_workspace");
        
        if (!empty) {
            // If a full workspace is requested, copy all files from examples to workspace
            // We only copy files (not directories) and recreate the directory structure
            // This avoids symlink issues that can occur in some environments
            Files.walk(examples)
                .filter(path -> !Files.isDirectory(path))
                .forEach(source -> {
                    try {
                        // Calculate the target path relative to the examples directory
                        Path target = root.resolve(examples.relativize(source));
                        // Create parent directories as needed
                        Files.createDirectories(target.getParent());
                        // Copy the file to our workspace
                        Files.copy(source, target);
                    } catch (IOException e) {
                        throw new UncheckedIOException(e);
                    }
                });
        }

        // Check if there's a WORKSPACE.bazel file in the examples directory
        Path workspace = examples.resolve("WORKSPACE.bazel");

        // If we're creating a full workspace and there's no WORKSPACE.bazel file,
        // we generate one with the appropriate dependencies
        if (!empty && Files.notExists(workspace))
        {
            // Generate a WORKSPACE file with the correct repository references
            // Note: We handle the relative path specially because the structure
            // can differ between local development and CI environments
            String contents = "workspace(name=\"examples\")\n"
                    + "load(\"@bazel_tools//tools/build_defs/repo:http.bzl\", \"http_archive\")\n"
                    + "local_repository(\n"
                    + "    name = \"rules_antlr\",\n"
                    + "    path = \"../../../rules_antlr\",\n" + ")\n"
                    + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                    + "rules_antlr_dependencies(2, 3, 4, \"Cpp\", \"Go\", \"Python\", \"Python2\")\n"
                    + "http_archive(\n"
                    + "    name = \"io_bazel_rules_go\",\n"
                    + "    sha256 = \"b78f77458e77162f45b4564d6b20b6f92f56431ed59eaaab09e7819d1d850313\",\n"
                    + "    urls = [\n"
                    + "        \"https://mirror.bazel.build/github.com/bazel-contrib/rules_go/releases/download/v0.53.0/rules_go-v0.53.0.zip\",\n"
                    + "        \"https://github.com/bazel-contrib/rules_go/releases/download/v0.53.0/rules_go-v0.53.0.zip\",\n"
                    + "    ],\n"
                    + ")\n"
                    + "load(\"@io_bazel_rules_go//go:deps.bzl\", \"go_register_toolchains\", \"go_rules_dependencies\")\n"
                    + "go_rules_dependencies()\n"
                    + "go_register_toolchains(version = \"1.24.1\")\n"
                    + "http_archive(\n"
                    + "    name = \"rules_python\",\n"
                    + "    sha256 = \"2ef40fdcd797e07f0b6abda446d1d84e2d9570d234fddf8fcd2aa262da852d1c\",\n"
                    + "    strip_prefix = \"rules_python-1.2.0\",\n"
                    + "    url = \"https://github.com/bazelbuild/rules_python/releases/download/1.2.0/rules_python-1.2.0.tar.gz\",\n"
                    + ")\n"
                    + "load(\"@rules_python//python:repositories.bzl\", \"py_repositories\")\n"
                    + "py_repositories()\n";

            Files.write(workspace, contents.getBytes(StandardCharsets.UTF_8));
        }
    }

    /**
     * Creates or overwrites a file in the workspace with the specified contents.
     * This method can be used to create configuration files or test inputs.
     * 
     * The method also replaces relative repository paths with absolute paths,
     * which is crucial for correct test execution in different environments.
     *
     * @param path The path to the file, relative to the workspace root
     * @param contents The contents to write to the file
     * @return The full path to the created file
     * @throws IOException if an I/O error occurs
     */
    public Path file(String path, String contents) throws IOException
    {
        // Replace relative repository paths with absolute paths
        // This is critical for ensuring tests work across different environments
        String processedContents = contents.replace(
            "path = \"../../../rules_antlr\"",
            "path = \"" + rulesAntlrPath() + "\""
        );
        
        Path file = root.resolve(path);
        Files.write(file, processedContents.getBytes(StandardCharsets.UTF_8));
        return file;
    }

    /**
     * Retrieves a Bazel information path by executing a bazel info command.
     * This is used to get various Bazel-specific paths like bazel-bin.
     *
     * @param key The info key to query (e.g., "bazel-bin")
     * @return The resulting path
     * @throws Exception if the Bazel command fails
     */
    public Path path(String key) throws Exception
    {
        // Execute bazel info to get information about paths
        Process p = new ProcessBuilder().command("bazel", "info", key)
                .redirectErrorStream(true)
                .directory(root.toFile())
                .start();

        try (Stream<String> lines = new BufferedReader(
                new InputStreamReader(p.getInputStream())).lines())
                {
                    // Get the last line of output
                    String line = lines.reduce((first, second) -> second).orElse(null);
                    Path path = Paths.get(line);
                    assertTrue(Files.exists(path));
                    return path;
                }
        finally
                {
                    p.waitFor();
                    assertEquals(0, p.exitValue());
                }
    }

    /**
     * Returns the absolute path to the rules_antlr repository.
     * This is used to provide absolute paths in WORKSPACE files,
     * which is more reliable than relative paths in CI environments.
     *
     * @return The absolute path to the rules_antlr repository
     */
    public String rulesAntlrPath() {
        return System.getProperty("user.dir");
    }
}
