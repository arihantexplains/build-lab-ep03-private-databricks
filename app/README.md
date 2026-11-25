# The canvas app

`AB-Databricks-Console.pa.yaml` is the source of the one screen console used in the video: one button per operation, a box for the row count and the run id, and a result panel.

To use it, create a blank canvas app, add the Custom API `ab_DatabricksRequest` as a data source (through the Dataverse environment), and paste the controls from the YAML onto the screen. Each button calls the Custom API with its operation, for example `submitJob` with the row count as `Payload`, and shows `Status` and `Result`.
