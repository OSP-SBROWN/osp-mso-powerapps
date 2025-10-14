SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_DeleteH1]
    @Hierarchy1_ID            INT,
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
    IF @Hierarchy1_ID IS NULL OR @Hierarchy1_ID <= 0
    BEGIN
        SET @SQL_Message = N'Hierarchy1_ID must be a positive INT.';
        RETURN;
    END;

    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID must be a positive INT.';
        RETURN;
    END;

    -- Check if H1 record exists
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Hierarchy1
        WHERE Hierarchy1_ID = @Hierarchy1_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'No H1 record found for ID=' + CAST(@Hierarchy1_ID AS NVARCHAR(20)) + N' in version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Get counts for informational message
    ------------------------------------------------------------
    DECLARE @H2Count INT = 0, @H3Count INT = 0;
    DECLARE @H1Name NVARCHAR(255), @H1Code INT;
    
    SELECT 
        @H1Name = Hierarchy1_Name,
        @H1Code = Hierarchy1_Code
    FROM dbo.Hierarchy1 
    WHERE Hierarchy1_ID = @Hierarchy1_ID 
      AND HierarchyVersion_ID = @HierarchyVersion_ID;
    
    -- Count H2 children
    SELECT @H2Count = COUNT(*)
    FROM dbo.Hierarchy2 
    WHERE ParentHierarchy_ID = @Hierarchy1_ID 
      AND HierarchyVersion_ID = @HierarchyVersion_ID;
    
    -- Count H3 grandchildren (through H2 children)
    SELECT @H3Count = COUNT(*)
    FROM dbo.Hierarchy3 h3
    INNER JOIN dbo.Hierarchy2 h2 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
    WHERE h2.ParentHierarchy_ID = @Hierarchy1_ID 
      AND h2.HierarchyVersion_ID = @HierarchyVersion_ID
      AND h3.HierarchyVersion_ID = @HierarchyVersion_ID;

    ------------------------------------------------------------
    -- Cascade Delete: H3 → H2 → H1
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        -- 1. Delete H3 records (grandchildren through H2 children)
        DELETE h3
        FROM dbo.Hierarchy3 h3
        INNER JOIN dbo.Hierarchy2 h2 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
        WHERE h2.ParentHierarchy_ID = @Hierarchy1_ID 
          AND h2.HierarchyVersion_ID = @HierarchyVersion_ID
          AND h3.HierarchyVersion_ID = @HierarchyVersion_ID;

        -- 2. Delete H2 records (direct children)
        DELETE FROM dbo.Hierarchy2 
        WHERE ParentHierarchy_ID = @Hierarchy1_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        -- 3. Delete H1 record itself
        DELETE FROM dbo.Hierarchy1 
        WHERE Hierarchy1_ID = @Hierarchy1_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message = 
            N'H1 record deleted successfully. '
          + N'H1="' + ISNULL(@H1Name, N'<NULL>') + N'" (Code=' + CAST(ISNULL(@H1Code, -1) AS NVARCHAR(20)) + N') '
          + N'and all children: ' + CAST(@H2Count AS NVARCHAR(10)) + N' H2 records, '
          + CAST(@H3Count AS NVARCHAR(10)) + N' H3 records removed.';

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