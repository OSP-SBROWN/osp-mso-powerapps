
CREATE   PROCEDURE [ui].[Overrides_BayInputUpdate]
    @ReportID int,
    @Gran_Code nvarchar(55),
    @ValueToSet varchar(max) = NULL  -- Allow NULL as a default value
AS
BEGIN
    -- Deleting rows based on the given criteria
    DELETE FROM dbo.BayRules
    WHERE ReportID = @ReportID
      AND Gran_Code = @Gran_Code
      AND ApplyColumn='Bays'
      AND Group_Key='InputOverrides';

    -- Insert a row with 'C' as Granularity if ValueToSet is not NULL or blank
    IF @ValueToSet IS NOT NULL AND LTRIM(RTRIM(@ValueToSet)) <> ''
    BEGIN
        INSERT INTO dbo.BayRules (ReportID, Gran_Code, ApplyColumn, Var_or_Col, Group_Key, Granularity, ValueToSet)
        VALUES (@ReportID, @Gran_Code, 'Bays', 'C', 'InputOverrides', 'C', @ValueToSet);
    END
END;

GO

