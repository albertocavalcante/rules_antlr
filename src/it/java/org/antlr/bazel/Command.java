package org.antlr.bazel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

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
     */
    public Command build() throws Exception {
        Process p = new ProcessBuilder()
                .command(
                        "bazel", "build", "--jobs", "2", target)
                .directory(directory.toFile())
                .redirectErrorStream(true)
                .start();

        output = new String(p.getInputStream().readAllBytes());

        p.waitFor();

        exitValue = p.exitValue();

        return this;
    }
}
