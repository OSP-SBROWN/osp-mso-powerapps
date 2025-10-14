
CREATE PROCEDURE [ui].[HierMan2_Update1]
    @Hierarchy1_ID            INT,
    @HierarchyVersion_ID      INT,
    @Hierarchy1_Code          INT             = NULL,      -- table is INT
    @Hierarchy1_Name          VARCHAR(255)    = NULL,
    @Trend                    DECIMAL(5,3)    = NULL,
    @MinBays                  DECIMAL(5,1)    = NULL,
    @MaxBays                  DECIMAL(5,1)    = NULL,
    @DOS                      DECIMAL(5,1)    = NULL,
    @COS                      DECIMAL(5,1)    = NULL,
    @Exclude_From_Analysis    VARCHAR(1)      = NULL,      -- expect 'Y'/'N'
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
        FROM dbo.Hierarchy1
        WHERE Hierarchy1_ID = @Hierarchy1_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'No record found for Hierarchy1_ID='
                         + CAST(@Hierarchy1_ID AS NVARCHAR(20))
                         + N' and Version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    /* 2) Load current values */
    DECLARE
        @Curr_Code        INT,
        @Curr_Name        VARCHAR(255),
        @Curr_Trend       DECIMAL(5,3),
        @Curr_MinBays     DECIMAL(5,1),
        @Curr_MaxBays     DECIMAL(5,1),
        @Curr_DOS         DECIMAL(5,1),
        @Curr_COS         DECIMAL(5,1),
        @Curr_Exclude     VARCHAR(1),
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
        @Curr_Code       = Hierarchy1_Code,
        @Curr_Name       = Hierarchy1_Name,
        @Curr_Trend      = Trend,
        @Curr_MinBays    = MinBays,
        @Curr_MaxBays    = MaxBays,
        @Curr_DOS        = DOS,
        @Curr_COS        = COS,
        @Curr_Exclude    = Exclude_From_Analysis,
        @Curr_Threshold  = BayRoundingThreshold,
        @Curr_Metric1    = Metric1,
        @Curr_Metric2    = Metric2,
        @Curr_Metric3    = Metric3,
        @Curr_Metric4    = Metric4,
        @Curr_Driver1    = Driver1,
        @Curr_Driver2    = Driver2,
        @Curr_Driver3    = Driver3,
        @Curr_Driver4    = Driver4
    FROM dbo.Hierarchy1
    WHERE Hierarchy1_ID = @Hierarchy1_ID
      AND HierarchyVersion_ID = @HierarchyVersion_ID;

    /* 3) Normalize & merge: trim; NULL -> keep current; coerce Y/N */
    -- Code is INT so just coalesce
    SET @Hierarchy1_Code = COALESCE(@Hierarchy1_Code, @Curr_Code);
    SET @Hierarchy1_Name = NULLIF(LTRIM(RTRIM(COALESCE(@Hierarchy1_Name, @Curr_Name))), '');
    SET @Trend           = COALESCE(@Trend,           @Curr_Trend);
    SET @MinBays         = COALESCE(@MinBays,         @Curr_MinBays);
    SET @MaxBays         = COALESCE(@MaxBays,         @Curr_MaxBays);
    SET @DOS             = COALESCE(@DOS,             @Curr_DOS);
    SET @COS             = COALESCE(@COS,             @Curr_COS);
    SET @Exclude_From_Analysis = UPPER(COALESCE(@Exclude_From_Analysis, @Curr_Exclude));
    SET @BayRoundingThreshold  = COALESCE(@BayRoundingThreshold, @Curr_Threshold);

    -- Merge metrics/drivers (caller can pass only the ones they change)
    SET @Metric1 = COALESCE(@Metric1, @Curr_Metric1);
    SET @Metric2 = COALESCE(@Metric2, @Curr_Metric2);
    SET @Metric3 = COALESCE(@Metric3, @Curr_Metric3);
    SET @Metric4 = COALESCE(@Metric4, @Curr_Metric4);

    SET @Driver1 = COALESCE(@Driver1, @Curr_Driver1);
    SET @Driver2 = COALESCE(@Driver2, @Curr_Driver2);
    SET @Driver3 = COALESCE(@Driver3, @Curr_Driver3);
    SET @Driver4 = COALESCE(@Driver4, @Curr_Driver4);

    /* 4) Requireds & simple checks */
    IF @Hierarchy1_Code IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy1_Code is required.';
        RETURN;
    END;
    IF @Hierarchy1_Name IS NULL
    BEGIN
        SET @SQL_Message = N'Hierarchy1_Name is required (after trimming).';
        RETURN;
    END;
    IF @Exclude_From_Analysis NOT IN ('Y', 'N')
    BEGIN
        SET @SQL_Message = N'Exclude_From_Analysis must be ''Y'' or ''N''.';
        RETURN;
    END;
    IF @MinBays IS NOT NULL AND @MaxBays IS NOT NULL AND @MinBays > @MaxBays
    BEGIN
        SET @SQL_Message = N'MinBays cannot be greater than MaxBays.';
        RETURN;
    END;

    /* 5) Validate metrics: either all NULL OR all in [0..100] and sum=100 */
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

    /* 6) Validate drivers: either all NULL OR all in [0..100] and sum=100 */
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

    /* 7) Enforce CODE uniqueness within version (exclude this row) */
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Code     = @Hierarchy1_Code
          AND Hierarchy1_ID      <> @Hierarchy1_ID
    )
    BEGIN
        DECLARE @DupID INT, @DupName VARCHAR(255);
        SELECT TOP (1)
            @DupID   = Hierarchy1_ID,
            @DupName = Hierarchy1_Name
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Code     = @Hierarchy1_Code
          AND Hierarchy1_ID      <> @Hierarchy1_ID;

        SET @SQL_Message = N'Cannot update: Hierarchy1_Code ' + CAST(@Hierarchy1_Code AS NVARCHAR(20))
                         + N' is already used by ID=' + CAST(@DupID AS NVARCHAR(20))
                         + N' (Name="' + ISNULL(@DupName, N'NULL') + N'").';
        RETURN;
    END;

    /* 8) NAME duplicates allowed: warn but do not block */
    DECLARE @NameWarning NVARCHAR(1000) = N'';
    IF EXISTS (
        SELECT 1
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Name     = @Hierarchy1_Name
          AND Hierarchy1_ID      <> @Hierarchy1_ID
    )
    BEGIN
        DECLARE @DupID2 INT, @DupCode2 INT;
        SELECT TOP (1)
            @DupID2  = Hierarchy1_ID,
            @DupCode2 = Hierarchy1_Code
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Name     = @Hierarchy1_Name
          AND Hierarchy1_ID      <> @Hierarchy1_ID;

        SET @NameWarning =
            N' WARNING: name "' + @Hierarchy1_Name
          + N'" already used by ID=' + CAST(@DupID2 AS NVARCHAR(20))
          + N' (Code=' + CAST(ISNULL(@DupCode2,-1) AS NVARCHAR(20)) + N').';
    END;

    /* 9) No-op check after normalization/merge */
    IF  @Hierarchy1_Code        = @Curr_Code
    AND @Hierarchy1_Name        = @Curr_Name
    AND COALESCE(@Trend,0)      = COALESCE(@Curr_Trend,0)
    AND COALESCE(@MinBays,0)    = COALESCE(@Curr_MinBays,0)
    AND COALESCE(@MaxBays,0)    = COALESCE(@Curr_MaxBays,0)
    AND COALESCE(@DOS,0)        = COALESCE(@Curr_DOS,0)
    AND COALESCE(@COS,0)        = COALESCE(@Curr_COS,0)
    AND @Exclude_From_Analysis  = @Curr_Exclude
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

    /* 10) Update */
    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.Hierarchy1
        SET
            Hierarchy1_Code          = @Hierarchy1_Code,
            Hierarchy1_Name          = @Hierarchy1_Name,
            Trend                    = @Trend,
            MinBays                  = @MinBays,
            MaxBays                  = @MaxBays,
            DOS                      = @DOS,
            COS                      = @COS,
            Exclude_From_Analysis    = @Exclude_From_Analysis,
            BayRoundingThreshold     = @BayRoundingThreshold,
            Metric1                  = @Metric1,
            Metric2                  = @Metric2,
            Metric3                  = @Metric3,
            Metric4                  = @Metric4,
            Driver1                  = @Driver1,
            Driver2                  = @Driver2,
            Driver3                  = @Driver3,
            Driver4                  = @Driver4
        WHERE Hierarchy1_ID = @Hierarchy1_ID
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
            SET @SQL_Message = N'Cannot update: Hierarchy1_Code '
                             + CAST(ISNULL(@Hierarchy1_Code,-1) AS NVARCHAR(20))
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

