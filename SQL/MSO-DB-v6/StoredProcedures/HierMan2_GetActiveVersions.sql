CREATE   PROCEDURE [ui].[HierMan2_GetActiveVersions]
    @SQL_Success INT OUTPUT,
    @SQL_Message NVARCHAR(MAX) OUTPUT
AS
BEGIN
    -- Prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;
    
    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = '';
    
    BEGIN TRY
        -- Check if the table exists first (optional defensive programming)
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HierarchyVersion')
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'Error: Table HierarchyVersion does not exist.';
            RETURN -1;
        END
        
        -- Main query to get active versions
        SELECT 
            HierarchyVersion_ID AS [ID], 
            HierarchyVersion_Name AS [Name]
        FROM 
            dbo.HierarchyVersion 
        WHERE 
            HierarchyVersion_Status = 'Active'
        ORDER BY 
            HierarchyVersionCreatedDate DESC; -- Optional: Add ordering for consistent results
        
        -- Get row count for feedback
        DECLARE @RowCount INT = @@ROWCOUNT;
        
        -- Set success parameters
        SET @SQL_Success = 1;
        SET @SQL_Message = CONCAT('Successfully retrieved ', @RowCount, ' active hierarchy version(s).');
        
        -- Return success code
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Capture error information
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        
        -- Set failure parameters
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            'Error ', @ErrorNumber, 
            ' in procedure ', ISNULL(@ErrorProcedure, 'HierMan2_GetActiveVersions'),
            ' at line ', @ErrorLine,
            ': ', @ErrorMessage
        );
        
        
        -- Return error code
        RETURN -1;
        
    END CATCH
END;

GO

