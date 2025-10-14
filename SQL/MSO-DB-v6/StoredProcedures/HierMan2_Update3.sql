
CREATE   PROCEDURE [ui].[HierMan2_Update3]
    @Hierarchy3_ID            INT,
    @HierarchyVersion_ID      INT,
    @Hierarchy3_Code          NVARCHAR(255)   = NULL,
    @Hierarchy3_Name          NVARCHAR(255)   = NULL,
    @ParentHierarchy_ID       INT             = NULL,
    @Trend                    FLOAT           = NULL,
    @MinBays                  FLOAT           = NULL,
    @MaxBays                  FLOAT           = NULL,
    @DOS                      FLOAT           = NULL,
    @COS                      FLOAT           = NULL,
    @Exclude_From_Analysis    NVARCHAR(1)     = NULL,   -- expect 'Y'/'N'
    @BayRoundingThreshold     FLOAT           = NULL,
    @SQL_Success              BIT             OUTPUT,
    @SQL_Message              NVARCHAR(4000)  OUTPUT    -- more room
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- init
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    /* 1) Ensure target row exists */
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE Hierarchy3_ID = @Hierarchy3_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'No record found for Hierarchy3_ID='
                         + CAST(@Hierarchy3_ID AS NVARCHAR(20))
                         + N' and Version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    /* 2) Load current values */
    DECLARE
        @Curr_Code       NVARCHAR(255),
        @Curr_Name       NVARCHAR(255),
        @Curr_Parent     INT,
        @Curr_Trend      FLOAT,
        @Curr_MinBays    FLOAT,
        @Curr_MaxBays    FLOAT,
        @Curr_DOS        FLOAT,
        @Curr_COS        FLOAT,
        @Curr_Exclude    NVARCHAR(1),
        @Curr_Threshold  FLOAT;

    SELECT
        @Curr_Code      = Hierarchy3_Code,
        @Curr_Name      = Hierarchy3_Name,
        @Curr_Parent    = ParentHierarchy_ID,
        @Curr_Trend     = Trend,
        @Curr_MinBays   = MinBays,
        @Curr_MaxBays   = MaxBays,
        @Curr_DOS       = DOS,
        @Curr_COS       = COS,
        @Curr_Exclude   = Exclude_From_Analysis,
        @Curr_Threshold = BayRoundingThreshold
    FROM dbo.Hierarchy3
    WHERE Hierarchy3_ID = @Hierarchy3_ID
      AND HierarchyVersion_ID = @HierarchyVersion_ID;

    /* 3) Normalize: trim; NULL -> keep current; coerce Y/N */
    SET @Hierarchy3_Code = NULLIF(LTRIM(RTRIM(COALESCE(@Hierarchy3_Code, @Curr_Code))), N'');
    SET @Hierarchy3_Name = NULLIF(LTRIM(RTRIM(COALESCE(@Hierarchy3_Name, @Curr_Name))), N'');
    SET @ParentHierarchy_ID   = COALESCE(@ParentHierarchy_ID,   @Curr_Parent);
    SET @Trend                = COALESCE(@Trend,                @Curr_Trend);
    SET @MinBays              = COALESCE(@MinBays,              @Curr_MinBays);
    SET @MaxBays              = COALESCE(@MaxBays,              @Curr_MaxBays);
    SET @DOS                  = COALESCE(@DOS,                  @Curr_DOS);
    SET @COS                  = COALESCE(@COS,                  @Curr_COS);
    SET @Exclude_From_Analysis = UPPER(COALESCE(@Exclude_From_Analysis, @Curr_Exclude));
    SET @BayRoundingThreshold  = COALESCE(@BayRoundingThreshold, @Curr_Threshold);

    IF @Hierarchy3_Code IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy3_Code is required (after trimming).';
        RETURN;
    END;
    IF @Hierarchy3_Name IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy3_Name is required (after trimming).';
        RETURN;
    END;
    IF @Exclude_From_Analysis NOT IN (N'Y', N'N')
    BEGIN
        SET @SQL_Message = N'Exclude_From_Analysis must be ''Y'' or ''N''.';
        RETURN;
    END;
    IF @MinBays IS NOT NULL AND @MaxBays IS NOT NULL AND @MinBays > @MaxBays
    BEGIN
        SET @SQL_Message = N'MinBays cannot be greater than MaxBays.';
        RETURN;
    END;

    /* 4) Parent must exist (if changed/provided) */
    IF @ParentHierarchy_ID IS NOT NULL AND @ParentHierarchy_ID <> @Curr_Parent
       AND NOT EXISTS (
            SELECT 1
            FROM dbo.Hierarchy2
            WHERE Hierarchy2_ID = @ParentHierarchy_ID
              AND HierarchyVersion_ID = @HierarchyVersion_ID
       )
    BEGIN
        SET @SQL_Message = N'Invalid ParentHierarchy_ID='
                         + CAST(@ParentHierarchy_ID AS NVARCHAR(20))
                         + N' for Version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    /* 5) Enforce CODE uniqueness within version (exclude this row) */
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Code     = @Hierarchy3_Code
          AND Hierarchy3_ID      <> @Hierarchy3_ID
    )
    BEGIN
        DECLARE @DupID INT, @DupName NVARCHAR(255);
        SELECT TOP (1)
            @DupID   = Hierarchy3_ID,
            @DupName = Hierarchy3_Name
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Code     = @Hierarchy3_Code
          AND Hierarchy3_ID      <> @Hierarchy3_ID;

        SET @SQL_Message = N'Cannot update: Hierarchy3_Code "' + @Hierarchy3_Code
                         + N'" is already used by ID=' + CAST(@DupID AS NVARCHAR(20))
                         + N' (Name="' + ISNULL(@DupName, N'NULL') + N'").';
        RETURN;
    END;

    /* 6) NAME duplicates allowed: warn but do not block */
    DECLARE @NameWarning NVARCHAR(1000) = N'';
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Name     = @Hierarchy3_Name
          AND Hierarchy3_ID      <> @Hierarchy3_ID
    )
    BEGIN
        DECLARE @DupID3 INT, @DupCode3 NVARCHAR(255);
        SELECT TOP (1)
            @DupID3  = Hierarchy3_ID,
            @DupCode3 = Hierarchy3_Code
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Name     = @Hierarchy3_Name
          AND Hierarchy3_ID      <> @Hierarchy3_ID;

        SET @NameWarning =
            N' WARNING: name "' + @Hierarchy3_Name
          + N'" already used by ID=' + CAST(@DupID3 AS NVARCHAR(20))
          + N' (Code="' + ISNULL(@DupCode3, N'NULL') + N'").';
    END;

    /* 7) No-op check after normalization */
    IF  @Hierarchy3_Code       = @Curr_Code
    AND @Hierarchy3_Name       = @Curr_Name
    AND @ParentHierarchy_ID    = @Curr_Parent
    AND COALESCE(@Trend,0)     = COALESCE(@Curr_Trend,0)
    AND COALESCE(@MinBays,0)   = COALESCE(@Curr_MinBays,0)
    AND COALESCE(@MaxBays,0)   = COALESCE(@Curr_MaxBays,0)
    AND COALESCE(@DOS,0)       = COALESCE(@Curr_DOS,0)
    AND COALESCE(@COS,0)       = COALESCE(@Curr_COS,0)
    AND @Exclude_From_Analysis = @Curr_Exclude
    AND COALESCE(@BayRoundingThreshold,0) = COALESCE(@Curr_Threshold,0)
    BEGIN
        SET @SQL_Success = 1;
        SET @SQL_Message = N'No changes detected.' + @NameWarning;
        RETURN;
    END;

    /* 8) Update */
    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.Hierarchy3
        SET
            Hierarchy3_Code         = @Hierarchy3_Code,
            Hierarchy3_Name         = @Hierarchy3_Name,
            ParentHierarchy_ID      = @ParentHierarchy_ID,
            Trend                   = @Trend,
            MinBays                 = @MinBays,
            MaxBays                 = @MaxBays,
            DOS                     = @DOS,
            COS                     = @COS,
            Exclude_From_Analysis   = @Exclude_From_Analysis,
            BayRoundingThreshold    = @BayRoundingThreshold
        WHERE Hierarchy3_ID = @Hierarchy3_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message = N'Update successful.' + @NameWarning;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = N'Cannot update: Hierarchy3_Code "' + ISNULL(@Hierarchy3_Code, N'')
                             + N'" conflicts with an existing row in this version.';
            RETURN;
        END;

        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            N'Error ', ERROR_NUMBER(), N' at line ', ERROR_LINE(), N': ', ERROR_MESSAGE()
        );
    END CATCH;
END

GO

