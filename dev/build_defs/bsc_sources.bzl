"""Declare files relevant to the Bluespec compiler."""

BSC_SOURCES_EXTENSIONS = [".bs", ".bsv", ".bo", ".ba", ".v"]

BSCSourcesInfo = provider(fields=["modules"])

BSC_SOURCES_RULE_ATTRIBUTES = {
    "srcs": attr.label_list(allow_files=BSC_SOURCES_EXTENSIONS),
    "modules": attr.string_list_dict(),
    "_bsc": attr.label(
        executable = True,
        cfg = "exec",
        allow_files = True,
        default="@local_tool//:bsc"
    )
}

def bsc_sources_rule_implementation(ctx):
    sources = {
        extension: {src.basename: src for src in ctx.files.srcs if src.basename.endswith(extension)}
        for extension in BSC_SOURCES_EXTENSIONS
    }

    generated = {extension: [] for extension in BSC_SOURCES_EXTENSIONS}

    # Declare compilation from bs/bsv to bo/ba.
    for (name, source) in sources[".bs"].items() + sources[".bsv"].items():
        basename = name.split(".", 1)[0]
        object_name = basename + ".bo"
        if object_name not in sources[".bo"]:
            object_file = ctx.actions.declare_file(object_name)
        else:
            continue

        module_names = ctx.attr.modules.get(name, [])

        elaboration_files = [
            ctx.actions.declare_file(m + ".ba") 
            for m in module_names
            if m + ".ba" not in sources[".ba"]
        ]

        verilog_files = [
            ctx.actions.declare_file(m + ".v") 
            for m in module_names
            if m + ".v" not in sources[".v"]
        ]

        partial_arguments = ["-bdir", object_file.dirname, "-vdir", object_file.dirname]
        for module in module_names:
            partial_arguments += ["-g", module]
        partial_arguments += [source.path]

        ctx.actions.run(
            inputs = sources[".bs"].values() + sources[".bsv"].values(),
            outputs = [object_file] + elaboration_files,
            arguments = ["-sim", "-elab"] + partial_arguments,
            mnemonic = "BSCCompilePartial",
            progress_message = "Partially compiling from bluespec: %s" % source,
            executable = ctx.executable._bsc
        )

        ctx.actions.run(
            inputs = sources[".bs"].values() + sources[".bsv"].values(),
            outputs = verilog_files,
            arguments = ["-verilog"] + partial_arguments,
            mnemonic = "BSCCompileVerilog",
            progress_message = "Compiling Verilog from bluespec: %s" % source,
            executable = ctx.executable._bsc
        )

        generated[".bo"] += [object_file]
        generated[".ba"] += elaboration_files
        generated[".v"] += verilog_files

    bsc_sources_info = BSCSourcesInfo(modules=ctx.attr.modules)
    output_group_info = OutputGroupInfo(**{
        extension: sources[extension].values() + generated[extension]
        for extension in BSC_SOURCES_EXTENSIONS
    })
    return bsc_sources_info, output_group_info

bsc_sources_rule = rule(
    implementation = bsc_sources_rule_implementation,
    attrs = BSC_SOURCES_RULE_ATTRIBUTES,
)

def bsc_sources(name, **kwargs):
    bsc_sources_rule(name=name, **kwargs)