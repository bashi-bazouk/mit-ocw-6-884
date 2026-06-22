
def file_extension(filename):
    return "." + filename.split(".", 1)[-1] if "." in filename else ""

def collect_extensions(files):
    return list(set([
        file_extension(file.basename)
        for file in files
    ]))

def index_by_extension(files, extensions=None):
    extensions = extensions or collect_extensions(files)
    return {
        extension: [file for file in files if file_extension(file.basename) == extension]
        for extension in extensions
    }

def any_file_has_short_path(files, short_path):
    return any([file.short_path == short_path for file in files])

def index_by_extension_has_file(filename):
    extension = filename.split(".", 1)[-1]

def short_dir(file):
    return file.short_path.rsplit("/",1)[0]

def relpath(path, start):
    path_slugs = path.split("/")
    start_slugs = start.split("/")

    for i in range(min(len(path_slugs)-1, len(start_slugs))):
        if path_slugs[0] != start_slugs[0]:
            break
        path_slugs.pop(0)
        start_slugs.pop(0)

    return "/".join([".." for _ in start_slugs] + path_slugs)