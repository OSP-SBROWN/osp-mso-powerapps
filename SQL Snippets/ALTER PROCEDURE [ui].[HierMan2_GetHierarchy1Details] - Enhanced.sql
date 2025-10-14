SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [ui].[HierMan2_GetHierarchy1Details]
    @Hierarchy1_ID             INT,
    @HierarchyVersion_ID       INT,
    @Hierarchy1_Code           NVARCHAR(255)    OUTPUT,
    @Hierarchy1_Name           NVARCHAR(255)    OUTPUT,
    @Trend                     FLOAT            OUTPUT,
    @MinBays                   FLOAT            OUTPUT,
    @MaxBays                   FLOAT            OUTPUT,
    @DOS                       FLOAT            OUTPUT,
    @COS                       FLOAT            OUTPUT,
    @Exclude_From_Analysis     NVARCHAR(1)      OUTPUT,
    @BayRoundingThreshold      FLOAT            OUTPUT,
    -- NEW: Added Metrics fields
    @Metric1                   INT              OUTPUT,
    @Metric2                   INT              OUTPUT,
    @Metric3                   INT              OUTPUT,
    @Metric4                   INT              OUTPUT,
    -- NEW: Added Drivers fields
    @Driver1                   INT              OUTPUT,
    @Driver2                   INT              OUTPUT,
    @Driver3                   INT              OUTPUT,
    @Driver4                   INT              OUTPUT,
    @SQL_Success               BIT              OUTPUT,
    @SQL_Message               NVARCHAR(4000)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Initialize all OUTPUTs to NULL in one go
        SELECT
            @Hierarchy1_Code           = NULL,
            @Hierarchy1_Name           = NULL,
            @Trend                     = NULL,
            @MinBays                   = NULL,
            @MaxBays                   = NULL,
            @DOS                       = NULL,
            @COS                       = NULL,
            @Exclude_From_Analysis     = NULL,
            @BayRoundingThreshold      = NULL,
            @Metric1                   = NULL,
            @Metric2                   = NULL,
            @Metric3                   = NULL,
            @Metric4                   = NULL,
            @Driver1                   = NULL,
            @Driver2                   = NULL,
            @Driver3                   = NULL,
            @Driver4                   = NULL,
            @SQL_Success               = NULL,
            @SQL_Message               = NULL;

        -- Fetch into OUTPUT parameters (including new Metrics/Drivers fields)
        SELECT
            @Hierarchy1_Code           = Hierarchy1_Code,
            @Hierarchy1_Name           = Hierarchy1_Name,
            @Trend                     = Trend,
            @MinBays                   = MinBays,
            @MaxBays                   = MaxBays,
            @DOS                       = DOS,
            @COS                       = COS,
            @Exclude_From_Analysis     = Exclude_From_Analysis,
            @BayRoundingThreshold      = BayRoundingThreshold,
            @Metric1                   = Metric1,
            @Metric2                   = Metric2,
            @Metric3                   = Metric3,
            @Metric4                   = Metric4,
            @Driver1                   = Driver1,
            @Driver2                   = Driver2,
            @Driver3                   = Driver3,
            @Driver4                   = Driver4
        FROM dbo.Hierarchy1
        WHERE Hierarchy1_ID = @Hierarchy1_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = N'No Hierarchy1 record found for ID = '
                               + CAST(@Hierarchy1_ID AS NVARCHAR(10)) + N' and Version = '
                               + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N'.';
        END
        ELSE
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = N'H1 record fetched successfully with all fields including Metrics/Drivers.';
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