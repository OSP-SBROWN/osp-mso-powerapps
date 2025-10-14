
CREATE   PROCEDURE [ui].[New_BaysReccDiff]
    @ReportID INT,
    @Granularity CHAR(1),
    @BayReccDiff DECIMAL(18, 2) OUTPUT  -- Output parameter to return the calculated difference
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TableName NVARCHAR(50) = QUOTENAME('C_StoreCategory_' + CAST(@ReportID AS NVARCHAR(10)));
    DECLARE @SqlQuery NVARCHAR(MAX);

    -- Check if the table exists
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = @TableName)
    BEGIN
        SET @BayReccDiff = NULL;
        RETURN;
    END

    -- Construct the SQL query based on Granularity
    IF @Granularity = 'S'
    BEGIN
        SET @SqlQuery = N'SELECT @BayReccDiff = SUM(Store_Bays_Recc - Bays) FROM ' + @TableName;
    END
    ELSE IF @Granularity = 'T'
    BEGIN
        SET @SqlQuery = N'SELECT @BayReccDiff = SUM(Temp_Bays_Recc - Bays) FROM ' + @TableName;
    END
    ELSE IF @Granularity = 'D'
    BEGIN
        SET @SqlQuery = N'SELECT @BayReccDiff = SUM(Dept_Bays_Recc - Bays) FROM ' + @TableName;
    END
    ELSE
    BEGIN
        -- If the granularity value is not 'S', 'T', or 'D', return a NULL value
        SET @BayReccDiff = NULL;
        RETURN;
    END

    -- Execute the constructed SQL query
    EXEC sp_executesql @SqlQuery, N'@BayReccDiff DECIMAL(18, 2) OUTPUT', @BayReccDiff OUTPUT;
END;

GO

