CREATE PROCEDURE [dbo].[StoreResizeLogic]
    @UserID INT,
    @ReportID INT,
    @Resize_Success BIT OUTPUT

AS
BEGIN
    SET NOCOUNT ON;
    SET @Resize_Success = 0;

    IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
    CREATE TABLE #Results (Category_Code INT);

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Granularity VARCHAR(1);
    DECLARE @Resize_Gran_Code INT;
    DECLARE @Resize_ValueToSet FLOAT;
    DECLARE @ColumnName NVARCHAR(255);

    DECLARE resize_cursor CURSOR FOR
    SELECT 
        Granularity,
        CASE 
            WHEN Granularity = 'C' THEN 'Category_Code'
            WHEN Granularity = 'D' THEN 'Department_Number' 
            WHEN Granularity = 'T' THEN 'Temp_Category_Number' 
        END AS ColumnName,
        Gran_Code, 
        ValueToSet
    FROM BayRules 
    WHERE ReportID = @ReportID
    AND Group_Key = 'Resize'
    ORDER BY Granularity DESC;

    OPEN resize_cursor;

    FETCH NEXT FROM resize_cursor INTO @Granularity, @ColumnName, @Resize_Gran_Code, @Resize_ValueToSet;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = N'
        SELECT * 
        INTO #resize 
        FROM MSO_Reports
        WHERE ' + QUOTENAME(@ColumnName) + N' = @Gran_Code
        AND UserID = @UserID AND ReportID = @ReportID
        AND Exclude_from_analysis = 0;

        WITH SumBays AS (
            SELECT ' + QUOTENAME(@ColumnName) + N', SUM(Bays) AS Sum_Bays
            FROM #resize 
            WHERE ' + QUOTENAME(@ColumnName) + N' = @Gran_Code
            GROUP BY ' + QUOTENAME(@ColumnName) + N'
        )
        UPDATE r
        SET Bays = Bays * COALESCE(((s.Sum_Bays + @ValueToSet) / NULLIF(s.Sum_Bays, 0)), 0)
        FROM #resize r
        JOIN SumBays s ON r.' + QUOTENAME(@ColumnName) + N' = s.' + QUOTENAME(@ColumnName) + N';

        UPDATE s
        SET s.Bays = ROUND(r.Bays, 2)
        FROM MSO_Reports s
        JOIN #resize r ON s.Category_Code = r.Category_Code
        WHERE s.UserID = @UserID AND s.ReportID = @ReportID;

        UPDATE s
        SET 
            s.Bays = s.Org_bays,
            s.Store_Bays_Recc = 0,
            s.Dept_Bays_Recc = 0,
            s.Temp_Bays_Recc = 0,
            s.Exclude_from_analysis = 4
        FROM MSO_Reports s
        JOIN #resize r ON s.Category_Code = r.Category_Code
        WHERE s.UserID = @UserID AND s.ReportID = @ReportID
        AND s.Bays <= 0;
        
        INSERT INTO #Results SELECT Category_Code FROM #resize;
        ';
        
        EXEC sp_executesql @SQL, 
            N'@Gran_Code INT, @ValueToSet FLOAT,@UserID INT, @ReportID INT', 
            @Gran_Code = @Resize_Gran_Code, 
            @ValueToSet = @Resize_ValueToSet,
            @UserID = @UserID,
            @ReportID = @ReportID;

        FETCH NEXT FROM resize_cursor INTO @Granularity, @ColumnName, @Resize_Gran_Code, @Resize_ValueToSet;
    END;

    CLOSE resize_cursor;
    DEALLOCATE resize_cursor;
    IF EXISTS (SELECT 1 FROM #Results)
    BEGIN
        SET @Resize_Success = 1; -- Data exists
    END

    SET NOCOUNT OFF;
END;

GO

