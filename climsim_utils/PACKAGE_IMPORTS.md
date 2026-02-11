# How `climsim_utils` Package Imports Work

## `__init__.py`

The `__init__.py` file in this directory is empty. Its sole purpose is to mark
`climsim_utils/` as a **Python package**. Without it, Python would not recognize
this directory as a package, and import statements like
`from climsim_utils.data_utils import *` would fail.

## Import mechanism

Throughout the codebase, the standard import is:

```python
from climsim_utils.data_utils import *
```

This works through three things:

1. **`__init__.py`** — Tells Python that `climsim_utils/` is a package. The file
   does not need any content; its existence is sufficient.

2. **`setup.py` with `find_packages()`** — `find_packages()` discovers directories
   containing `__init__.py` and registers them as installable packages. Running
   `pip install -e .` places `climsim_utils` on `sys.path`, making it importable
   from anywhere.

3. **Dotted path resolution** — Python resolves `climsim_utils.data_utils` by
   finding the `climsim_utils` package, then locating `data_utils.py` inside it.

## Is the directory structure critical?

Yes. The directory layout (`climsim_utils/data_utils.py`) must match the import
path (`climsim_utils.data_utils`). However, the caller's filesystem location does
not matter as long as the package is installed. If the package is *not* installed,
imports only work when the working directory or `PYTHONPATH` includes the repo root.

## Is `__init__.py` required?

For this project, yes. Python 3.3+ supports "namespace packages" without
`__init__.py`, but `setuptools.find_packages()` explicitly requires it to identify
packages. Removing `__init__.py` would break both the install and all imports.
