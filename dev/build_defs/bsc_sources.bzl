"""Declare files relevant to the Bluespec compiler."""
load("utilities.bzl", "index_by_extension", "any_file_has_short_path", "flatten_index", "output_group_info_to_index", "relpath", "short_dir")

BSC_SOURCES_EXTENSIONS = [".bs", ".bsv", ".bsvi", ".bo", ".ba", ".v"]

BSCSourcesInfo = provider(fields=["modules"])

BSC_SOURCES_RULE_ATTRIBUTES = {
    "srcs": attr.label_list(allow_files=BSC_SOURCES_EXTENSIONS),
    "modules": attr.string_list_dict(),
    "deps": attr.label_list(providers=[BSCSourcesInfo]),
    "compile_flags": attr.string_list(),
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

def bsc_sources_rule_implementation(ctx):
    dep_sourcess = [flatten_index(output_group_info_to_index(dep[OutputGroupInfo])) for dep in ctx.attr.deps]
    sourcess = [ctx.files.srcs, ctx.files._bsc_runfiles] + dep_sourcess
    sources = index_by_extension([f for fs in sourcess for f in fs], BSC_SOURCES_EXTENSIONS)

    inputs = flatten_index(sources)

    paths = list(set([src.dirname for src in inputs]))

    # Declare compilation from bs/bsv to bo/ba.
    for source in sources[".bs"] + sources[".bsv"]:
        object_short_path = source.short_path.rsplit(".", 1)[0] + ".bo"
        if any_file_has_short_path(sources[".bo"], object_short_path):
            continue
        object_file = ctx.actions.declare_file(relpath(object_short_path, ctx.label.package))

        module_names = ctx.attr.modules.get(relpath(source.short_path, ctx.label.package), [])

        elaboration_files = [
            ctx.actions.declare_file(relpath(elaboration_file_short_path, ctx.label.package), sibling=source) 
            for m in module_names
            for elaboration_file_short_path in ["%s/%s.ba" % (short_dir(source), m)]
            if not any_file_has_short_path(sources[".ba"], elaboration_file_short_path)
        ]

        verilog_files = [
            ctx.actions.declare_file(relpath(verilog_file_short_path, ctx.label.package), sibling=source) 
            for m in module_names
            for verilog_file_short_path in ["%s/%s.v" % (short_dir(source), m)]
            if not any_file_has_short_path(sources[".v"], verilog_file_short_path)
        ]

        _paths = [path for path in paths if path != object_file.dirname]

        partial_arguments = [
            "-bdir", object_file.dirname,
            "-vdir", object_file.dirname,
            "-p", ":".join(paths)
        ] + ctx.attr.compile_flags
        for module in module_names:
            partial_arguments += ["-g", module]
        partial_arguments += [source.path]

        ctx.actions.run(
            inputs = inputs,
            outputs = [object_file] + elaboration_files,
            arguments = ["-sim", "-elab"] + partial_arguments,
            mnemonic = "BSCCompilePartial",
            progress_message = "Partially compiling from bluespec: %s" % source.basename,
            tools = ctx.files._bsc_runfiles,
            executable = ctx.executable._bsc
        )

        if verilog_files:
            ctx.actions.run(
                inputs = inputs,
                outputs = verilog_files,
                arguments = ["-verilog"] + partial_arguments,
                mnemonic = "BSCCompileVerilog",
                progress_message = "Compiling Verilog from bluespec: %s" % source,
                tools = ctx.files._bsc_runfiles,
                executable = ctx.executable._bsc
            )

        sources[".bo"] += [object_file]
        sources[".ba"] += elaboration_files
        sources[".v"] += verilog_files

    bsc_sources_info = BSCSourcesInfo(modules=ctx.attr.modules)
    output_group_info = OutputGroupInfo(**sources)
    return bsc_sources_info, output_group_info

bsc_sources_rule = rule(
    implementation = bsc_sources_rule_implementation,
    attrs = BSC_SOURCES_RULE_ATTRIBUTES,
)

def bsc_sources(name, **kwargs):
    bsc_sources_rule(name=name, **kwargs)