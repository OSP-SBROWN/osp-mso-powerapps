SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_DeleteHierarchyVersion]
    @HierarchyVersion_ID        INT              = NULL,       -- required: version to delete
    @SQL_Success                BIT              OUTPUT,
    @SQL_Message                NVARCHAR(4000)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- auto-rollback on error

    -- init outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    ------------------------------------------------------------
    -- Basic validation
    ------------------------------------------------------------
    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID is required and must be greater than 0.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Check if version exists
    ------------------------------------------------------------
    DECLARE @VersionName NVARCHAR(255);
    DECLARE @VersionStatus NVARCHAR(50);
    
    SELECT @VersionName = Name, @VersionStatus = Status
    FROM dbo.HierarchyVersions 
    WHERE ID = @HierarchyVersion_ID;

    IF @VersionName IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy version with ID ' + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N' not found.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Prevent deletion of Active versions (business rule)
    ------------------------------------------------------------
    IF @VersionStatus = N'Active'
    BEGIN
        SET @SQL_Message = N'Cannot delete Active hierarchy version ''' + @VersionName + N'''. Please change status to Draft or Archived first.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Check for child records count (for informational message)
    ------------------------------------------------------------
    DECLARE @H1Count INT = 0, @H2Count INT = 0, @H3Count INT = 0;
    
    SELECT @H1Count = COUNT(*) FROM dbo.Hierarchy1 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
    SELECT @H2Count = COUNT(*) FROM dbo.Hierarchy2 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
    SELECT @H3Count = COUNT(*) FROM dbo.Hierarchy3 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;

    ------------------------------------------------------------
    -- Delete operation (cascade from parent to children)
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Delete in proper order: H3 -> H2 -> H1 -> HierarchyVersions
        -- This ensures referential integrity
        
        DELETE FROM dbo.Hierarchy3 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
        DELETE FROM dbo.Hierarchy2 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;  
        DELETE FROM dbo.Hierarchy1 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
        DELETE FROM dbo.HierarchyVersions WHERE ID = @HierarchyVersion_ID;

        COMMIT TRANSACTION;

        -- Success message with deletion summary
        SET @SQL_Success = 1;
        SET @SQL_Message = N'Hierarchy version ''' + @VersionName + N''' deleted successfully. ' +
                          N'Removed: ' + CAST(@H1Count AS NVARCHAR(10)) + N' H1 items, ' +
                          CAST(@H2Count AS NVARCHAR(10)) + N' H2 items, ' +
                          CAST(@H3Count AS NVARCHAR(10)) + N' H3 items.';

    END TRY
    BEGIN CATCH
        -- Rollback transaction on error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Return error details
        SET @SQL_Success = 0;
        SET @SQL_Message = N'Error deleting hierarchy version ''' + @VersionName + N''': ' + ERROR_MESSAGE();
        
        -- Log error details for troubleshooting
        DECLARE @ErrorDetails NVARCHAR(4000);
        SET @ErrorDetails = N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + 
                           N' at Line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + 
                           N': ' + ERROR_MESSAGE();
        
        -- Could log to error table here if needed
        PRINT @ErrorDetails;
        
    END CATCH;
END;
GO