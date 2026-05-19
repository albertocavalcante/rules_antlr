load("repositories.bzl", "rules_antlr_dependencies", "rules_antlr_optimized_dependencies", "rules_antlr_tool_repositories")

def _antlr_repositories_impl(module_ctx):
    # Track which baseline repos will be created by toolchain tags so we do not
    # call _dependencies() twice for the same repo (maybe() is not reliable in
    # module extension context and Bazel raises an error on duplicates).
    already_created = []
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            for v in toolchain.versions:
                sv = str(v)
                if sv in ["2", "2.7.7"] and "antlr2" not in already_created:
                    already_created.append("antlr2")
                if sv in ["3", "3.5.2"] and "antlr3_tool" not in already_created:
                    already_created.append("antlr3_tool")
            all_args = toolchain.versions + toolchain.languages
            rules_antlr_dependencies(
                *all_args,
            )
        for toolchain in mod.tags.optimized_toolchain:
            rules_antlr_optimized_dependencies(toolchain.version)
    # Always ensure the minimal repos that rules_antlr's .bzl files reference exist.
    # antlr2 and antlr3_tool are declared in rules_antlr's non-dev use_repo so that
    # Label("@antlr2//jar") / Label("@antlr3_tool//jar") resolve in antlr2.bzl / antlr3.bzl.
    rules_antlr_tool_repositories(existing_repos = already_created)
    return module_ctx.extension_metadata(
        root_module_direct_deps="all", 
        root_module_direct_dev_deps=[], 
        reproducible=False)

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
