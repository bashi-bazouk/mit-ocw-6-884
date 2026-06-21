"""Invoke bsc on some bs files."""

BluespecCompileInfo = provider(fields=["path", "elaborations"])

BSC_COMPILE_RULE_ATTRIBUTES = {
    "srcs": attr.label_list(allow_files=[".bs"], allow_empty=False),
    "elaborations": attr.string_list(),
    "_bsc": attr.label(
        executable = True,
        cfg = "exec",
        allow_files = True,
        default="@local_tool//:bsc"
    )
}

def _bsc_compile_rule_implementation(ctx):
    inputs = ctx.files.srcs
    elaborations = ctx.attr.elaborations
    subpath = "%s/objects" % ctx.attr.name

    # Object files
    outputs = [  
        ctx.actions.declare_file("%s/%s.bo" % (subpath, basename))
        for src in ctx.files.srcs
        for basename in [src.basename.split(".",1)[0]]
    ]

    path = outputs[0].dirname

    # Elaboration files
    outputs += [
        ctx.actions.declare_file("%s/%s.ba" % (subpath, elaboration))
        for elaboration in ctx.attr.elaborations
    ]

    # Arguments
    arguments = ctx.actions.args()
    arguments.add_all(["-sim", "-elab"])
    arguments.add("-bdir", path)
    arguments.add_all([
        arg
        for elaboration in elaborations
        for arg in ("-g", elaboration)
    ])
    arguments.add_all(inputs)

    # Actions
    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        arguments = [arguments],
        progress_message = "Compiling for simulation with bsc.",
        executable = ctx.executable._bsc
    )

    # Providers
    default_info = DefaultInfo(files=depset(outputs))
    bluespec_compile_info = BluespecCompileInfo(
        path=path,
        elaborations = elaborations
    )

    return default_info, bluespec_compile_info

bsc_compile_rule = rule(
    implementation = _bsc_compile_rule_implementation,
    attrs = BSC_COMPILE_RULE_ATTRIBUTES,
)

def bsc_compile(name, **args):
    bsc_compile_rule(name = name, **args)