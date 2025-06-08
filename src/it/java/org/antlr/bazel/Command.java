package org.antlr.bazel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Bazel command for integration testing.
 *
 * @author Marco Hunsicker
 */
class Command {
    private String target;
    private Path directory;
    private int exitValue = -1;
    private String output = "";

    /**
     * Creates a new Command object.
     *
     * @param directory the working directory.
     * @param target    the build target.
     */
    public Command(Path directory, String target) {
        this.target = target;
        this.directory = directory;
    }

    /**
     * Returns the process exit value.
     *
     * @return the exit value.
     */
    public int exitValue() {
        return exitValue;
    }

    /**
     * Returns the build output.
     *
     * @return the build output.
     */
    public String output() {
        return output;
    }

    /**
     * Builds the specified target.
     * 
     * @return this Command instance.
     * @throws Exception if an error occurs.
     */
    public Command build() throws Exception {
        return build(new String[0]);
    }

    /**
     * Gets the bazel command to execute, respecting the BAZEL environment variable.
     * 
     * @return the bazel command path or "bazel" if not set.
     */
    private static String getBazelCommand() {
        String bazelPath = System.getenv("BAZEL");
        return bazelPath != null ? bazelPath : "bazel";
    }

    /**
     * Builds the specified target with additional flags.
     * 
     * @param flags Additional flags to pass to the bazel build command.
     * @return this Command instance.
     * @throws Exception if an error occurs.
     */
    public Command build(String... flags) throws Exception {
        List<String> command = new ArrayList<>();
        command.add(getBazelCommand());
        command.add("build");
        command.add("--jobs");
        command.add("2");
        command.add("--verbose_failures");
        command.add("--noenable_bzlmod");

        // Add any additional flags
        if (flags != null && flags.length > 0) {
            command.addAll(Arrays.asList(flags));
        }

        // Add the target at the end
        command.add(target);

        Process p = new ProcessBuilder()
                .command(command)
                .directory(directory.toFile())
                .redirectErrorStream(true)
                .start();

        output = new String(p.getInputStream().readAllBytes());

        p.waitFor();

        exitValue = p.exitValue();

        return this;
    }
}
