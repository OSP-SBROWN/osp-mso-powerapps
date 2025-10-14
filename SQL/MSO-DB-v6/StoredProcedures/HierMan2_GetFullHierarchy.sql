
CREATE  PROCEDURE [ui].[HierMan2_GetFullHierarchy]
    @SQL_Success  BIT OUTPUT,
    @SQL_Message  NVARCHAR(4000) OUTPUT,   -- more room than 255
    @Hier_Version INT
AS
BEGIN
    SET NOCOUNT ON;

    -- defaults
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    -- basic validation
    IF @Hier_Version IS NULL OR @Hier_Version <= 0
    BEGIN
        SET @SQL_Message = N'@Hier_Version must be a positive INT.';
        RETURN;
    END;

    BEGIN TRY
        DECLARE
            @c_detail INT = 0,
            @c_h1     INT = 0,
            @c_h2     INT = 0,
            @c_h3     INT = 0;

        /* =========================================
           1) Full hierarchy (Result set #1)
           ========================================= */
        SELECT
            hd.Hierarchy1_Code,
            hd.Hierarchy1_Name,
            hd.Hierarchy2_Code,
            hd.Hierarchy2_Name,
            hd.Hierarchy3_Code,
            hd.Hierarchy3_Name,
            hd.Trend,
            hd.MinBays,
            hd.MaxBays,
            hd.Exclude_From_Analysis,
            hd.FlowNumber
        FROM dbo.HierarchyDetail AS hd
        WHERE hd.HierarchyVersion_ID = @Hier_Version
        ORDER BY hd.FlowNumber ASC, hd.Hierarchy3_Code;
        SET @c_detail = @@ROWCOUNT;

        /* =========================================
           2) Hierarchy1 with child counts (Result set #2)
           ========================================= */
        SELECT
            h1.Hierarchy1_ID,
            h1.Hierarchy1_Code,
            h1.Hierarchy1_Name,
            h1.Trend,
            h1.MinBays,
            h1.MaxBays,
            h1.DOS AS DaysOnSite,
            h1.COS AS CapacityOnSite,
            h1.Exclude_From_Analysis AS Exclude,
            h1.BayRoundingThreshold,
            h1.Metric1 AS Metric1_Pct,
            h1.Metric2 AS Metric2_Pct,
            h1.Metric3 AS Metric3_Pct,
            h1.Metric4 AS Metric4_Pct,
            h1.Driver1 AS Driver1_Pct,
            h1.Driver2 AS Driver2_Pct,
            h1.Driver3 AS Driver3_Pct,
            h1.Driver4 AS Driver4_Pct,
            h1.HierarchyVersion_ID,
            COUNT(DISTINCT h2.Hierarchy2_ID) AS Child_H2,
            COUNT(DISTINCT h3.Hierarchy3_ID) AS Child_H3
        FROM dbo.Hierarchy1 AS h1
        LEFT JOIN dbo.Hierarchy2 AS h2 ON h2.ParentHierarchy_ID = h1.Hierarchy1_ID
        LEFT JOIN dbo.Hierarchy3 AS h3 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
        WHERE h1.HierarchyVersion_ID = @Hier_Version
        GROUP BY h1.Hierarchy1_ID, h1.Hierarchy1_Code, h1.Hierarchy1_Name, h1.Trend, h1.MinBays, h1.MaxBays, 
                 h1.DOS, h1.COS, h1.Exclude_From_Analysis, h1.BayRoundingThreshold,
                 h1.Metric1, h1.Metric2, h1.Metric3, h1.Metric4,
                 h1.Driver1, h1.Driver2, h1.Driver3, h1.Driver4, h1.HierarchyVersion_ID
        ORDER BY h1.Hierarchy1_Code;
        SET @c_h1 = @@ROWCOUNT;

        /* =========================================
           3) Hierarchy2 with all fields (Result set #3)
           ========================================= */
        SELECT
            h2.Hierarchy2_ID,
            h2.Hierarchy2_Code,
            h2.Hierarchy2_Name,
            h2.Trend,
            h2.MinBays,
            h2.MaxBays,
            h2.DOS AS DaysOnSite,
            h2.COS AS CapacityOnSite,
            h2.Exclude_From_Analysis AS Exclude,
            h2.BayRoundingThreshold,
            h2.Metric1 AS Metric1_Pct,
            h2.Metric2 AS Metric2_Pct,
            h2.Metric3 AS Metric3_Pct,
            h2.Metric4 AS Metric4_Pct,
            h2.Driver1 AS Driver1_Pct,
            h2.Driver2 AS Driver2_Pct,
            h2.Driver3 AS Driver3_Pct,
            h2.Driver4 AS Driver4_Pct,
            h2.ParentHierarchy_ID,
            h2.HierarchyVersion_ID,
            COUNT(DISTINCT h3.Hierarchy3_ID) AS Child_H3
        FROM dbo.Hierarchy2 AS h2
        LEFT JOIN dbo.Hierarchy3 AS h3 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
        WHERE h2.HierarchyVersion_ID = @Hier_Version
        GROUP BY h2.Hierarchy2_ID, h2.Hierarchy2_Code, h2.Hierarchy2_Name, h2.Trend, h2.MinBays, h2.MaxBays,
                 h2.DOS, h2.COS, h2.Exclude_From_Analysis, h2.BayRoundingThreshold,
                 h2.Metric1, h2.Metric2, h2.Metric3, h2.Metric4,
                 h2.Driver1, h2.Driver2, h2.Driver3, h2.Driver4,
                 h2.ParentHierarchy_ID, h2.HierarchyVersion_ID
        ORDER BY h2.ParentHierarchy_ID, h2.Hierarchy2_Code;
        SET @c_h2 = @@ROWCOUNT;

        /* =========================================
           4) Hierarchy3 table (Result set #4)
           ========================================= */
        SELECT
            h3.Hierarchy3_ID,
            h3.Hierarchy3_Code,
            h3.Hierarchy3_Name,
            h3.ParentHierarchy_ID,
            h3.Trend,
            h3.MinBays,
            h3.MaxBays,
            h3.DOS AS DaysOnSite,
            h3.COS AS CapacityOnSite,
            h3.Exclude_From_Analysis AS Exclude,
            h3.FlowNumber,
            h3.BayRoundingThreshold,
            h3.Metric1 AS Metric1_Pct,
            h3.Metric2 AS Metric2_Pct,
            h3.Metric3 AS Metric3_Pct,
            h3.Metric4 AS Metric4_Pct,
            h3.Driver1 AS Driver1_Pct,
            h3.Driver2 AS Driver2_Pct,
            h3.Driver3 AS Driver3_Pct,
            h3.Driver4 AS Driver4_Pct,
            h3.HierarchyVersion_ID
        FROM dbo.Hierarchy3 AS h3
        WHERE h3.HierarchyVersion_ID = @Hier_Version
        ORDER BY h3.FlowNumber ASC, h3.Hierarchy3_Code;
        SET @c_h3 = @@ROWCOUNT;

        -- success summary
        SET @SQL_Success = 1;
        SET @SQL_Message = CONCAT(
            N'OK (Version ', @Hier_Version, N'). ',
            N'HierarchyDetail=', @c_detail, N'; ',
            N'H1_Child=', @c_h1, N'; ',
            N'H2_Child=', @c_h2, N'; ',
            N'H3=', @c_h3, N'.'
        );
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrNum  INT = ERROR_NUMBER(),
            @ErrLine INT = ERROR_LINE(),
            @ErrProc NVARCHAR(128) = ERROR_PROCEDURE(),
            @ErrMsg  NVARCHAR(2048) = ERROR_MESSAGE();

        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            N'Error ', @ErrNum, N' in ', ISNULL(@ErrProc, N'[procedure]'),
            N' at line ', @ErrLine, N': ', @ErrMsg
        );
        -- Optional: rethrow if you want the client to receive an error
        -- THROW;
    END CATCH;
END

GO

