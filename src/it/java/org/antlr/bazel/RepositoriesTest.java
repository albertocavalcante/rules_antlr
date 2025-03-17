package org.antlr.bazel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import org.junit.Test;


/**
 * Integration tests for ANTLR dependency loading functionality.
 * 
 * These tests verify that the ANTLR rules properly handle dependency declarations,
 * including version and language specifications. Each test validates different
 * edge cases or requirements for the dependency loading mechanism.
 *
 */
public class RepositoriesTest
{
    /**
     * Tests that building fails when no ANTLR version is specified in the dependencies.
     * 
     * The rules_antlr_dependencies() call must include at least one version parameter.
     * This test ensures proper error message is displayed when this requirement is violated.
     */
    @Test
    public void missingVersion() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies()";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: Missing ANTLR version"));
    }

    /**
     * Tests that building fails when a language is specified but no ANTLR version.
     * 
     * This test verifies that providing only a language without a version is invalid,
     * as the system needs to know which ANTLR version to use for the specified language.
     */
    @Test
    public void languageAndMissingVersion() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(\"Java\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: Missing ANTLR version"));
    }

    /**
     * Tests the error handling when an unsupported ANTLR version is specified.
     * 
     * ANTLR rules only support specific versions (2.7.7, 3.5.2, 4.7.1, etc.).
     * This test verifies that proper error messages are shown when unsupported versions are requested.
     */
    @Test
    public void unsupportedVersion() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(\"4.0\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: Unsupported ANTLR version provided: \"4.0\"."));

        contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_optimized_dependencies\")\n"
                + "rules_antlr_optimized_dependencies(\"4.0\")";

        workspace.file("WORKSPACE.bazel", contents);
        c = new Command(workspace.root, "//antlr4/HelloWorld/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute version: Unsupported ANTLR version provided: \"4.0\"."));
    }

    /**
     * Tests that providing versions in an invalid format produces appropriate errors.
     * 
     * The ANTLR rules now require semantic versioning format (e.g., "4.7.1") 
     * instead of numeric format (e.g., 471).
     */
    @Test
    public void invalidVersion() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(471)";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: Integer version '471' no longer valid. Use semantic version \"4.7.1\" instead."));

        contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_optimized_dependencies\")\n"
                + "rules_antlr_optimized_dependencies(471)";

        workspace.file("WORKSPACE.bazel", contents);
        c = new Command(workspace.root, "//antlr4/HelloWorld/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute version: Integer version '471' no longer valid. Use semantic version \"4.7.1\" instead."));
    }

    /**
     * Tests error handling when an invalid language is specified.
     * 
     * ANTLR rules only support specific language targets (Java, Cpp, Python, etc.).
     * This test verifies proper error handling when an unsupported language is requested.
     */
    @Test
    public void invalidLanguage() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(4, \"Haskell\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: Invalid language provided: \"Haskell\"."));
    }

    /**
     * Tests that specifying multiple versions from the same major version stream is an error.
     * 
     * ANTLR rules allow at most one version from each major ANTLR release stream (2.x, 3.x, 4.x).
     * This test verifies that proper errors are shown when multiple versions from the same stream are requested.
     */
    @Test
    public void severalVersions() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(\"4.7.1\", \"4.7.2\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Calc/...").build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains("attribute versionsAndLanguages: You can only load one version from ANTLR 4. You specified both \"4.7.1\" and \"4.7.2\"."));
    }

    /**
     * Tests that build fails when a required language is not specified.
     * 
     * When using language-specific targets, the corresponding language must be
     * included in the dependencies declaration.
     */
    @Test
    public void missingLanguage() throws Exception
    {
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"../../../rules_antlr\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(\"2.7.7\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file("WORKSPACE.bazel", contents);
        Command c = new Command(workspace.root, "//antlr2/Cpp/...").build();
        assertEquals(c.output(), 1, c.exitValue());
    }

    /**
     * Tests that Java dependencies are automatically loaded when other languages are specified.
     * 
     * This is a crucial test that verifies ANTLR's behavior of always loading Java dependencies
     * when any other language is specified, since the ANTLR tool itself is Java-based.
     * 
     * This test:
     * 1. Creates an empty workspace
     * 2. Copies only the necessary antlr2/Cpp directory from examples
     * 3. Creates a WORKSPACE file specifying ANTLR 2.7.7 with Cpp language
     * 4. Verifies the build succeeds, showing Java dependencies were automatically loaded
     */
    @Test
    public void alwaysLoadJavaDependencies() throws Exception
    {
        // Get the absolute path to the rules_antlr directory
        // Using absolute paths is critical for CI environments where relative paths often fail
        String rulesAntlrPath = System.getProperty("user.dir");
        System.out.println("Rules ANTLR path: " + rulesAntlrPath);

        // Create an empty workspace - we'll manually copy only what we need
        TestWorkspace workspace = new TestWorkspace(true);
        System.out.println("Workspace root: " + workspace.root);

        // Find the examples directory which contains the example projects
        Path examplesPath = Projects.path("examples");
        System.out.println("Examples directory: " + examplesPath);

        // Create the antlr2 directory structure in our workspace
        Files.createDirectories(workspace.root.resolve("antlr2"));

        // Copy the entire antlr2/Cpp directory structure
        // This is necessary because we need all the BUILD files and source files
        copyDirectory(examplesPath.resolve("antlr2/Cpp"), workspace.root.resolve("antlr2/Cpp"));

        // Log what files were copied for debugging purposes
        System.out.println("Files copied to workspace:");
        Files.walk(workspace.root.resolve("antlr2"))
                .filter(Files::isRegularFile)
                .forEach(p -> System.out.println("  " + p));

        // Create WORKSPACE.bazel file with:
        // 1. Absolute path to rules_antlr (critical for CI environments)
        // 2. Dependencies specification for ANTLR 2.7.7 with Cpp language
        String contents = "workspace(name=\"examples\")\n"
                + "local_repository(\n"
                + "    name = \"rules_antlr\",\n"
                + "    path = \"" + rulesAntlrPath + "\",\n"
                + ")\n"
                + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
                + "rules_antlr_dependencies(\"2.7.7\", \"Cpp\")";

        workspace.file("WORKSPACE.bazel", contents);
        System.out.println("Created WORKSPACE.bazel file");

        // Run bazel build with a specific JDK version to ensure consistency
        Command c = new Command(workspace.root, "//antlr2/Cpp/...")
                .build("--java_runtime_version=remotejdk_11");

        // Log results for debugging
        System.out.println("Command exit value: " + c.exitValue());

        // Verify build succeeds (exit code 0)
        // This shows that Java dependencies were automatically loaded even though
        // we only specified Cpp as the language
        assertEquals(c.output(), 0, c.exitValue());
    }

    /**
     * Helper method to recursively copy a directory structure.
     * 
     * This method is crucial for the alwaysLoadJavaDependencies test as it ensures
     * all necessary files are copied with the correct structure preserved.
     * 
     * @param source The source directory to copy from
     * @param target The target directory to copy to
     * @throws IOException If an I/O error occurs during copying
     */
    private void copyDirectory(Path source, Path target) throws IOException {
        // Ensure target directory exists
        Files.createDirectories(target);

        // List all entries in the source directory
        try (var entries = Files.list(source)) {
            // Process each entry (file or directory)
            for (Path entry : entries.collect(Collectors.toList())) {
                Path targetEntry = target.resolve(entry.getFileName());

                if (Files.isDirectory(entry)) {
                    // Recursively copy subdirectories
                    copyDirectory(entry, targetEntry);
                } else {
                    // Copy individual files
                    Files.copy(entry, targetEntry);
                    System.out.println("Copied file: " + entry + " to " + targetEntry);
                }
            }
        }
    }
}
