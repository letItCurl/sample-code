# Some code
> Just a sample code

ActiveExport was created on my initiative to make export for the user exceptionally easy and reliable to implement.

## Description
With just one line of code added to any model, several methods will be added to your model to allow for exporting of the entire table, with specific queries, table and column names.

The client can access ActiveExport instances via a view, creating a single page for export for all models.
The introduction of ActiveExport was a impressive breakthrough, helping my team to ship faster and saving money on developers.

## How it works:
Add to any model the line:
```
has_one_export :events
```

Then when the user vists the export page, he can clic on "export" and the export worker would be trigger to prepare the csv file.
