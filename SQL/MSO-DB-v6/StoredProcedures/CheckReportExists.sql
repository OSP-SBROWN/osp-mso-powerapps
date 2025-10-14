CREATE   PROCEDURE [ui].[CheckReportExists]
    @ReportID INT,
    @ReportFound BIT OUTPUT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Check if the ReportID exists in the MSO_Reports table
        IF EXISTS (SELECT 1 FROM MSO_Reports WHERE ReportID = @ReportID)
        BEGIN
            SET @ReportFound = 1; -- Report exists
            SET @SQL_Success = 1; -- Success
            SET @SQL_Message = 'Report found in the MSO_Reports table.';
        END
        ELSE
        BEGIN
            SET @ReportFound = 0; -- Report does not exist
            SET @SQL_Success = 1; -- Success
            SET @SQL_Message = 'Report not found in the MSO_Reports table.';
        END
    END TRY
    BEGIN CATCH
        -- Handle any errors that occur
        SET @ReportFound = 0; -- Default to false in case of errors
        SET @SQL_Success = 0; -- Failure
        SET @SQL_Message = ERROR_MESSAGE(); -- Capture the error message
        THROW; -- Re-throw the error to handle it outside the procedure if necessary
    END CATCH
END

GO

