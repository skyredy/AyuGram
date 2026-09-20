load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AiraGramUI",
    module_name = "AiraGramUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/TelegramUI/Components/TabBarComponent",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/MergeLists:MergeLists",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
