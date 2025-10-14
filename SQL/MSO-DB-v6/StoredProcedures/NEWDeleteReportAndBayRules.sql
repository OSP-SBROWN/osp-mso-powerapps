
CREATE   PROCEDURE [ui].[NEWDeleteReportAndBayRules]
    @ReportID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- DECLARE @BackupTableName SYSNAME;
    -- -- For example, T_ReportVersionAttributes_20250402123045
    -- SET @BackupTableName = 'T_ReportVersionAttributes_' 
    --     + CONVERT(VARCHAR(8), GETDATE(), 112)  -- YYYYMMDD
    --     + '_'
    --     + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');  -- HHMMSS

    -- DECLARE @SQLString NVARCHAR(MAX) = 
    --     N'SELECT * INTO ' + QUOTENAME(@BackupTableName)
    --     + N' FROM ReportVersionAttributes;';

    -- EXEC sp_executesql @SQLString;

    DECLARE @BackupColumnName VARCHAR(50);
    SET @BackupColumnName = CONVERT(VARCHAR(8), GETDATE(), 112)  + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');

    INSERT INTO Rva_Archive SELECT @BackupColumnName, * FROM ReportVersionAttributes WHERE ReportID = @ReportID;

    BEGIN TRY
        DELETE FROM ReportVersionAttributes WHERE ReportID=@ReportID;
        DELETE FROM MSO_Reports WHERE ReportID=@ReportID;
        DELETE FROM MSO_Products WHERE ReportID=@ReportID;
        DELETE FROM BayRules WHERE ReportID=@ReportID;
        -- Set success output parameters
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Success: Report Deleted';
    END TRY
    BEGIN CATCH
        -- Handle errors and set failure output parameters
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT('Error: ', ERROR_MESSAGE());
    END CATCH;
END

GO

