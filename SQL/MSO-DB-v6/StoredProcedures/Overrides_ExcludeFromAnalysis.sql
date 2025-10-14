
CREATE   PROCEDURE [ui].[Overrides_ExcludeFromAnalysis]
    @ReportID int,
    @Gran_Code nvarchar(55),
    @ValueToSet varchar(max) = NULL  -- Allow NULL as a default value
AS
BEGIN
    -- Deleting rows based on the given criteria
    DELETE FROM dbo.BayRules
    WHERE ReportID = @ReportID
      AND Gran_Code = @Gran_Code
      AND ApplyColumn='Exclude_from_analysis'
      AND Group_Key='Exclude';

    -- Insert a row with 'C' as Granularity if ValueToSet is not NULL, not blank, and not '_'
    IF @ValueToSet IS NOT NULL AND LTRIM(RTRIM(@ValueToSet)) <> '' AND @ValueToSet <> '_'
    BEGIN
        INSERT INTO dbo.BayRules (ReportID, Gran_Code, ApplyColumn, Var_or_Col, Group_Key, Granularity, ValueToSet)
        VALUES (@ReportID, @Gran_Code, 'Exclude_from_analysis', 'C', 'Exclude', 'C', @ValueToSet);
    END
END;

GO

