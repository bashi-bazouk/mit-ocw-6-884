"""Link an executable simulation with Bluespec."""
load(":bsc_sources.bzl", "BSC_SOURCES_EXTENSIONS", "BSCSourcesInfo")

BSC_SIMULATION_RULE_ATTRIBUTES = {
    "bsc_sources": attr.label(mandatory=True, providers=[BSCSourcesInfo]),
    "module": attr.string(mandatory=True),
    "_bsc": attr.label(
        executable = True,
        cfg = "exec",
        allow_files = True,
        default="@bsc_local//:bin/bsc"
    ),
    "_bsc_runfiles": attr.label(
        allow_files = True,
        default="@bsc_local//:bsc_runfiles"
    )
}

def bsc_simulation_rule_implementation(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    executable_so = ctx.actions.declare_file(ctx.attr.name + ".so")
    simdir_path = executable.dirname

    sources = {
        extension: getattr(ctx.attr.bsc_sources[OutputGroupInfo], extension).to_list()
        for extension in BSC_SOURCES_EXTENSIONS
    }

    inputs = [
        f 
        for fs in sources.values()
        for f in fs
    ]

    paths = list(set([f.dirname for f in inputs]))

    outputs = [
        executable, 
        executable_so
    ] + [
        ctx.actions.declare_file(pattern % (ctx.attr.module, extension))
        for pattern in [ "%s.%s", "model_%s.%s"]
        for extension in [
            "cxx", "h", "o"
        ]
    ]

    arguments = [
        "-sim", 
        "-simdir", simdir_path, 
        "-p", ":".join(paths),
        "-e", ctx.attr.module,
        "-o", executable.path
    ]

    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        arguments = arguments,
        progress_message = "Linking a bsc simulation: " + ctx.attr.name,
        tools = ctx.files._bsc_runfiles,
        executable = ctx.executable._bsc
    )

    return DefaultInfo(executable=executable)

bsc_simulation_rule = rule(
    implementation = bsc_simulation_rule_implementation,
    attrs = BSC_SIMULATION_RULE_ATTRIBUTES,
    executable = True,
)

def bsc_simulation(name, **kwargs):
    bsc_simulation_rule(name=name, **kwargs)