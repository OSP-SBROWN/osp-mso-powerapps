
CREATE   PROCEDURE [ui].[HierMan_GetFullHierarchyCurrent]
    @MacroDate   DATE,
    @HierVer     INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success  = 0;
    SET @SQL_Message  = 'Procedure started...';

    BEGIN TRY
        --====================================
        -- 1. Return full hierarchy (Table #1)
        --====================================
        SELECT
        Hierarchy1_Code,
        Hierarchy1_Name,
        Hierarchy2_Code,
        Hierarchy2_Name,
        Hierarchy3_Code,
        Hierarchy3_Name,
        Trend,
        MinBays,
        MaxBays,
        Exclude_From_Analysis,
        FlowNumber
    FROM HierarchyDetail
    WHERE HierarchyVersion_ID = @HierVer
    ORDER BY FlowNumber ASC;

        --===================================================
        -- 2. Return distinct CategoryCodes NOT in Hierarchy3
        --    from MacroSnapShot (Table #2)
        --===================================================
        SELECT DISTINCT MS.Category_Code
    FROM MacroSnapShot AS MS
    WHERE MS.Create_Date = @MacroDate
        AND MS.Category_Code NOT IN (
                SELECT HD.Hierarchy3_Code
        FROM HierarchyDetail AS HD
        WHERE HD.HierarchyVersion_ID = @HierVer
          );

        --============================================
        -- 3. Return all records from Hierarchy1_Child (Table #3)
        --============================================
        SELECT *
    FROM Hierarchy1_Child
    WHERE HierarchyVersion_ID = @HierVer;

        --============================================
        -- 4. Return all records from Hierarchy2_Child (Table #4)
        --============================================
        SELECT *
    FROM Hierarchy2_Child
    WHERE HierarchyVersion_ID = @HierVer;

        --============================================
        -- 5. Return all records from Hierarchy3 (Table #5)
        --============================================
        SELECT *
    FROM Hierarchy3
    WHERE HierarchyVersion_ID = @HierVer;

        -- If everything succeeds:
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Hierarchy, snapshot categories, and child hierarchies successfully retrieved.';
    END TRY
    BEGIN CATCH
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT('There was a problem, error code: ', ERROR_MESSAGE());
    END CATCH;
END

GO

