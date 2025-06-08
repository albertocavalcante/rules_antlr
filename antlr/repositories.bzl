"""Loads ANTLR dependencies."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_jar")
load(":lang.bzl", "C", "CPP", "GO", "JAVA", "OBJC", "PYTHON", "PYTHON2", "PYTHON3", supported_languages = "supported")

v4 = [4, "4.7.1", "4.7.2", "4.8", "4.9", "4.9.1", "4.9.2", "4.9.3", "4.10", "4.10.1", "4.11.0", "4.12.0"]
v4_opt = [4, "4.7.1", "4.7.2", "4.7.3", "4.7.4"]
v3 = [3, "3.5.2"]
v2 = [2, "2.7.7"]

PACKAGES = {
    "antlr": {
        "4.12.0": {
            "url": "https://github.com/antlr/antlr4/archive/4.12.0.tar.gz",
            "prefix": "antlr4-4.12.0",
            "sha256": "8b6050a2111a6bb6405cc5e9e7bca80c136548ac930e4b2c27566d1eb32f8aed",
        },
        "4.11.1": {
            "url": "https://github.com/antlr/antlr4/archive/4.11.1.tar.gz",
            "prefix": "antlr4-4.11.1",
            "sha256": "81f87f03bb83b48da62e4fc8bfdaf447efb9fb3b7f19eb5cbc37f64e171218cf",
        },
        "4.11.0": {
            "url": "https://github.com/antlr/antlr4/archive/4.11.0.tar.gz",
            "prefix": "antlr4-4.11.0",
            "sha256": "317f4e745badd8b5272191c3a4fd34a183a242aef269c68a9b23a382590dd142",
        },
        "4.10.1": {
            "url": "https://github.com/antlr/antlr4/archive/4.10.1.tar.gz",
            "prefix": "antlr4-4.10.1",
            "sha256": "a320568b738e42735946bebc5d9d333170e14a251c5734e8b852ad1502efa8a2",
        },
        "4.10": {
            "url": "https://github.com/antlr/antlr4/archive/4.10.tar.gz",
            "prefix": "antlr4-4.10",
            "sha256": "39b2604fc75fa77323bd7046f2fb750c818cf11fcce2cd6cca06b6697f60ffbb",
        },
        "4.9.3": {
            "url": "https://github.com/antlr/antlr4/archive/4.9.3.tar.gz",
            "prefix": "antlr4-4.9.3",
            "sha256": "efe4057d75ab48145d4683100fec7f77d7f87fa258707330cadd1f8e6f7eecae",
        },
        "4.9.2": {
            "url": "https://github.com/antlr/antlr4/archive/4.9.2.tar.gz",
            "prefix": "antlr4-4.9.2",
            "sha256": "db170179917ce6fec7bc4ecf72edba36b97c9881e09e03af6ac0c901eba52a8f",
        },
        "4.9.1": {
            "url": "https://github.com/antlr/antlr4/archive/4.9.1.tar.gz",
            "prefix": "antlr4-4.9.1",
            "sha256": "db170179917ce6fec7bc4ecf72edba36b97c9881e09e03af6ac0c901eba52a8f",
        },
        "4.9": {
            "url": "https://github.com/antlr/antlr4/archive/4.9.tar.gz",
            "prefix": "antlr4-4.9",
            "sha256": "8ea492d2670bf7cf30b22bbc0391bc0b976652a8a4f8c08057d8bdb9f3817988",
        },
        "4.8": {
            "url": "https://github.com/antlr/antlr4/archive/4.8.tar.gz",
            "prefix": "antlr4-4.8",
            "sha256": "992d52444b81ed75e52ea62f9f38ecb7652d5ce2a2130af143912b3042a6d77e",
        },
        "4.7.2": {
            "url": "https://github.com/antlr/antlr4/archive/4.7.2.tar.gz",
            "prefix": "antlr4-4.7.2",
            "sha256": "46f5e1af5f4bd28ade55cb632f9a069656b31fc8c2408f9aa045f9b5f5caad64",
        },
        "4.7.1": {
            "url": "https://github.com/antlr/antlr4/archive/4.7.1.tar.gz",
            "prefix": "antlr4-4.7.1",
            "sha256": "4d0714f441333a63e50031c9e8e4890c78f3d21e053d46416949803e122a6574",
        },
        "3.5.2": {
            "url": "https://github.com/marcohu/antlr3/archive/master.tar.gz",
            "prefix": "antlr3-master",
            "sha256": "53cd6c8e41995efa0b7d01c53047ad8a0e2c74e56fe03f6e938d2f0493ee7ace",
        },
        "2.7.7": {
            "url": "https://www.antlr2.org/download/antlr-2.7.7.tar.gz",
            "prefix": "antlr-2.7.7",
            "sha256": "853aeb021aef7586bda29e74a6b03006bcb565a755c86b66032d8ec31b67dbb9",
            "patches": ["@rules_antlr//third_party:antlr2_strings.patch"],
        },
    },
    "antlr4_runtime": {
        "4.12.0": {
            "path": "org/antlr/antlr4-runtime/4.12.0/antlr4-runtime-4.12.0.jar",
            "sha256": "db353b34927d6e10cd790905cea3c8e17283db464daf572e3eadbb9ee569da34",
        },
        "4.11.1": {
            "path": "org/antlr/antlr4-runtime/4.11.1/antlr4-runtime-4.11.1.jar",
            "sha256": "e06c6553c1ccc14d36052ec4b0fc6f13b808cf957b5b1dc3f61bf401996ada59",
        },
        "4.11.0": {
            "path": "org/antlr/antlr4-runtime/4.11.0/antlr4-runtime-4.11.0.jar",
            "sha256": "ac29f09f9ad3b5fa8427659a291729888d52af256f659903ab5c5955e0099e77",
        },
        "4.10.1": {
            "path": "org/antlr/antlr4-runtime/4.10.1/antlr4-runtime-4.10.1.jar",
            "sha256": "da66be0c98acfb29bc708300d05f1a3269c40f9984a4cb9251cf2ba1898d1334",
        },
        "4.10": {
            "path": "org/antlr/antlr4-runtime/4.10/antlr4-runtime-4.10.jar",
            "sha256": "4663a38f88e1935ea612336cbf34f702f10bd0af8e62715a9e959629f141654e",
        },
        "4.9.3": {
            "path": "org/antlr/antlr4-runtime/4.9.3/antlr4-runtime-4.9.3.jar",
            "sha256": "131a6594969bc4f321d652ea2a33bc0e378ca312685ef87791b2c60b29d01ea5",
        },
        "4.9.2": {
            "path": "org/antlr/antlr4-runtime/4.9.2/antlr4-runtime-4.9.2.jar",
            "sha256": "",
        },
        "4.9.1": {
            "path": "org/antlr/antlr4-runtime/4.9.1/antlr4-runtime-4.9.1.jar",
            "sha256": "a80502c3140ae7acfbb1f57847c8eb1c101461a969215ec38c3f1ebdff61ac29",
        },
        "4.9": {
            "path": "org/antlr/antlr4-runtime/4.9/antlr4-runtime-4.9.jar",
            "sha256": "c961cf29061bc383aafbbf0c78bdd3c2514a87d65e1c830b1c6d3634dab99043",
        },
        "4.9.2": {
            "path": "org/antlr/antlr4-runtime/4.9.2/antlr4-runtime-4.9.2.jar",
            "sha256": "120053628dd598d43cb7ac6b9ecc72529dfa5a5fd3292d37cf638a81cc0075f6",
        },
        "4.9.1": {
            "path": "org/antlr/antlr4-runtime/4.9.1/antlr4-runtime-4.9.1.jar",
            "sha256": "a80502c3140ae7acfbb1f57847c8eb1c101461a969215ec38c3f1ebdff61ac29",
        },
        "4.8": {
            "path": "org/antlr/antlr4-runtime/4.8/antlr4-runtime-4.8.jar",
            "sha256": "2337df5d81e715b39aeea07aac46ad47e4f1f9e9cd7c899f124f425913efdcf8",
        },
        "4.7.2": {
            "path": "org/antlr/antlr4-runtime/4.7.2/antlr4-runtime-4.7.2.jar",
            "sha256": "4c518b87d4bdff8b44cd8cbc1af816e944b62a3fe5b80b781501cf1f4759bbc4",
        },
        "4.7.1": {
            "path": "org/antlr/antlr4-runtime/4.7.1/antlr4-runtime-4.7.1.jar",
            "sha256": "43516d19beae35909e04d06af6c0c58c17bc94e0070c85e8dc9929ca640dc91d",
        },
        "4.7.4-opt": {
            "path": "com/tunnelvisionlabs/antlr4-runtime/4.7.4/antlr4-runtime-4.7.4.jar",
            "sha256": "c0616e1eb3b7aa6b4de9a304ea458d50cac279f78b0b65bf7a8176701f8402ee",
        },
        "4.7.3-opt": {
            "path": "com/tunnelvisionlabs/antlr4-runtime/4.7.3/antlr4-runtime-4.7.3.jar",
            "sha256": "5f4f0c4031e4b83cb369ef00f4909cdb6f62b11e3d253f83a6184d80c5eb3157",
        },
        "4.7.2-opt": {
            "path": "com/tunnelvisionlabs/antlr4-runtime/4.7.2/antlr4-runtime-4.7.2.jar",
            "sha256": "fdec73953ba059034336a8e0b0ea5204f6897900bf0b0fa35347ce8a8bb88816",
        },
        "4.7.1-opt": {
            "path": "com/tunnelvisionlabs/antlr4-runtime/4.7.1/antlr4-runtime-4.7.1.jar",
            "sha256": "ce4f77ff9dc014feb9a8e700de5c77101d203acb6a1e8fa3446905c391ac72b9",
        },
    },
    "antlr4_tool": {
        "4.12.0": {
            "path": "org/antlr/antlr4/4.12.0/antlr4-4.12.0.jar",
            "sha256": "d957656b132a052fa66c08b9d1a4a9a9e8275720f6f62e43c72d1de2bfcdc388",
        },
        "4.11.1": {
            "path": "org/antlr/antlr4/4.11.1/antlr4-4.11.1.jar",
            "sha256": "e9686e8a663ca512afe3a2eeb6f6ad3f303abb46188991f19ebc6a0fd9c1c14f",
        },
        "4.11.0": {
            "path": "org/antlr/antlr4/4.11.0/antlr4-4.11.0.jar",
            "sha256": "33ec099fa7ff8dd617a40e81522b39ac92c95aed4b0a4dbcbc8782903150f844",
        },
        "4.10.1": {
            "path": "org/antlr/antlr4/4.10.1/antlr4-4.10.1.jar",
            "sha256": "6bef3dad65a1bd55533981d7ef694d27dcfb4e7a70f560dd026c8895b35a7468",
        },
        "4.10": {
            "path": "org/antlr/antlr4/4.10/antlr4-4.10.jar",
            "sha256": "f32485cfdf114295a58cd2005af9463706c5fd43d900118126eb3a9ac36bfec3",
        },
        "4.9.3": {
            "path": "org/antlr/antlr4/4.9.3/antlr4-4.9.3.jar",
            "sha256": "386fec520b8962fe37f448af383920ea33d7a532314b36d7ba9ccec1ba95eb37",
        },
        "4.9.2": {
            "path": "org/antlr/antlr4/4.9.2/antlr4-4.9.2.jar",
            "sha256": "7d66253762da7c8c7ab6ac05da1471aeeb3cb8e92310ecfb08f939306b4c7dae",
        },
        "4.9.1": {
            "path": "org/antlr/antlr4/4.9.1/antlr4-4.9.1.jar",
            "sha256": "e6bd18f14126ab85a42dcb80ba5f67da2f35ba164ec5a64d40024bd0e7436584",
        },
        "4.9": {
            "path": "org/antlr/antlr4/4.9/antlr4-4.9.jar",
            "sha256": "",
        },
        "4.8": {
            "path": "org/antlr/antlr4/4.8/antlr4-4.8.jar",
            "sha256": "6e4477689371f237d4d8aa40642badbb209d4628ccdd81234d90f829a743bac8",
        },
        "4.7.2": {
            "path": "org/antlr/antlr4/4.7.2/antlr4-4.7.2.jar",
            "sha256": "a3811fad1e4cb6dde62c189c204cf931c5fa40e06e43839ead4a9f2e188f2fe5",
        },
        "4.7.1": {
            "path": "org/antlr/antlr4/4.7.1/antlr4-4.7.1.jar",
            "sha256": "a2cdc2f2f8eb893728832568dc54d080eb5a1495edb3b66e51b97122a60a0d87",
        },
        "4.7.4-opt": {
            "path": "com/tunnelvisionlabs/antlr4/4.7.4/antlr4-4.7.4.jar",
            "sha256": "f84d71d130f17b13f0934af7575626890a4dab0c588a95b80572a66f7deacca4",
        },
        "4.7.3-opt": {
            "path": "com/tunnelvisionlabs/antlr4/4.7.3/antlr4-4.7.3.jar",
            "sha256": "06cd5f3a9488b32cb1022360df054bbe7aebe8e817c0aa58c8feec05879e0c63",
        },
        "4.7.2-opt": {
            "path": "com/tunnelvisionlabs/antlr4/4.7.2/antlr4-4.7.2.jar",
            "sha256": "fcc2a0365de371d8676ab9b45c49aa2e784036a77b76383892887c89c5725ca3",
        },
        "4.7.1-opt": {
            "path": "com/tunnelvisionlabs/antlr4/4.7.1/antlr4-4.7.1.jar",
            "sha256": "de9a7b94b48ea7c8100663cbb1a54465c37671841c0aefdf4c53a72212555ae8",
        },
    },
    "antlr3_runtime": {
        "3.5.2": {
            "path": "org/antlr/antlr-runtime/3.5.2/antlr-runtime-3.5.2.jar",
            "sha256": "ce3fc8ecb10f39e9a3cddcbb2ce350d272d9cd3d0b1e18e6fe73c3b9389c8734",
        },
    },
    "antlr3_tool": {
        "3.5.2": {
            # the official release generates problematic C++ code, we therefore use a
            # custom build forked from https://github.com/ibre5041/antlr3.git
            "path": "https://github.com/marcohu/antlr3/raw/master/antlr-3.5.3.jar",
            "sha256": "897d0b914adf2e63899ada179c5f4aeb606d59fdfbb6ccaff5bc87aec300e2ce",
        },
    },
    "antlr2": {
        "2.7.7": {
            "path": "antlr/antlr/2.7.7/antlr-2.7.7.jar",
            "sha256": "88fbda4b912596b9f56e8e12e580cc954bacfb51776ecfddd3e18fc1cf56dc4c",
        },
    },
    "stringtemplate4": {
        "4.3": {
            "path": "org/antlr/ST4/4.3/ST4-4.3.jar",
            "sha256": "28547dba48cfceb77b6efbfe069aebe9ed3324ae60dbd52093d13a1d636ed069",
        },
        "4.0.8": {
            "path": "org/antlr/ST4/4.0.8/ST4-4.0.8.jar",
            "sha256": "58caabc40c9f74b0b5993fd868e0f64a50c0759094e6a251aaafad98edfc7a3b",
        },
    },
    "javax_json": {
        "1.0.4": {
            "path": "org/glassfish/javax.json/1.0.4/javax.json-1.0.4.jar",
            "sha256": "0e1dec40a1ede965941251eda968aeee052cc4f50378bc316cc48e8159bdbeb4",
        },
    },
}

def _fail_with_attr(message, attr_name):
    """Helper function for consistent error handling with attribute context."""
    fail(message, attr = attr_name)

def rules_antlr_dependencies(*versions_and_languages):
    """Loads the dependencies for the specified ANTLR releases.

    You have to provide at least the version number of the ANTLR release you want to use. To
    load the dependencies for languages besides Java, you have to indicate the languages as well.

    ```starlark
    load("@rules_antlr//antlr:lang.bzl", "CPP", "PYTHON")
    load("@rules_antlr//antlr:repositories.bzl", "rules_antlr_dependencies")

    rules_antlr_dependencies("4.7.2", CPP, PYTHON)
    ```

    Args:
      *versions_and_languages: the ANTLR release versions to make available for the provided target languages.
    """
    if versions_and_languages:
        versions = []
        languages = []
        supported_versions = v4 + v3 + v2

        for version_or_language in versions_and_languages:
            if not version_or_language in supported_versions:
                if type(version_or_language) == "int" or str(version_or_language).isdigit():
                    _fail_with_attr(
                        'Integer version \'{}\' no longer valid. Use semantic version "{}" instead.'.format(
                            version_or_language,
                            ".".join(str(version_or_language).elems()),
                        ),
                        "versions_and_languages",
                    )
                elif str(version_or_language).replace(".", "").isdigit():
                    _fail_with_attr(
                        'Unsupported ANTLR version provided: "{0}". Currently supported are: {1}'.format(
                            version_or_language,
                            supported_versions,
                        ),
                        "versions_and_languages",
                    )
                elif not version_or_language in supported_languages():
                    _fail_with_attr(
                        'Invalid language provided: "{0}". Currently supported are: {1}'.format(
                            version_or_language,
                            supported_languages(),
                        ),
                        "versions_and_languages",
                    )
                languages.append(version_or_language)
            else:
                versions.append(version_or_language)

        if not versions:
            _fail_with_attr("Missing ANTLR version", "versions_and_languages")

        # only one version allowed per ANTLR release stream
        _validate_versions(versions)

        # if no language is specified, assume Java
        if not languages:
            languages = [JAVA]

        for version in sorted(versions, key = _to_string):
            if version in v4:
                version = "4.12.0" if version == 4 else version
                _antlr4_dependencies(languages, version)
            elif version in v3:
                version = "3.5.2" if version == 3 else version
                _antlr3_dependencies(languages, version)
            elif version in v2:
                version = "2.7.7" if version == 2 else version
                _antlr2_dependencies(languages, version)
    else:
        _fail_with_attr("Missing ANTLR version", "versions_and_languages")

def rules_antlr_optimized_dependencies(version):
    """Loads the dependencies for the "optimized" fork of ANTLR 4 maintained by Sam Harwell.

    ```starlark
    load("@rules_antlr//antlr:repositories.bzl", "rules_antlr_optimized_dependencies")

    rules_antlr_optimized_dependencies("4.7.2")
    ```

    Args:
      version: the ANTLR release version to make available.
    """
    if version in v4_opt:
        version = "4.12.0" if version == 4 else version
        _antlr4_optimized_dependencies(version = version)
    elif type(version) == "int" or str(version).isdigit():
        _fail_with_attr(
            'Integer version \'{}\' no longer valid. Use semantic version "{}" instead.'.format(
                version,
                ".".join(str(version).elems()),
            ),
            "version",
        )
    else:
        _fail_with_attr(
            'Unsupported ANTLR version provided: "{0}". Currently supported are: {1}'.format(
                version,
                v4_opt,
            ),
            "version",
        )

def _antlr4_optimized_dependencies(version):
    _dependencies({
        "antlr4_runtime": version,
        "antlr4_tool": version,
        "antlr3_runtime": "3.5.2",
        "stringtemplate4": "4.0.8",
        "javax_json": "1.0.4",
    })


def _antlr4_dependencies(version, languages):
    _dependencies({
        "antlr4_runtime": version,
        "antlr4_tool": version,
        "antlr3_runtime": "3.5.2",
        "stringtemplate4": "4.3.3",
        "javax_json": "1.0.4",
    })
    archive = PACKAGES["antlr"][version]
    build_script, workspace = _antlr4_build_script(languages)

    if build_script:
        http_archive(
            name = "antlr4_runtimes",
            sha256 = archive["sha256"],
            strip_prefix = archive["prefix"],
            url = archive["url"],
            build_file_content = build_script,
            workspace_file_content = workspace,
        )

def _antlr4_build_script(languages):
    script = ""
    workspace = ""

    if CPP in languages:
        script += """
cc_library(
    name = "cpp",
    srcs = glob(["runtime/Cpp/runtime/src/**/*.cpp"]),
    hdrs = glob(["runtime/Cpp/runtime/src/**/*.h"]),
    includes = ["runtime/Cpp/runtime/src"],
    visibility = ["//visibility:public"],
)
"""

    if GO in languages:
        workspace += _load_http(workspace) + """
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "b78f77458e77162f45b4564d6b20b6f92f56431ed59eaaab09e7819d1d850313",
    urls = [
        "https://mirror.bazel.build/github.com/bazel-contrib/rules_go/releases/download/v0.53.0/rules_go-v0.53.0.zip",
        "https://github.com/bazel-contrib/rules_go/releases/download/v0.53.0/rules_go-v0.53.0.zip",
    ],
)
load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains(version = "1.24.1")
"""
        script += """
load("@io_bazel_rules_go//go:def.bzl", "go_library")
go_library(
    name = "go",
    srcs = glob(["runtime/Go/antlr/*.go"], allow_empty = True),
    importpath = "github.com/antlr/antlr4/runtime/Go/antlr",
    visibility = ["//visibility:public"],
)
"""

    if PYTHON2 in languages:
        workspace += _load_http(workspace) + _load_rules_python_repositories(workspace)
        script += _load_rules_python_defs(script) + """
py_library(
    name = "python2",
    srcs = glob(["runtime/Python3/src/**/*.py"], allow_empty = True),
    imports = ["runtime/Python3/src"],
    visibility = ["//visibility:public"],
)
"""

    if PYTHON in languages or PYTHON3 in languages:
        workspace += _load_http(workspace) + _load_rules_python_repositories(workspace)
        script += _load_rules_python_defs(script) + """
py_library(
    name = "python",
    srcs = glob(["runtime/Python3/src/**/*.py"], allow_empty = True),
    imports = ["runtime/Python3/src"],
    visibility = ["//visibility:public"],
)
alias(
    name = "python3",
    actual = ":python",
)
"""

    return (script, workspace)

def _load_http(workspace):
    return "" if workspace.find("@bazel_tools//tools/build_defs/repo:http.bzl") > -1 else 'load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")'

def _load_rules_python_repositories(workspace):
    return "" if workspace.find('load("@rules_python//python:repositories.bzl", "py_repositories")') > -1 else """
http_archive(
    name = "rules_python",
    sha256 = "2ef40fdcd797e07f0b6abda446d1d84e2d9570d234fddf8fcd2aa262da852d1c",
    strip_prefix = "rules_python-1.2.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/1.2.0/rules_python-1.2.0.tar.gz",
)
load("@rules_python//python:repositories.bzl", "py_repositories")
py_repositories()
"""

def _load_rules_python_defs(script):
    return "" if script.find('load("@rules_python//python:defs.bzl"') > -1 else 'load("@rules_python//python:defs.bzl", "py_library")'

def _antlr3_dependencies(version, languages):
    _dependencies({
        "antlr3_runtime": version,
        "antlr3_tool": version,
        "stringtemplate4": "4.0.8",
    })
    archive = PACKAGES["antlr"][version]
    build_script = _antlr3_build_script(languages)

    if build_script:
        http_archive(
            name = "antlr3_runtimes",
            sha256 = archive["sha256"],
            strip_prefix = archive["prefix"],
            url = archive["url"],
            build_file_content = build_script,
        )

def _antlr3_build_script(languages):
    script = ""

    if CPP in languages:
        script += """
cc_library(
    name = "cpp",
    hdrs = glob(["runtime/Cpp/include/*.hpp", "runtime/Cpp/include/*.inl"]),
    includes = ["runtime/Cpp/include"],
    visibility = ["//visibility:public"],
)
"""

    if PYTHON2 in languages:
        script += """
py_library(
    name = "python2",
    srcs = glob(["runtime/Python/antlr3/*.py"]),
    imports = ["runtime/Python/antlr3"],
    visibility = ["//visibility:public"],
)
"""

    if PYTHON in languages or PYTHON3 in languages:
        script += """
py_library(
    name = "python",
    srcs = glob(["runtime/Python3/antlr3/*.py"]),
    imports = ["runtime/Python3/antlr3"],
    visibility = ["//visibility:public"],
)
"""

    return script

def _antlr2_dependencies(version, languages):
    _dependencies({
        "antlr2": version,
    })
    archive = PACKAGES["antlr"][version]
    build_script = _antlr2_build_script(languages)

    if build_script:
        http_archive(
            name = "antlr2_runtimes",
            sha256 = archive["sha256"],
            strip_prefix = "antlr-2.7.7",
            url = archive["url"],
            patches = archive["patches"] if "patches" in archive else [],
            build_file_content = build_script,
        )

def _antlr2_build_script(languages):
    script = ""

    if CPP in languages:
        script += """
cc_library(
    name = "cpp",
    srcs = select({
        "@bazel_tools//src/conditions:windows": glob(["lib/cpp/src/*.cpp"]),
        "//conditions:default": glob(["lib/cpp/src/*.cpp"], exclude=["lib/cpp/src/dll.cpp"]),
    }),
    hdrs = glob(["lib/cpp/antlr/*.hpp"]),
    includes = ["lib/cpp"],
    visibility = ["//visibility:public"],
)
"""

    if PYTHON in languages or PYTHON2 in languages:
        script += """
py_library(
    name = "python",
    srcs = glob(["lib/python/antlr/*.py"]),
    imports = ["lib/python/antlr"],
    visibility = ["//visibility:public"],
)
"""

    return script

def _dependencies(dependencies):
    for key in dependencies:
        version = dependencies[key]
        _download(
            name = key,
            path = PACKAGES[key][version]["path"],
            sha256 = PACKAGES[key][version]["sha256"],
        )

def _download(name, path, sha256):
    http_jar(
        name = name,
        url = path if path.startswith("https") else "https://repo1.maven.org/maven2/" + path,
        sha256 = sha256,
    )

def _validate_versions(versions):
    store = {}
    for version in versions:
        v = str(version)[0]
        p = store.get(v)
        if p:
            _fail_with_attr(
                'You can only load one version from ANTLR {0}. You specified both "{1}" and "{2}".'.format(
                    v,
                    p,
                    version,
                ),
                "versions_and_languages",
            )
        store[v] = version

def _to_string(x):
    return str(x)
