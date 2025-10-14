
CREATE   PROCEDURE [ui].[NEWGetBayRulesByReportID]
    @ReportID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate Input
        IF @ReportID IS NULL OR @ReportID <= 0
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'Error: Invalid ReportID. It must be a positive integer.';
            RETURN;
        END

        -- Select Bay Rules
        SELECT 
            Granularity,
            Gran_Code,
            Group_Key,
            ApplyColumn,
            ValueToSet,
            Var_or_Col
        FROM 
            [dbo].[BayRules]
        WHERE 
            ReportID = @ReportID;

        -- Check if any data was returned
        IF @@ROWCOUNT = 0
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = 'No Rules found for the specified ReportID.';
        END
        ELSE
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = 'Success: Rules retrieved successfully.';
        END
    END TRY
    BEGIN CATCH
        -- Handle Errors
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT('Error: ', ERROR_MESSAGE());
    END CATCH;
END

GO

