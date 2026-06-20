

YOSYS_LIBARY_RULE_ATTRIBUTES = {
    "_yosys": attr.label(default="@local_tool//:yosys")
}

def yosys_library_rule_implementation(ctx):
    pass

yosys_library = rule(
    implementation = yosys_library_rule_implementation,
    attrs = YOSYS_LIBARY_RULE_ATTRIBUTES,
)