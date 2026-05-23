load("repositories.bzl", "rules_antlr_dependencies", "rules_antlr_optimized_dependencies", "rules_antlr_tool_repositories")

def _append_if_absent(lst, item):
    """Appends item to lst only if it is not already present."""
    if item not in lst:
        lst.append(item)

def _antlr_repositories_impl(module_ctx):
    # Track which baseline repos will be created by toolchain tags so we do not
    # call _dependencies() twice for the same repo (maybe() is not reliable in
    # module extension context and Bazel raises an error on duplicates).
    already_created = []

    # Collect only the repos that correspond to what the caller requested.
    # Implementation-detail repos (stringtemplate4, javax_json, antlr2 when only
    # v3 is requested, etc.) are deliberately excluded so consumers do not have
    # to list them in use_repo().
    direct_deps = []

    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            langs = toolchain.languages
            non_java = len(langs) > 0

            for v in toolchain.versions:
                sv = str(v)
                if sv in ["2", "2.7.7"]:
                    if "antlr2" not in already_created:
                        already_created.append("antlr2")
                    _append_if_absent(direct_deps, "antlr2")
                    if non_java:
                        _append_if_absent(direct_deps, "antlr2_runtimes")
                elif sv in ["3", "3.5.2"]:
                    if "antlr3_tool" not in already_created:
                        already_created.append("antlr3_tool")
                    _append_if_absent(direct_deps, "antlr3_runtime")
                    _append_if_absent(direct_deps, "antlr3_tool")
                    if non_java:
                        _append_if_absent(direct_deps, "antlr3_runtimes")
                elif sv.startswith("4"):
                    _append_if_absent(direct_deps, "antlr4_runtime")
                    _append_if_absent(direct_deps, "antlr4_tool")
                    _append_if_absent(direct_deps, "antlr3_runtime")
                    if non_java:
                        _append_if_absent(direct_deps, "antlr4_runtimes")

            all_args = toolchain.versions + langs
            rules_antlr_dependencies(
                *all_args,
            )

        for toolchain in mod.tags.optimized_toolchain:
            rules_antlr_optimized_dependencies(toolchain.version)
            _append_if_absent(direct_deps, "antlr4_runtime")
            _append_if_absent(direct_deps, "antlr4_tool")
            _append_if_absent(direct_deps, "antlr3_runtime")

    # Always ensure the minimal repos that rules_antlr's .bzl files reference exist.
    # antlr2 and antlr3_tool are declared in rules_antlr's non-dev use_repo so that
    # Label("@antlr2//jar") / Label("@antlr3_tool//jar") resolve in antlr2.bzl / antlr3.bzl.
    rules_antlr_tool_repositories(existing_repos = already_created)

    return module_ctx.extension_metadata(
        root_module_direct_deps = direct_deps,
        root_module_direct_dev_deps = [],
        reproducible = True)

antlr_extension = module_extension(
    implementation = _antlr_repositories_impl,
    tag_classes = {
        "toolchain": tag_class(attrs = {
            "languages": attr.string_list(doc = "A list of languages to support."),
            "name": attr.string(doc = "The name of the repository used for the toolchains.", default = "antlr_repositories"),
            "versions": attr.string_list(doc = "The antlr versions to support."),
        }),
        "optimized_toolchain": tag_class(attrs = {
            "version": attr.string(doc = "The TunnelVision Labs optimized ANTLR 4 version to use (e.g. '4.7.4')."),
        }),
    },
)
