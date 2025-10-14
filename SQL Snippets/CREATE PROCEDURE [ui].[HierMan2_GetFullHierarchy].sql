SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_GetFullHierarchy]
    @HierarchyVersion_ID        INT              = NULL,       -- required: which version to load
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
    -- Get counts for informational message
    ------------------------------------------------------------
    DECLARE @H1Count INT = 0, @H2Count INT = 0, @H3Count INT = 0;
    
    SELECT @H1Count = COUNT(*) FROM dbo.Hierarchy1 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
    SELECT @H2Count = COUNT(*) FROM dbo.Hierarchy2 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;
    SELECT @H3Count = COUNT(*) FROM dbo.Hierarchy3 WHERE HierarchyVersion_ID = @HierarchyVersion_ID;

    ------------------------------------------------------------
    -- Return all hierarchy data in separate result sets
    ------------------------------------------------------------
    BEGIN TRY
        
        -- Result Set 1: Hierarchy1 data
        SELECT 
            Hierarchy1_ID,
            HierarchyVersion_ID,
            Hierarchy1_Code,
            Hierarchy1_Name,
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
        FROM dbo.Hierarchy1 
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
        ORDER BY Hierarchy1_Code;

        -- Result Set 2: Hierarchy2 data
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
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
        ORDER BY ParentHierarchy_ID, Hierarchy2_Code;

        -- Result Set 3: Hierarchy3 data
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
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
        ORDER BY ParentHierarchy_ID, FlowNumber, Hierarchy3_Code;

        -- Success message with data summary
        SET @SQL_Success = 1;
        SET @SQL_Message = N'Full hierarchy loaded for version ''' + @VersionName + N'''. ' +
                          N'Records: ' + CAST(@H1Count AS NVARCHAR(10)) + N' H1, ' +
                          CAST(@H2Count AS NVARCHAR(10)) + N' H2, ' +
                          CAST(@H3Count AS NVARCHAR(10)) + N' H3 items.';

    END TRY
    BEGIN CATCH
        -- Return error details
        SET @SQL_Success = 0;
        SET @SQL_Message = N'Error loading hierarchy data for version ''' + COALESCE(@VersionName, 'Unknown') + N''': ' + ERROR_MESSAGE();
        
        -- Log error details for troubleshooting
        DECLARE @ErrorDetails NVARCHAR(4000);
        SET @ErrorDetails = N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + 
                           N' at Line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + 
                           N': ' + ERROR_MESSAGE();
        
        PRINT @ErrorDetails;
        
    END CATCH;
END;
GO