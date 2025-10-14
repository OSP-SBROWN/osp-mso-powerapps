
CREATE   PROCEDURE [ui].[RefreshScopeCheckNEW]
    @ReportID INT,                        -- Parameter to accept ReportID
    @BayRulesCount INT OUTPUT,           -- Output parameter for BayRulesCount
    @CoreTables INT OUTPUT,              -- Output parameter for DynamicTableNameCount
    @SQL_Success BIT OUTPUT,             -- Output parameter for success status
    @SQL_Message NVARCHAR(255) OUTPUT    -- Output parameter for message
AS
BEGIN
    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = N'Starting procedure execution.';

    BEGIN TRY
        DECLARE @DynamicTableNameCount INT;
        DECLARE @SQL NVARCHAR(MAX);

        -- Retrieve BayRulesCount for the specified ReportID
        SELECT @BayRulesCount = COUNT(*)
        FROM dbo.BayRules BR
        WHERE BR.ReportID = @ReportID;

        -- Construct the dynamic SQL to count tables with names matching pattern
        SET @SQL = N'SELECT @DynamicCount = COUNT(*)
                     FROM sys.tables
                     WHERE name LIKE ''C\_%\_'' + CAST(@ReportID AS NVARCHAR) + ''%'' ESCAPE ''\'''
                     + ' AND SCHEMA_NAME(schema_id) = ''dbo'';';

        -- Execute the dynamic SQL
        EXEC sp_executesql @SQL, N'@ReportID INT, @DynamicCount INT OUTPUT', @ReportID, @DynamicTableNameCount OUTPUT;

        -- Set the output parameter
        SET @CoreTables = @DynamicTableNameCount;

        -- Check if both counts were successfully retrieved
        IF @BayRulesCount IS NOT NULL AND @CoreTables IS NOT NULL
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = N'Success, counts retrieved successfully.';
        END
        ELSE
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = N'Counts could not be retrieved. Check ReportID or data integrity.';
        END
    END TRY
    BEGIN CATCH
        -- Error handling
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();
    END CATCH;
END;

GO

