load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AiraGramGlass",
    module_name = "AiraGramGlass",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display:Display",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramUI/Components/GlassBackgroundComponent",
    ],
    visibility = [
        "//visibility:public",
    ],
)
