CREATE VIEW dbo.View_ImportInfoPerformance AS
SELECT
  TRY_CAST(
    SUBSTRING(REPLACE(REPLACE(File_Name, 'Waitrose_PerformanceAndLoyalty_', ''), '.txt', ''), 1, 4) 
    + SUBSTRING(REPLACE(REPLACE(File_Name, 'Waitrose_PerformanceAndLoyalty_', ''), '.txt', ''), LEN(REPLACE(REPLACE(File_Name, 'Waitrose_PerformanceAndLoyalty_', ''), '.txt', '')) - 1, 2) 
    AS Numeric(6, 0)
  ) AS Date_ID,
  Rows
FROM
  dbo.Importinfo
WHERE
  Type = 'Performance';

GO

