SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [ui].[HierMan2_CreateHierarchyVersion]
    @VersionName                 NVARCHAR(255)    = NULL,      -- required
    @VersionStatus              NVARCHAR(50)     = 'Draft',    -- default to Draft
    @CreatedBy                  NVARCHAR(255)    = NULL,       -- user email
    @DuplicateFromExisting_ID   INT              = NULL,       -- 0 or NULL = empty, >0 = duplicate from
    @NewHierarchyVersion_ID     INT              OUTPUT,       -- Match donor app naming
    @SQL_Success                BIT              OUTPUT,
    @SQL_Message                NVARCHAR(4000)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- auto-rollback on error

    -- init outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';
    SET @NewHierarchyVersion_ID = NULL;

    DECLARE @CopiedCounts NVARCHAR(200) = N'';

    ------------------------------------------------------------
    -- Basic validation + normalization
    ------------------------------------------------------------
    SET @VersionName = NULLIF(LTRIM(RTRIM(@VersionName)), N'');
    SET @VersionStatus = COALESCE(NULLIF(LTRIM(RTRIM(@VersionStatus)), N''), N'Draft');
    SET @CreatedBy = NULLIF(LTRIM(RTRIM(@CreatedBy)), N'');

    IF @VersionName IS NULL
    BEGIN
        SET @SQL_Message = N'VersionName is required.';
        RETURN;
    END;

    -- Validate status
    IF @VersionStatus NOT IN (N'Draft', N'Active', N'Archived')
    BEGIN
        SET @SQL_Message = N'VersionStatus must be ''Draft'', ''Active'', or ''Archived''.';
        RETURN;
    END;

    -- Check for duplicate name
    IF EXISTS (
        SELECT 1
        FROM dbo.HierarchyVersion 
        WHERE HierarchyVersion_Name = @VersionName
    )
    BEGIN
        SET @SQL_Message = N'A hierarchy version with name "' + @VersionName + N'" already exists.';
        RETURN;
    END;

    -- Validate duplicate source if specified
    IF @DuplicateFromExisting_ID IS NOT NULL AND @DuplicateFromExisting_ID > 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.HierarchyVersion 
            WHERE HierarchyVersion_ID = @DuplicateFromExisting_ID
        )
        BEGIN
            SET @SQL_Message = N'Source hierarchy version (ID=' + CAST(@DuplicateFromExisting_ID AS NVARCHAR(10)) + N') does not exist.';
            RETURN;
        END;
    END;

    ------------------------------------------------------------
    -- Create new hierarchy version
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        -- Insert the new hierarchy version
        INSERT INTO dbo.HierarchyVersion
        (
            HierarchyVersion_Name,
            HierarchyVersion_Status,
            HierarchyVersion_CreatedBy,
            HierarchyVersionCreatedDate
        )
        VALUES
        (
            @VersionName,
            @VersionStatus,
            @CreatedBy,
            GETDATE()
        );

        SET @NewHierarchyVersion_ID = CONVERT(INT, SCOPE_IDENTITY());

        -- If duplicating from existing version, copy all hierarchy data
        IF @DuplicateFromExisting_ID IS NOT NULL AND @DuplicateFromExisting_ID > 0
        BEGIN
            DECLARE @H1_Mapping TABLE (
                OldH1_ID INT,
                NewH1_ID INT,
                OldH1_Code INT
            );

            DECLARE @H2_Mapping TABLE (
                OldH2_ID INT,
                NewH2_ID INT,
                OldH2_Code INT
            );

            DECLARE @NextH1_ID INT;
            DECLARE @NextH2_ID INT;
            DECLARE @NextH3_ID INT;
            DECLARE @CopiedH1Count INT = 0;
            DECLARE @CopiedH2Count INT = 0;
            DECLARE @CopiedH3Count INT = 0;

            SELECT @NextH1_ID = ISNULL(MAX(Hierarchy1_ID), 0) + 1 FROM dbo.Hierarchy1;

            DECLARE @H1_Source TABLE (
                OldH1_ID INT,
                NewH1_ID INT,
                Hierarchy1_Code INT,
                Hierarchy1_Name NVARCHAR(255),
                Trend DECIMAL(5,3),
                MinBays DECIMAL(5,1),
                MaxBays DECIMAL(5,1),
                DOS DECIMAL(5,1),
                COS DECIMAL(5,1),
                Exclude_From_Analysis VARCHAR(1),
                BayRoundingThreshold DECIMAL(5,1),
                Metric1 INT,
                Metric2 INT,
                Metric3 INT,
                Metric4 INT,
                Driver1 INT,
                Driver2 INT,
                Driver3 INT,
                Driver4 INT
            );

            WITH SourceH1 AS (
                SELECT 
                    h1.Hierarchy1_ID AS OldH1_ID,
                    h1.Hierarchy1_Code,
                    h1.Hierarchy1_Name,
                    h1.Trend,
                    h1.MinBays,
                    h1.MaxBays,
                    h1.DOS,
                    h1.COS,
                    h1.Exclude_From_Analysis,
                    h1.BayRoundingThreshold,
                    h1.Metric1,
                    h1.Metric2,
                    h1.Metric3,
                    h1.Metric4,
                    h1.Driver1,
                    h1.Driver2,
                    h1.Driver3,
                    h1.Driver4,
                    ROW_NUMBER() OVER (ORDER BY h1.Hierarchy1_ID) - 1 AS RowNum
                FROM dbo.Hierarchy1 h1
                WHERE h1.HierarchyVersion_ID = @DuplicateFromExisting_ID
            )
            INSERT INTO @H1_Source
            (
                OldH1_ID,
                NewH1_ID,
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
            )
            SELECT
                SourceH1.OldH1_ID,
                @NextH1_ID + SourceH1.RowNum,
                SourceH1.Hierarchy1_Code,
                SourceH1.Hierarchy1_Name,
                SourceH1.Trend,
                SourceH1.MinBays,
                SourceH1.MaxBays,
                SourceH1.DOS,
                SourceH1.COS,
                SourceH1.Exclude_From_Analysis,
                SourceH1.BayRoundingThreshold,
                SourceH1.Metric1,
                SourceH1.Metric2,
                SourceH1.Metric3,
                SourceH1.Metric4,
                SourceH1.Driver1,
                SourceH1.Driver2,
                SourceH1.Driver3,
                SourceH1.Driver4
            FROM SourceH1;

            INSERT INTO dbo.Hierarchy1
            (
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
            )
            SELECT
                H1Source.NewH1_ID,
                @NewHierarchyVersion_ID,
                H1Source.Hierarchy1_Code,
                H1Source.Hierarchy1_Name,
                H1Source.Trend,
                H1Source.MinBays,
                H1Source.MaxBays,
                H1Source.DOS,
                H1Source.COS,
                H1Source.Exclude_From_Analysis,
                H1Source.BayRoundingThreshold,
                H1Source.Metric1,
                H1Source.Metric2,
                H1Source.Metric3,
                H1Source.Metric4,
                H1Source.Driver1,
                H1Source.Driver2,
                H1Source.Driver3,
                H1Source.Driver4
            FROM @H1_Source AS H1Source;

            INSERT INTO @H1_Mapping (OldH1_ID, NewH1_ID, OldH1_Code)
            SELECT OldH1_ID, NewH1_ID, Hierarchy1_Code
            FROM @H1_Source;

            SELECT @CopiedH1Count = COUNT(*) FROM @H1_Source;

            SELECT @NextH2_ID = ISNULL(MAX(Hierarchy2_ID), 0) + 1 FROM dbo.Hierarchy2;

            DECLARE @H2_Source TABLE (
                OldH2_ID INT,
                NewH2_ID INT,
                ParentOldH1_ID INT,
                Hierarchy2_Code INT,
                Hierarchy2_Name NVARCHAR(255),
                Trend DECIMAL(5,3),
                MinBays DECIMAL(5,1),
                MaxBays DECIMAL(5,1),
                DOS DECIMAL(5,1),
                COS DECIMAL(5,1),
                Exclude_From_Analysis VARCHAR(1),
                BayRoundingThreshold DECIMAL(5,1),
                Metric1 INT,
                Metric2 INT,
                Metric3 INT,
                Metric4 INT,
                Driver1 INT,
                Driver2 INT,
                Driver3 INT,
                Driver4 INT
            );

            WITH SourceH2 AS (
                SELECT 
                    h2.Hierarchy2_ID AS OldH2_ID,
                    h2.ParentHierarchy_ID,
                    h2.Hierarchy2_Code,
                    h2.Hierarchy2_Name,
                    h2.Trend,
                    h2.MinBays,
                    h2.MaxBays,
                    h2.DOS,
                    h2.COS,
                    h2.Exclude_From_Analysis,
                    h2.BayRoundingThreshold,
                    h2.Metric1,
                    h2.Metric2,
                    h2.Metric3,
                    h2.Metric4,
                    h2.Driver1,
                    h2.Driver2,
                    h2.Driver3,
                    h2.Driver4,
                    ROW_NUMBER() OVER (ORDER BY h2.Hierarchy2_ID) - 1 AS RowNum
                FROM dbo.Hierarchy2 h2
                WHERE h2.HierarchyVersion_ID = @DuplicateFromExisting_ID
            )
            INSERT INTO @H2_Source
            (
                OldH2_ID,
                NewH2_ID,
                ParentOldH1_ID,
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
            )
            SELECT
                SourceH2.OldH2_ID,
                @NextH2_ID + SourceH2.RowNum,
                SourceH2.ParentHierarchy_ID,
                SourceH2.Hierarchy2_Code,
                SourceH2.Hierarchy2_Name,
                SourceH2.Trend,
                SourceH2.MinBays,
                SourceH2.MaxBays,
                SourceH2.DOS,
                SourceH2.COS,
                SourceH2.Exclude_From_Analysis,
                SourceH2.BayRoundingThreshold,
                SourceH2.Metric1,
                SourceH2.Metric2,
                SourceH2.Metric3,
                SourceH2.Metric4,
                SourceH2.Driver1,
                SourceH2.Driver2,
                SourceH2.Driver3,
                SourceH2.Driver4
            FROM SourceH2;

            INSERT INTO dbo.Hierarchy2
            (
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
            )
            SELECT
                H2Source.NewH2_ID,
                @NewHierarchyVersion_ID,
                h1_map.NewH1_ID,
                H2Source.Hierarchy2_Code,
                H2Source.Hierarchy2_Name,
                H2Source.Trend,
                H2Source.MinBays,
                H2Source.MaxBays,
                H2Source.DOS,
                H2Source.COS,
                H2Source.Exclude_From_Analysis,
                H2Source.BayRoundingThreshold,
                H2Source.Metric1,
                H2Source.Metric2,
                H2Source.Metric3,
                H2Source.Metric4,
                H2Source.Driver1,
                H2Source.Driver2,
                H2Source.Driver3,
                H2Source.Driver4
            FROM @H2_Source AS H2Source
            INNER JOIN @H1_Mapping h1_map ON H2Source.ParentOldH1_ID = h1_map.OldH1_ID;

            INSERT INTO @H2_Mapping (OldH2_ID, NewH2_ID, OldH2_Code)
            SELECT OldH2_ID, NewH2_ID, Hierarchy2_Code
            FROM @H2_Source;

            SELECT @CopiedH2Count = COUNT(*) FROM @H2_Source;

            SELECT @NextH3_ID = ISNULL(MAX(Hierarchy3_ID), 0) + 1 FROM dbo.Hierarchy3;

            DECLARE @H3_Source TABLE (
                OldH3_ID INT,
                NewH3_ID INT,
                ParentOldH2_ID INT,
                Hierarchy3_Code INT,
                Hierarchy3_Name NVARCHAR(255),
                Trend DECIMAL(5,3),
                MinBays DECIMAL(5,1),
                MaxBays DECIMAL(5,1),
                DOS DECIMAL(5,1),
                COS DECIMAL(5,1),
                Exclude_From_Analysis VARCHAR(1),
                FlowNumber INT,
                BayRoundingThreshold DECIMAL(5,1),
                Metric1 INT,
                Metric2 INT,
                Metric3 INT,
                Metric4 INT,
                Driver1 INT,
                Driver2 INT,
                Driver3 INT,
                Driver4 INT
            );

            WITH SourceH3 AS (
                SELECT 
                    h3.Hierarchy3_ID AS OldH3_ID,
                    h3.ParentHierarchy_ID,
                    h3.Hierarchy3_Code,
                    h3.Hierarchy3_Name,
                    h3.Trend,
                    h3.MinBays,
                    h3.MaxBays,
                    h3.DOS,
                    h3.COS,
                    h3.Exclude_From_Analysis,
                    h3.FlowNumber,
                    h3.BayRoundingThreshold,
                    h3.Metric1,
                    h3.Metric2,
                    h3.Metric3,
                    h3.Metric4,
                    h3.Driver1,
                    h3.Driver2,
                    h3.Driver3,
                    h3.Driver4,
                    ROW_NUMBER() OVER (ORDER BY h3.Hierarchy3_ID) - 1 AS RowNum
                FROM dbo.Hierarchy3 h3
                WHERE h3.HierarchyVersion_ID = @DuplicateFromExisting_ID
            )
            INSERT INTO @H3_Source
            (
                OldH3_ID,
                NewH3_ID,
                ParentOldH2_ID,
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
            )
            SELECT
                SourceH3.OldH3_ID,
                @NextH3_ID + SourceH3.RowNum,
                SourceH3.ParentHierarchy_ID,
                SourceH3.Hierarchy3_Code,
                SourceH3.Hierarchy3_Name,
                SourceH3.Trend,
                SourceH3.MinBays,
                SourceH3.MaxBays,
                SourceH3.DOS,
                SourceH3.COS,
                SourceH3.Exclude_From_Analysis,
                SourceH3.FlowNumber,
                SourceH3.BayRoundingThreshold,
                SourceH3.Metric1,
                SourceH3.Metric2,
                SourceH3.Metric3,
                SourceH3.Metric4,
                SourceH3.Driver1,
                SourceH3.Driver2,
                SourceH3.Driver3,
                SourceH3.Driver4
            FROM SourceH3;

            INSERT INTO dbo.Hierarchy3
            (
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
            )
            SELECT
                H3Source.NewH3_ID,
                @NewHierarchyVersion_ID,
                h2_map.NewH2_ID,
                H3Source.Hierarchy3_Code,
                H3Source.Hierarchy3_Name,
                H3Source.Trend,
                H3Source.MinBays,
                H3Source.MaxBays,
                H3Source.DOS,
                H3Source.COS,
                H3Source.Exclude_From_Analysis,
                H3Source.FlowNumber,
                H3Source.BayRoundingThreshold,
                H3Source.Metric1,
                H3Source.Metric2,
                H3Source.Metric3,
                H3Source.Metric4,
                H3Source.Driver1,
                H3Source.Driver2,
                H3Source.Driver3,
                H3Source.Driver4
            FROM @H3_Source AS H3Source
            INNER JOIN @H2_Mapping h2_map ON H3Source.ParentOldH2_ID = h2_map.OldH2_ID;

            SELECT @CopiedH3Count = COUNT(*) FROM @H3_Source;

            SET @CopiedCounts = N' Copied: '
                + CAST(@CopiedH3Count AS NVARCHAR(10)) + N' H3, '
                + CAST(@CopiedH2Count AS NVARCHAR(10)) + N' H2, '
                + CAST(@CopiedH1Count AS NVARCHAR(10)) + N' H1 items.';
        END;
        ELSE
        BEGIN
            SET @CopiedCounts = N' Created as empty version.';
        END;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message = N'Hierarchy version "' + @VersionName + N'" created successfully (ID=' + CAST(@NewHierarchyVersion_ID AS NVARCHAR(10)) + N').' + @CopiedCounts;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            N'Error ', ERROR_NUMBER(),
            N' at line ', ERROR_LINE(), N': ',
            ERROR_MESSAGE()
        );
        RETURN;
    END CATCH;
END

GO