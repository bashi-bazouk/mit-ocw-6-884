"""Invoke bsc on some bs files."""

BSC_COMPILE_RULE_ATTRIBUTES = {
    "srcs": attr.label_list(allow_files=[".bs"]),
    "_bsc": attr.label(
        executable = True,
        cfg = "exec",
        allow_files = True,
        default="@local_tool//:bsc"
    )
}

def bsc_compile_rule_implementation(ctx):
    object_files = []
    for src in ctx.files.srcs:
        base = src.basename.split(".",1)[0]
        object_file = ctx.actions.declare_file("%s.bo" % base)
        arguments = ctx.actions.args()
        arguments.add_all(["-u", "-elab", "-sim"])
        arguments.add("-bdir", object_file.dirname)
        arguments.add(src)
        ctx.actions.run(
            inputs = [src],
            outputs = [object_file],
            arguments = [arguments],
            progress_message = "Invoking bsc.",
            executable = ctx.executable._bsc
        )
        object_files.append(object_file)

    return DefaultInfo(files=depset(object_files))

bsc_compile_rule = rule(
    implementation = bsc_compile_rule_implementation,
    attrs = BSC_COMPILE_RULE_ATTRIBUTES,
)

def bsc_compile(name, **args):
    bsc_compile_rule(name = name, **args)