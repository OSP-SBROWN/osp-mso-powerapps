SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [ui].[HierMan2_Insert1]
    @Hierarchy1_ID            INT              OUTPUT,
    @HierarchyVersion_ID      INT,                        -- required
    @Hierarchy1_Code          INT            = NULL,      -- table is INT
    @Hierarchy1_Name          VARCHAR(255)   = NULL,
    @Trend                    DECIMAL(5,3)   = NULL,
    @MinBays                  DECIMAL(5,1)   = NULL,
    @MaxBays                  DECIMAL(5,1)   = NULL,
    @DOS                      DECIMAL(5,1)   = NULL,
    @COS                      DECIMAL(5,1)   = NULL,
    @Exclude_From_Analysis    VARCHAR(1)     = NULL,      -- expect 'Y'/'N'
    @BayRoundingThreshold     DECIMAL(5,1)   = NULL,

    -- NEW: metrics (0–100, all null or all set & sum=100)
    @Metric1                  INT            = NULL,
    @Metric2                  INT            = NULL,
    @Metric3                  INT            = NULL,
    @Metric4                  INT            = NULL,

    -- NEW: drivers (0–100, all null or all set & sum=100)
    @Driver1                  INT            = NULL,
    @Driver2                  INT            = NULL,
    @Driver3                  INT            = NULL,
    @Driver4                  INT            = NULL,

    @SQL_Success              BIT             OUTPUT,
    @SQL_Message              NVARCHAR(4000)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- init outputs
    SET @SQL_Success   = 0;
    SET @SQL_Message   = N'';
    SET @Hierarchy1_ID = NULL;

    ------------------------------------------------------------
    -- Basic validation + normalization
    ------------------------------------------------------------
    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID must be a positive INT.';
        RETURN;
    END;

    -- Check if version exists
    IF NOT EXISTS (SELECT 1 FROM dbo.HierarchyVersion WHERE HierarchyVersion_ID = @HierarchyVersion_ID)
    BEGIN
        SET @SQL_Message = N'Hierarchy version with ID ' + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N' not found.';
        RETURN;
    END;

    DECLARE @NameWarning NVARCHAR(500) = N'';

    ------------------------------------------------------------
    -- Validate Metrics: either all NULL, or all between 0..100 and sum=100
    ------------------------------------------------------------
    DECLARE @Metrics_AllNull BIT =
        CASE WHEN @Metric1 IS NULL AND @Metric2 IS NULL AND @Metric3 IS NULL AND @Metric4 IS NULL THEN 1 ELSE 0 END;
    DECLARE @Metrics_AllSet  BIT =
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

    ------------------------------------------------------------
    -- Validate Drivers: either all NULL, or all between 0..100 and sum=100
    ------------------------------------------------------------
    DECLARE @Drivers_AllNull BIT =
        CASE WHEN @Driver1 IS NULL AND @Driver2 IS NULL AND @Driver3 IS NULL AND @Driver4 IS NULL THEN 1 ELSE 0 END;
    DECLARE @Drivers_AllSet  BIT =
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

    ------------------------------------------------------------
    -- Check for duplicate Code within version (fail-fast)
    ------------------------------------------------------------
    IF @Hierarchy1_Code IS NOT NULL AND EXISTS (
        SELECT 1
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Code     = @Hierarchy1_Code
    )
    BEGIN
        DECLARE @DupID1 INT;
        SELECT TOP (1) @DupID1 = Hierarchy1_ID
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Code     = @Hierarchy1_Code;

        SET @SQL_Message =
            N'Hierarchy1_Code ' + CAST(@Hierarchy1_Code AS NVARCHAR(20))
          + N' already exists in this version (ID=' + CAST(@DupID1 AS NVARCHAR(20)) + N').';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Check for duplicate Name within version (warning only)
    ------------------------------------------------------------
    IF @Hierarchy1_Name IS NOT NULL AND EXISTS (
        SELECT 1
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Name     = @Hierarchy1_Name
    )
    BEGIN
        DECLARE @DupID2 INT, @DupCode2 INT;
        SELECT TOP (1)
            @DupID2  = Hierarchy1_ID,
            @DupCode2 = Hierarchy1_Code
        FROM dbo.Hierarchy1
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID
          AND Hierarchy1_Name     = @Hierarchy1_Name;

        SET @NameWarning =
            N' WARNING: name "' + @Hierarchy1_Name
          + N'" already exists (ID=' + CAST(@DupID2 AS NVARCHAR(20))
          + N', Code=' + CAST(ISNULL(@DupCode2, -1) AS NVARCHAR(20)) + N').';
    END;

    ------------------------------------------------------------
    -- Insert (FIXED: Generate explicit ID since Hierarchy1_ID is NOT IDENTITY)
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        -- Generate the next available ID
        SELECT @Hierarchy1_ID = ISNULL(MAX(Hierarchy1_ID), 0) + 1 
        FROM dbo.Hierarchy1;

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
            Metric1, Metric2, Metric3, Metric4,
            Driver1, Driver2, Driver3, Driver4
        )
        VALUES
        (
            @Hierarchy1_ID,
            @HierarchyVersion_ID,
            @Hierarchy1_Code,
            @Hierarchy1_Name,
            @Trend,
            @MinBays,
            @MaxBays,
            @DOS,
            @COS,
            @Exclude_From_Analysis,
            @BayRoundingThreshold,
            @Metric1, @Metric2, @Metric3, @Metric4,
            @Driver1, @Driver2, @Driver3, @Driver4
        );

        -- ID was already set above before the INSERT
        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message =
            N'H1 record created successfully.'
          + N' New ID=' + CAST(@Hierarchy1_ID AS NVARCHAR(20))
          + N', Code=' + CAST(ISNULL(@Hierarchy1_Code, -1) AS NVARCHAR(20))
          + N', Name="' + ISNULL(@Hierarchy1_Name, N'<NULL>') + N'".'
          + @NameWarning;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        SET @SQL_Success = 0;
        SET @SQL_Message =
            N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
          + N' in ' + ISNULL(ERROR_PROCEDURE(), N'<unknown>')
          + N' at line ' + CAST(ERROR_LINE() AS NVARCHAR(10))
          + N': ' + ERROR_MESSAGE();
    END CATCH

END

GO