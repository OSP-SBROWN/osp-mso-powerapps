SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_GetH2Details]
    @HierarchyVersion_ID        INT              = NULL,       -- required: which version
    @Hierarchy2_ID              INT              = NULL,       -- required: which H2 item
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

    IF @Hierarchy2_ID IS NULL OR @Hierarchy2_ID <= 0
    BEGIN
        SET @SQL_Message = N'Hierarchy2_ID is required and must be greater than 0.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Check if version exists
    ------------------------------------------------------------
    DECLARE @VersionName NVARCHAR(255);
    
    SELECT @VersionName = Name
    FROM dbo.HierarchyVersions 
    WHERE ID = @HierarchyVersion_ID;

    IF @VersionName IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy version with ID ' + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N' not found.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Get H2 details
    ------------------------------------------------------------
    BEGIN TRY
        
        -- Check if H2 item exists in this version
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Hierarchy2 
            WHERE Hierarchy2_ID = @Hierarchy2_ID 
              AND HierarchyVersion_ID = @HierarchyVersion_ID
        )
        BEGIN
            SET @SQL_Message = N'H2 item with ID ' + CAST(@Hierarchy2_ID AS NVARCHAR(10)) + 
                              N' not found in version ''' + @VersionName + N'''.';
            RETURN;
        END;

        -- Return H2 details
        SELECT 
            Hierarchy2_ID,
            HierarchyVersion_ID,
            ParentHierarchy_ID,
            Hierarchy2_Code,
            Hierarchy2_Name,
            Trend,
            MinBays,
            MaxBays,
            DOS,
            COS,
            Exclude_From_Analysis,
            BayRoundingThreshold,
            Metric1,
            Metric2,
            Metric3,
            Metric4,
            Driver1,
            Driver2,
            Driver3,
            Driver4
        FROM dbo.Hierarchy2 
        WHERE Hierarchy2_ID = @Hierarchy2_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        -- Success message
        SET @SQL_Success = 1;
        SET @SQL_Message = N'H2 details loaded successfully for version ''' + @VersionName + N'''.';

    END TRY
    BEGIN CATCH
        -- Return error details
        SET @SQL_Success = 0;
        SET @SQL_Message = N'Error loading H2 details: ' + ERROR_MESSAGE();
        
    END CATCH;
END;
GO