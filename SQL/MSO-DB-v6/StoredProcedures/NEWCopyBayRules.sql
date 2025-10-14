
CREATE   PROCEDURE [ui].[NEWCopyBayRules]
    @SourceReportID INT,
    @DestReportID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Insert rows into dbo.BayRules by selecting rows with SourceReportID and setting ReportID to DestReportID
        INSERT INTO dbo.BayRules (ReportID, Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
        SELECT 
            @DestReportID, -- Setting ReportID to DestReportID
            Granularity, 
            Gran_Code, 
            ApplyColumn, 
            ValueToSet, 
            Var_or_Col, 
            Group_Key
        FROM 
            dbo.BayRules 
        WHERE 
            ReportID = @SourceReportID 
            AND Group_Key IN ('Drivers', 'Metrics', 'Rounding', 'Resize');

        -- Set success output parameters
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Success: BayRules copied from SourceReportID to DestReportID.';
    END TRY
    BEGIN CATCH
        -- Handle errors and set failure output parameters
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT('Error: ', ERROR_MESSAGE());
    END CATCH;
END

GO

