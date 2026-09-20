load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ChatMessageBackground",
    module_name = "ChatMessageBackground",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
    	"//submodules/Display:Display",
    	"//submodules/TelegramPresentationData:TelegramPresentationData",
    	"//submodules/ComponentFlow:ComponentFlow",
    	"//submodules/TelegramUI/Components/GlassBackgroundComponent",
    	"//submodules/TelegramCore:TelegramCore",
    	"//submodules/WallpaperBackgroundNode:WallpaperBackgroundNode",
    ],
    visibility = [
        "//visibility:public",
    ],
)
