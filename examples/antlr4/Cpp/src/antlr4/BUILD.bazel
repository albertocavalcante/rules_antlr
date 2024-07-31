load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_antlr//antlr:antlr4.bzl", "antlr")

antlr(
    name = "generated",
    srcs = glob(["*.g4"]),
    language = "Cpp",
    package = "antlrcpptest",
)

cc_library(
    name = "lib",
    srcs = [":generated"],
    visibility = ["//visibility:public"],
    deps = [
        ":generated",
        "@antlr4_runtimes//:cpp",
    ],
)
