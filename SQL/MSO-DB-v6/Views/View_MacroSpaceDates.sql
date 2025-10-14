CREATE VIEW [dbo].[View_MacroSpaceDates] AS
SELECT DISTINCT 
    CONVERT(varchar, Create_Date, 112) AS SQLDate,  -- Format as yyyymmdd
    REPLACE(CONVERT(varchar, Create_Date, 106), ' ', '-') AS TextDate  -- Format as dd-mmm-yy

FROM 
    dbo.MacroSnapShot;

GO

