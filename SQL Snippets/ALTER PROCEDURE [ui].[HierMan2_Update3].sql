SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [ui].[HierMan2_Update3]
    @Hierarchy3_ID            INT,
    @HierarchyVersion_ID      INT,
    @Hierarchy3_Code          INT             = NULL,      -- table is INT
    @Hierarchy3_Name          VARCHAR(255)    = NULL,
    @ParentHierarchy_ID       INT             = NULL,
    @Trend                    DECIMAL(5,3)    = NULL,
    @MinBays                  DECIMAL(5,1)    = NULL,
    @MaxBays                  DECIMAL(5,1)    = NULL,
    @DOS                      DECIMAL(5,1)    = NULL,
    @COS                      DECIMAL(5,1)    = NULL,
    @Exclude_From_Analysis    VARCHAR(1)      = NULL,      -- 'Y'/'N'
    @FlowNumber               INT             = NULL,
    @BayRoundingThreshold     DECIMAL(5,1)    = NULL,

    -- NEW: metrics/drivers (merge semantics; validated after merge)
    @Metric1                  INT             = NULL,
    @Metric2                  INT             = NULL,
    @Metric3                  INT             = NULL,
    @Metric4                  INT             = NULL,
    @Driver1                  INT             = NULL,
    @Driver2                  INT             = NULL,
    @Driver3                  INT             = NULL,
    @Driver4                  INT             = NULL,

    @SQL_Success              BIT             OUTPUT,
    @SQL_Message              NVARCHAR(4000)  OUTPUT
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
        @Curr_Code        INT,
        @Curr_Name        VARCHAR(255),
        @Curr_Parent      INT,
        @Curr_Trend       DECIMAL(5,3),
        @Curr_MinBays     DECIMAL(5,1),
        @Curr_MaxBays     DECIMAL(5,1),
        @Curr_DOS         DECIMAL(5,1),
        @Curr_COS         DECIMAL(5,1),
        @Curr_Exclude     VARCHAR(1),
        @Curr_FlowNumber  INT,
        @Curr_Threshold   DECIMAL(5,1),
        @Curr_Metric1     INT,
        @Curr_Metric2     INT,
        @Curr_Metric3     INT,
        @Curr_Metric4     INT,
        @Curr_Driver1     INT,
        @Curr_Driver2     INT,
        @Curr_Driver3     INT,
        @Curr_Driver4     INT;

    SELECT
        @Curr_Code        = Hierarchy3_Code,
        @Curr_Name        = Hierarchy3_Name,
        @Curr_Parent      = ParentHierarchy_ID,
        @Curr_Trend       = Trend,
        @Curr_MinBays     = MinBays,
        @Curr_MaxBays     = MaxBays,
        @Curr_DOS         = DOS,
        @Curr_COS         = COS,
        @Curr_Exclude     = Exclude_From_Analysis,
        @Curr_FlowNumber  = FlowNumber,
        @Curr_Threshold   = BayRoundingThreshold,
        @Curr_Metric1     = Metric1,
        @Curr_Metric2     = Metric2,
        @Curr_Metric3     = Metric3,
        @Curr_Metric4     = Metric4,
        @Curr_Driver1     = Driver1,
        @Curr_Driver2     = Driver2,
        @Curr_Driver3     = Driver3,
        @Curr_Driver4     = Driver4
    FROM dbo.Hierarchy3
    WHERE Hierarchy3_ID = @Hierarchy3_ID
      AND HierarchyVersion_ID = @HierarchyVersion_ID;

    /* 3) Normalize & merge */
    SET @Hierarchy3_Code = COALESCE(@Hierarchy3_Code, @Curr_Code);
    SET @Hierarchy3_Name = NULLIF(LTRIM(RTRIM(COALESCE(@Hierarchy3_Name, @Curr_Name))), '');
    SET @ParentHierarchy_ID   = COALESCE(@ParentHierarchy_ID,   @Curr_Parent);
    SET @Trend                = COALESCE(@Trend,                @Curr_Trend);
    SET @MinBays              = COALESCE(@MinBays,              @Curr_MinBays);
    SET @MaxBays              = COALESCE(@MaxBays,              @Curr_MaxBays);
    SET @DOS                  = COALESCE(@DOS,                  @Curr_DOS);
    SET @COS                  = COALESCE(@COS,                  @Curr_COS);
    SET @Exclude_From_Analysis = UPPER(COALESCE(@Exclude_From_Analysis, @Curr_Exclude));
    SET @FlowNumber            = COALESCE(@FlowNumber,          @Curr_FlowNumber);
    SET @BayRoundingThreshold  = COALESCE(@BayRoundingThreshold,@Curr_Threshold);

    SET @Metric1 = COALESCE(@Metric1, @Curr_Metric1);
    SET @Metric2 = COALESCE(@Metric2, @Curr_Metric2);
    SET @Metric3 = COALESCE(@Metric3, @Curr_Metric3);
    SET @Metric4 = COALESCE(@Metric4, @Curr_Metric4);

    SET @Driver1 = COALESCE(@Driver1, @Curr_Driver1);
    SET @Driver2 = COALESCE(@Driver2, @Curr_Driver2);
    SET @Driver3 = COALESCE(@Driver3, @Curr_Driver3);
    SET @Driver4 = COALESCE(@Driver4, @Curr_Driver4);

    /* 4) Requireds & simple checks */
    IF @Hierarchy3_Code IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy3_Code is required.';
        RETURN;
    END;
    IF @Hierarchy3_Name IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy3_Name is required (after trimming).';
        RETURN;
    END;
    IF @Exclude_From_Analysis NOT IN ('Y','N')
    BEGIN
        SET @SQL_Message = N'Exclude_From_Analysis must be ''Y'' or ''N''.';
        RETURN;
    END;
    IF @MinBays IS NOT NULL AND @MaxBays IS NOT NULL AND @MinBays > @MaxBays
    BEGIN
        SET @SQL_Message = N'MinBays cannot be greater than MaxBays.';
        RETURN;
    END;

    /* 5) Parent must exist (if changed/provided) */
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

    /* 6) Metrics: all NULL OR all set in [0..100] and sum=100 */
    DECLARE @Metrics_AllNull BIT =
        CASE WHEN @Metric1 IS NULL AND @Metric2 IS NULL AND @Metric3 IS NULL AND @Metric4 IS NULL THEN 1 ELSE 0 END;
    DECLARE @Metrics_AllSet BIT =
        CASE WHEN @Metric1 IS NOT NULL AND @Metric2 IS NOT NULL AND @Metric3 IS NOT NULL AND @Metric4 IS NOT NULL THEN 1 ELSE 0 END;

    IF @Metrics_AllNull = 0 AND @Metrics_AllSet = 0
    BEGIN
        SET @SQL_Message = N'All Metric values must be NULL or all provided.';
        RETURN;
    END;

    IF @Metrics_AllSet = 1
    BEGIN
        IF (@Metric1 < 0 OR @Metric1 > 100 OR
            @Metric2 < 0 OR @Metric2 > 100 OR
            @Metric3 < 0 OR @Metric3 > 100 OR
            @Metric4 < 0 OR @Metric4 > 100)
        BEGIN
            SET @SQL_Message = N'Each Metric value must be between 0 and 100.';
            RETURN;
        END;
        IF (@Metric1 + @Metric2 + @Metric3 + @Metric4) <> 100
        BEGIN
            SET @SQL_Message = N'Metric1..4 must sum to 100.';
            RETURN;
        END;
    END;

    /* 7) Drivers: all NULL OR all set in [0..100] and sum=100 */
    DECLARE @Drivers_AllNull BIT =
        CASE WHEN @Driver1 IS NULL AND @Driver2 IS NULL AND @Driver3 IS NULL AND @Driver4 IS NULL THEN 1 ELSE 0 END;
    DECLARE @Drivers_AllSet BIT =
        CASE WHEN @Driver1 IS NOT NULL AND @Driver2 IS NOT NULL AND @Driver3 IS NOT NULL AND @Driver4 IS NOT NULL THEN 1 ELSE 0 END;

    IF @Drivers_AllNull = 0 AND @Drivers_AllSet = 0
    BEGIN
        SET @SQL_Message = N'All Driver values must be NULL or all provided.';
        RETURN;
    END;

    IF @Drivers_AllSet = 1
    BEGIN
        IF (@Driver1 < 0 OR @Driver1 > 100 OR
            @Driver2 < 0 OR @Driver2 > 100 OR
            @Driver3 < 0 OR @Driver3 > 100 OR
            @Driver4 < 0 OR @Driver4 > 100)
        BEGIN
            SET @SQL_Message = N'Each Driver value must be between 0 and 100.';
            RETURN;
        END;
        IF (@Driver1 + @Driver2 + @Driver3 + @Driver4) <> 100
        BEGIN
            SET @SQL_Message = N'Driver1..4 must sum to 100.';
            RETURN;
        END;
    END;

    /* 8) Enforce CODE uniqueness within version (exclude this row) */
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Code     = @Hierarchy3_Code
          AND Hierarchy3_ID      <> @Hierarchy3_ID
    )
    BEGIN
        DECLARE @DupID INT, @DupName VARCHAR(255);
        SELECT TOP (1)
            @DupID   = Hierarchy3_ID,
            @DupName = Hierarchy3_Name
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Code     = @Hierarchy3_Code
          AND Hierarchy3_ID      <> @Hierarchy3_ID;

        SET @SQL_Message = N'Cannot update: Hierarchy3_Code '
                         + CAST(@Hierarchy3_Code AS NVARCHAR(20))
                         + N' is already used by ID=' + CAST(@DupID AS NVARCHAR(20))
                         + N' (Name="' + ISNULL(@DupName, N'NULL') + N'").';
        RETURN;
    END;

    /* 9) NAME duplicates allowed: warn but do not block */
    DECLARE @NameWarning NVARCHAR(1000) = N'';
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy3_Name     = @Hierarchy3_Name
          AND Hierarchy3_ID      <> @Hierarchy3_ID
    )
    BEGIN
        DECLARE @DupID3 INT, @DupCode3 INT;
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
          + N' (Code=' + CAST(ISNULL(@DupCode3,-1) AS NVARCHAR(20)) + N').';
    END;

    /* 10) No-op check after normalization/merge */
    IF  @Hierarchy3_Code        = @Curr_Code
    AND @Hierarchy3_Name        = @Curr_Name
    AND @ParentHierarchy_ID     = @Curr_Parent
    AND COALESCE(@Trend,0)      = COALESCE(@Curr_Trend,0)
    AND COALESCE(@MinBays,0)    = COALESCE(@Curr_MinBays,0)
    AND COALESCE(@MaxBays,0)    = COALESCE(@Curr_MaxBays,0)
    AND COALESCE(@DOS,0)        = COALESCE(@Curr_DOS,0)
    AND COALESCE(@COS,0)        = COALESCE(@Curr_COS,0)
    AND @Exclude_From_Analysis  = @Curr_Exclude
    AND COALESCE(@FlowNumber,0) = COALESCE(@Curr_FlowNumber,0)
    AND COALESCE(@BayRoundingThreshold,0) = COALESCE(@Curr_Threshold,0)
    AND COALESCE(@Metric1,-1)   = COALESCE(@Curr_Metric1,-1)
    AND COALESCE(@Metric2,-1)   = COALESCE(@Curr_Metric2,-1)
    AND COALESCE(@Metric3,-1)   = COALESCE(@Curr_Metric3,-1)
    AND COALESCE(@Metric4,-1)   = COALESCE(@Curr_Metric4,-1)
    AND COALESCE(@Driver1,-1)   = COALESCE(@Curr_Driver1,-1)
    AND COALESCE(@Driver2,-1)   = COALESCE(@Curr_Driver2,-1)
    AND COALESCE(@Driver3,-1)   = COALESCE(@Curr_Driver3,-1)
    AND COALESCE(@Driver4,-1)   = COALESCE(@Curr_Driver4,-1)
    BEGIN
        SET @SQL_Success = 1;
        SET @SQL_Message = N'No changes detected.' + @NameWarning;
        RETURN;
    END;

    /* 11) Update */
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
            FlowNumber              = @FlowNumber,
            BayRoundingThreshold    = @BayRoundingThreshold,
            Metric1                 = @Metric1,
            Metric2                 = @Metric2,
            Metric3                 = @Metric3,
            Metric4                 = @Metric4,
            Driver1                 = @Driver1,
            Driver2                 = @Driver2,
            Driver3                 = @Driver3,
            Driver4                 = @Driver4
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
            SET @SQL_Message = N'Cannot update: Hierarchy3_Code '
                             + CAST(ISNULL(@Hierarchy3_Code,-1) AS NVARCHAR(20))
                             + N' conflicts with an existing row in this version.';
            RETURN;
        END;

        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            N'Error ', ERROR_NUMBER(), N' at line ', ERROR_LINE(), N': ', ERROR_MESSAGE()
        );
    END CATCH;
END
GO
