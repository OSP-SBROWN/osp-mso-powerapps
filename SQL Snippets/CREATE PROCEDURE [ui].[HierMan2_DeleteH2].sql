SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_DeleteH2]
    @Hierarchy2_ID            INT,
    @HierarchyVersion_ID      INT,
    @SQL_Success              BIT             OUTPUT,
    @SQL_Message              NVARCHAR(4000)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- init outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------
    IF @Hierarchy2_ID IS NULL OR @Hierarchy2_ID <= 0
    BEGIN
        SET @SQL_Message = N'Hierarchy2_ID must be a positive INT.';
        RETURN;
    END;

    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID must be a positive INT.';
        RETURN;
    END;

    -- Check if H2 record exists
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Hierarchy2
        WHERE Hierarchy2_ID = @Hierarchy2_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'No H2 record found for ID=' + CAST(@Hierarchy2_ID AS NVARCHAR(20)) + N' in version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Get counts for informational message
    ------------------------------------------------------------
    DECLARE @H3Count INT = 0;
    DECLARE @H2Name NVARCHAR(255), @H2Code INT;
    
    SELECT 
        @H2Name = Hierarchy2_Name,
        @H2Code = Hierarchy2_Code
    FROM dbo.Hierarchy2 
    WHERE Hierarchy2_ID = @Hierarchy2_ID 
      AND HierarchyVersion_ID = @HierarchyVersion_ID;
    
    -- Count H3 children
    SELECT @H3Count = COUNT(*)
    FROM dbo.Hierarchy3 
    WHERE ParentHierarchy_ID = @Hierarchy2_ID 
      AND HierarchyVersion_ID = @HierarchyVersion_ID;

    ------------------------------------------------------------
    -- Cascade Delete: H3 → H2
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        -- 1. Delete H3 records (direct children)
        DELETE FROM dbo.Hierarchy3 
        WHERE ParentHierarchy_ID = @Hierarchy2_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        -- 2. Delete H2 record itself
        DELETE FROM dbo.Hierarchy2 
        WHERE Hierarchy2_ID = @Hierarchy2_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message = 
            N'H2 record deleted successfully. '
          + N'H2="' + ISNULL(@H2Name, N'<NULL>') + N'" (Code=' + CAST(ISNULL(@H2Code, -1) AS NVARCHAR(20)) + N') '
          + N'and all children: ' + CAST(@H3Count AS NVARCHAR(10)) + N' H3 records removed.';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        SET @SQL_Success = 0;
        SET @SQL_Message =
            N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
          + N' in ' + ISNULL(ERROR_PROCEDURE(), N'<unknown>')
          + N' at line ' + CAST(ERROR_LINE() AS NVARCHAR(10))
          + N': ' + ERROR_MESSAGE();
    END CATCH

END

GO