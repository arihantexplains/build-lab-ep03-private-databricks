# The demo notebook

`summary.py` is the notebook the plug-in runs with `runs/submit`. It takes one widget, `rows`, builds that many synthetic rows, and returns a small JSON summary with `dbutils.notebook.exit`. The plug-in reads it back through `runStatus`.

Import it to `/Shared/ab-demo/summary` while public network access is still on (setup step 5), and give the managed identity access to it.
