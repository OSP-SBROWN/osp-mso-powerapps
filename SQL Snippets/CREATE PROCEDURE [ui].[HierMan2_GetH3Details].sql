SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_GetH3Details]
    @HierarchyVersion_ID        INT              = NULL,       -- required: which version
    @Hierarchy3_ID              INT              = NULL,       -- required: which H3 item
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

    IF @Hierarchy3_ID IS NULL OR @Hierarchy3_ID <= 0
    BEGIN
        SET @SQL_Message = N'Hierarchy3_ID is required and must be greater than 0.';
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
    -- Get H3 details
    ------------------------------------------------------------
    BEGIN TRY
        
        -- Check if H3 item exists in this version
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Hierarchy3 
            WHERE Hierarchy3_ID = @Hierarchy3_ID 
              AND HierarchyVersion_ID = @HierarchyVersion_ID
        )
        BEGIN
            SET @SQL_Message = N'H3 item with ID ' + CAST(@Hierarchy3_ID AS NVARCHAR(10)) + 
                              N' not found in version ''' + @VersionName + N'''.';
            RETURN;
        END;

        -- Return H3 details
        SELECT 
            Hierarchy3_ID,
            HierarchyVersion_ID,
            ParentHierarchy_ID,
            Hierarchy3_Code,
            Hierarchy3_Name,
            Trend,
            MinBays,
            MaxBays,
            DOS,
            COS,
            Exclude_From_Analysis,
            FlowNumber,
            BayRoundingThreshold,
            Metric1,
            Metric2,
            Metric3,
            Metric4,
            Driver1,
            Driver2,
            Driver3,
            Driver4
        FROM dbo.Hierarchy3 
        WHERE Hierarchy3_ID = @Hierarchy3_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        -- Success message
        SET @SQL_Success = 1;
        SET @SQL_Message = N'H3 details loaded successfully for version ''' + @VersionName + N'''.';

    END TRY
    BEGIN CATCH
        -- Return error details
        SET @SQL_Success = 0;
        SET @SQL_Message = N'Error loading H3 details: ' + ERROR_MESSAGE();
        
    END CATCH;
END;
GO