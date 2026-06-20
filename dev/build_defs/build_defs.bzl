

BSC_LIBARY_RULE_ATTRIBUTES = {
    "_bsc": attr.label(default="@local_tool//:bsc")
}

def bsc_library_rule_implementation(ctx):
    pass

bsc_library = rule(
    implementation = bsc_library_rule_implementation,
    attrs = BSC_LIBARY_RULE_ATTRIBUTES,
)