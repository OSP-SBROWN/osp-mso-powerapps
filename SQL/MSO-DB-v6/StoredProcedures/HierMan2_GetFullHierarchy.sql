
CREATE   PROCEDURE [ui].[HierMan2_GetFullHierarchy]
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
           2) Hierarchy1_Child view (Result set #2)
           ========================================= */
        SELECT
            h1c.Hierarchy1_ID,
            h1c.Hierarchy1_Code,
            h1c.Hierarchy1_Name,
            h1c.Child_H2,
            h1c.Child_H3,
            h1c.HierarchyVersion_ID
        FROM dbo.Hierarchy1_Child AS h1c
        WHERE h1c.HierarchyVersion_ID = @Hier_Version
        ORDER BY h1c.Hierarchy1_Code;
        SET @c_h1 = @@ROWCOUNT;

        /* =========================================
           3) Hierarchy2_Child view (Result set #3)
           ========================================= */
        SELECT
            h2c.Hierarchy2_ID,
            h2c.Hierarchy2_Code,
            h2c.Hierarchy2_Name,
            h2c.ParentHierarchy_ID,
            h2c.Child_H3,
            h2c.HierarchyVersion_ID
        FROM dbo.Hierarchy2_Child AS h2c
        WHERE h2c.HierarchyVersion_ID = @Hier_Version
        ORDER BY h2c.ParentHierarchy_ID, h2c.Hierarchy2_Code;
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
            h3.DOS,
            h3.COS,
            h3.Exclude_From_Analysis,
            h3.FlowNumber,
            h3.BayRoundingThreshold,
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

