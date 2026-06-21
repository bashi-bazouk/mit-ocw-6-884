"""Invoke bsc on some bs files."""
load(":bsc_compile.bzl", "BluespecCompileInfo")

BSC_LINK_RULE_ATTRIBUTES = {
    "top": attr.string(mandatory=True),
    "deps": attr.label_list(providers=[BluespecCompileInfo]),
    "simulator": attr.string(values=["iverilog"], default="iverilog"),
    "_bsc": attr.label(
        executable = True,
        cfg = "exec",
        allow_files = True,
        default="@local_tool//:bsc"
    )
}

def bsc_link_rule_implementation(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    executable_so = ctx.actions.declare_file(ctx.attr.name + ".so")
    path = executable.dirname

    inputs = [
        file
        for dep in ctx.attr.deps
        for file in dep[DefaultInfo].files.to_list()
    ]
    paths = {
        dep[BluespecCompileInfo].path: None
        for dep in ctx.attr.deps
    }.keys()

    outputs = [
        executable, 
        executable_so
    ] + [
        ctx.actions.declare_file(pattern % (ctx.attr.top, extension))
        for pattern in [ "%s.%s", "model_%s.%s"]
        for extension in [
            "cxx", "h", "o"
        ]
    ]


    arguments = ctx.actions.args()
    arguments.add_all(["-sim"])
    arguments.add("-simdir", path)
    arguments.add("-p", ":".join(paths))
    arguments.add("-e", ctx.attr.top)
    arguments.add("-o", executable.path)
    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        arguments = [arguments],
        progress_message = "Linking a simulation with bsc.",
        executable = ctx.executable._bsc
    )

    return DefaultInfo(executable=executable)

bsc_link_rule = rule(
    implementation = bsc_link_rule_implementation,
    attrs = BSC_LINK_RULE_ATTRIBUTES,
    executable = True,
)

def bsc_link(name, **args):
    bsc_link_rule(name = name, **args)