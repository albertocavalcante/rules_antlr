package org.antlr.bazel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import org.junit.Test;

/**
 * Dependency loading tests.
 */
public class RepositoriesTest {

    public static final String WORKSPACE_FILENAME = "WORKSPACE.bazel";

    private static final String RULES_ANTLR_PATH = "../../../rules_antlr";

    private void runTest(String workspaceContents, String target, String expectedError) throws Exception {
        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file(WORKSPACE_FILENAME, workspaceContents);
        Command c = new Command(workspace.root, target).build();
        assertEquals(c.output(), 1, c.exitValue());
        assertTrue(c.output().contains(expectedError));
    }

    @Test
    public void missingVersion() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies()";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: Missing ANTLR version");
    }

    @Test
    public void languageAndMissingVersion() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(\"Java\")";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: Missing ANTLR version");
    }

    @Test
    public void unsupportedVersion() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(\"4.0\")";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: Unsupported ANTLR version provided: \"4.0\".");

        contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_optimized_dependencies\")\n"
            + "rules_antlr_optimized_dependencies(\"4.0\")";

        runTest(contents, "//antlr4/HelloWorld/...", "attribute version: Unsupported ANTLR version provided: \"4.0\".");
    }

    @Test
    public void invalidVersion() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(471)";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: Integer version '471' no longer valid. Use semantic version \"4.7.1\" instead.");

        contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_optimized_dependencies\")\n"
            + "rules_antlr_optimized_dependencies(471)";

        runTest(contents, "//antlr4/HelloWorld/...", "attribute version: Integer version '471' no longer valid. Use semantic version \"4.7.1\" instead.");
    }

    @Test
    public void invalidLanguage() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(4, \"Haskell\")";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: Invalid language provided: \"Haskell\".");
    }

    @Test
    public void severalVersions() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(\"4.7.1\", \"4.7.2\")";

        runTest(contents, "//antlr2/Calc/...", "attribute versionsAndLanguages: You can only load one version from ANTLR 4. You specified both \"4.7.1\" and \"4.7.2\".");
    }

    @Test
    public void missingLanguage() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(\"2.7.7\")";

        runTest(contents, "//antlr2/Cpp/...", "attribute versionsAndLanguages: Missing language for ANTLR 2. You specified \"2.7.7\".");
    }

    @Test
    public void alwaysLoadJavaDependencies() throws Exception {
        String contents = "workspace(name=\"examples\")\n"
            + "local_repository(\n"
            + "    name = \"rules_antlr\",\n"
            + "    path = \"" + RULES_ANTLR_PATH + "\",\n"
            + ")\n"
            + "load(\"@rules_antlr//antlr:repositories.bzl\", \"rules_antlr_dependencies\")\n"
            + "rules_antlr_dependencies(\"2.7.7\", \"Cpp\")";

        TestWorkspace workspace = new TestWorkspace(true);
        workspace.file(WORKSPACE_FILENAME, contents);
        Command c = new Command(workspace.root, "//antlr2/Cpp/...").build();
        assertEquals(c.output(), 0, c.exitValue());
    }
}
