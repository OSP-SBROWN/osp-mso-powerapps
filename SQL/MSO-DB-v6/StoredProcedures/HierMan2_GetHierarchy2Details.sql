
CREATE PROCEDURE [ui].[HierMan2_GetHierarchy2Details]
    @Hierarchy2_ID            INT,
    @HierarchyVersion_ID      INT,
    @Hierarchy2_Code          NVARCHAR(255)     OUTPUT,
    @Hierarchy2_Name          NVARCHAR(255)     OUTPUT,
    @ParentHierarchy_ID       INT               OUTPUT,
    @Trend                    FLOAT             OUTPUT,
    @MinBays                  FLOAT             OUTPUT,
    @MaxBays                  FLOAT             OUTPUT,
    @DOS                      FLOAT             OUTPUT,
    @COS                      FLOAT             OUTPUT,
    @Exclude_From_Analysis    NVARCHAR(1)       OUTPUT,
    @BayRoundingThreshold     FLOAT             OUTPUT,
    -- NEW: Added Metrics fields
    @Metric1                  INT               OUTPUT,
    @Metric2                  INT               OUTPUT,
    @Metric3                  INT               OUTPUT,
    @Metric4                  INT               OUTPUT,
    -- NEW: Added Drivers fields
    @Driver1                  INT               OUTPUT,
    @Driver2                  INT               OUTPUT,
    @Driver3                  INT               OUTPUT,
    @Driver4                  INT               OUTPUT,
    @SQL_Success              BIT               OUTPUT,
    @SQL_Message              NVARCHAR(4000)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1. Initialize all OUTPUTs to NULL
        SELECT
            @Hierarchy2_Code        = NULL,
            @Hierarchy2_Name        = NULL,
            @ParentHierarchy_ID     = NULL,
            @Trend                  = NULL,
            @MinBays                = NULL,
            @MaxBays                = NULL,
            @DOS                    = NULL,
            @COS                    = NULL,
            @Exclude_From_Analysis  = NULL,
            @BayRoundingThreshold   = NULL,
            @Metric1                = NULL,
            @Metric2                = NULL,
            @Metric3                = NULL,
            @Metric4                = NULL,
            @Driver1                = NULL,
            @Driver2                = NULL,
            @Driver3                = NULL,
            @Driver4                = NULL,
            @SQL_Success            = NULL,
            @SQL_Message            = NULL;

        -- 2. Fetch into OUTPUT parameters (including new Metrics/Drivers fields)
        SELECT
            @Hierarchy2_Code        = Hierarchy2_Code,
            @Hierarchy2_Name        = Hierarchy2_Name,
            @ParentHierarchy_ID     = ParentHierarchy_ID,
            @Trend                  = Trend,
            @MinBays                = MinBays,
            @MaxBays                = MaxBays,
            @DOS                    = DOS,
            @COS                    = COS,
            @Exclude_From_Analysis  = Exclude_From_Analysis,
            @BayRoundingThreshold   = BayRoundingThreshold,
            @Metric1                = Metric1,
            @Metric2                = Metric2,
            @Metric3                = Metric3,
            @Metric4                = Metric4,
            @Driver1                = Driver1,
            @Driver2                = Driver2,
            @Driver3                = Driver3,
            @Driver4                = Driver4
        FROM dbo.Hierarchy2
        WHERE Hierarchy2_ID = @Hierarchy2_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        -- 3. Check if found
        IF @@ROWCOUNT = 0
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = N'No Hierarchy2 record found for ID = '
                             + CAST(@Hierarchy2_ID AS NVARCHAR(10)) + N' and Version = '
                             + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N'.';
        END
        ELSE
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = N'H2 record fetched successfully with all fields including Metrics/Drivers.';
        END
    END TRY
    BEGIN CATCH
        SET @SQL_Success = 0;
        SET @SQL_Message =
            N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
          + N' in ' + ISNULL(ERROR_PROCEDURE(), N'<unknown>')
          + N' at line ' + CAST(ERROR_LINE() AS NVARCHAR(10))
          + N': ' + ERROR_MESSAGE();
    END CATCH
END

GO

