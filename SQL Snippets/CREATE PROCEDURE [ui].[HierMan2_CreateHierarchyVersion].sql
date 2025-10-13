SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_CreateHierarchyVersion]
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
        FROM dbo.HierarchyVersions 
        WHERE Name = @VersionName
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
            FROM dbo.HierarchyVersions 
            WHERE ID = @DuplicateFromExisting_ID
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
        INSERT INTO dbo.HierarchyVersions
        (
            Name,
            Status,
            CreatedBy,
            CreatedDate,
            ModifiedDate
        )
        VALUES
        (
            @VersionName,
            @VersionStatus,
            @CreatedBy,
            GETDATE(),
            GETDATE()
        );

        SET @NewHierarchyVersion_ID = CONVERT(INT, SCOPE_IDENTITY());

        -- If duplicating from existing version, copy all hierarchy data
        IF @DuplicateFromExisting_ID IS NOT NULL AND @DuplicateFromExisting_ID > 0
        BEGIN
            -- Copy Hierarchy1 records
            INSERT INTO dbo.Hierarchy1 
            (
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
                @NewHierarchyVersion_ID,  -- New version ID
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
            WHERE HierarchyVersion_ID = @DuplicateFromExisting_ID;

            -- Copy Hierarchy2 records (need to map parent IDs)
            -- Create a mapping table for old to new H1 IDs
            DECLARE @H1_Mapping TABLE (
                OldH1_ID INT,
                NewH1_ID INT,
                OldH1_Code INT
            );

            INSERT INTO @H1_Mapping (OldH1_ID, NewH1_ID, OldH1_Code)
            SELECT 
                old_h1.Hierarchy1_ID AS OldH1_ID,
                new_h1.Hierarchy1_ID AS NewH1_ID,
                old_h1.Hierarchy1_Code AS OldH1_Code
            FROM dbo.Hierarchy1 old_h1
            INNER JOIN dbo.Hierarchy1 new_h1 ON old_h1.Hierarchy1_Code = new_h1.Hierarchy1_Code
            WHERE old_h1.HierarchyVersion_ID = @DuplicateFromExisting_ID
              AND new_h1.HierarchyVersion_ID = @NewHierarchyVersion_ID;

            INSERT INTO dbo.Hierarchy2
            (
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
                @NewHierarchyVersion_ID,
                h1_map.NewH1_ID,  -- Map to new H1 ID
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
                h2.Driver4
            FROM dbo.Hierarchy2 h2
            INNER JOIN @H1_Mapping h1_map ON h2.ParentHierarchy_ID = h1_map.OldH1_ID
            WHERE h2.HierarchyVersion_ID = @DuplicateFromExisting_ID;

            -- Copy Hierarchy3 records (need to map parent IDs)
            -- Create a mapping table for old to new H2 IDs
            DECLARE @H2_Mapping TABLE (
                OldH2_ID INT,
                NewH2_ID INT,
                OldH2_Code INT
            );

            INSERT INTO @H2_Mapping (OldH2_ID, NewH2_ID, OldH2_Code)
            SELECT 
                old_h2.Hierarchy2_ID AS OldH2_ID,
                new_h2.Hierarchy2_ID AS NewH2_ID,
                old_h2.Hierarchy2_Code AS OldH2_Code
            FROM dbo.Hierarchy2 old_h2
            INNER JOIN dbo.Hierarchy2 new_h2 ON old_h2.Hierarchy2_Code = new_h2.Hierarchy2_Code
            WHERE old_h2.HierarchyVersion_ID = @DuplicateFromExisting_ID
              AND new_h2.HierarchyVersion_ID = @NewHierarchyVersion_ID;

            INSERT INTO dbo.Hierarchy3
            (
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
                @NewHierarchyVersion_ID,
                h2_map.NewH2_ID,  -- Map to new H2 ID
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
                h3.Driver4
            FROM dbo.Hierarchy3 h3
            INNER JOIN @H2_Mapping h2_map ON h3.ParentHierarchy_ID = h2_map.OldH2_ID
            WHERE h3.HierarchyVersion_ID = @DuplicateFromExisting_ID;

            DECLARE @CopiedCounts NVARCHAR(200) = N' Copied: ' 
                + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' H3, '
                + CAST((SELECT COUNT(*) FROM dbo.Hierarchy2 WHERE HierarchyVersion_ID = @NewHierarchyVersion_ID) AS NVARCHAR(10)) + N' H2, '
                + CAST((SELECT COUNT(*) FROM dbo.Hierarchy1 WHERE HierarchyVersion_ID = @NewHierarchyVersion_ID) AS NVARCHAR(10)) + N' H1 items.';
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