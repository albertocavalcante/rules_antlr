load("repositories.bzl", "rules_antlr_dependencies")

def _antlr_repositories_impl(module_ctx):
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            all_args = toolchain.versions + toolchain.languages
            rules_antlr_dependencies(
                *all_args,
            )
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
    },
)
