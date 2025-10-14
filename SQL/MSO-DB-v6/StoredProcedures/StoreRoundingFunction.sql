
CREATE PROCEDURE [dbo].[StoreRoundingFunction]
    @ReportID INT,
    @UserID INT,
    @MinBayFraction FLOAT,
    @Hierarchy_Code INT,
    @Hierarchy INT
    --@SQL_Success BIT OUTPUT
    --@SQL_Message NVARCHAR(255) OUTPUT



AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SumReqd FLOAT;
    DECLARE @SumMade FLOAT;
    DECLARE @Diff FLOAT;
    DECLARE @SortOrder VARCHAR(4);
    DECLARE @TopCount INT;
    DECLARE @SumDiff FLOAT;


    SELECT @SumDiff = ISNULL(SUM(Store_Bays_Recc) - SUM(Org_Store_Bays_Recc), 0) FROM MSO_Reports WHERE UserID = @UserID AND ReportID = @ReportID AND Exclude_from_analysis = 5;
    --SET @SumDiff = 0;


    SELECT @SumReqd = ROUND(SUM(Bays), 1) -- - @SumDiff, 1)
    FROM MSO_Reports
    WHERE UserID = @UserID AND ReportID = @ReportID AND Exclude_from_analysis = 0
    AND (CASE WHEN @Hierarchy = 1 THEN Temp_Category_Number WHEN @Hierarchy = 2 THEN Department_Number ELSE 1 END) =
    (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);

    SELECT
    @SumMade = SUM(Rounded_Value)
    FROM Sys_Rounded_Recc
    WHERE UserID = @UserID AND ReportID = @ReportID AND Hierarchy = @Hierarchy 
    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);


    SET @Diff = @SumMade - @SumReqd;

    SET @SortOrder = CASE WHEN @Diff < 0 THEN 'DESC' ELSE 'ASC' END;

    SET @TopCount = CASE
                    WHEN @Diff = 0 THEN 0
                    WHEN ABS(@Diff) <> 0 AND  ABS(@Diff) < 1 THEN ABS(@Diff)  -- This is to manage half bays add one half bay
                    ELSE ABS(@Diff * 2) END;                                  -- As we are adding half bays we need twice as many target rows
    --HALF BAYS
   IF @TopCount <> 0
        IF @SortOrder = 'ASC'
            BEGIN
                WITH targets AS (
                    SELECT TOP (@TopCount)
                        ReportID,
                        UserID,
                        Category_Code,
                        Hierarchy,
                        Hierarchy_Code
                    FROM Sys_Rounded_Recc
                    WHERE UserID = @UserID AND ReportID = @ReportID  AND Hierarchy = @Hierarchy
                    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END)
                    AND Rounded_Value - FLOOR(Rounded_Value) <> 0 -- Check for whole bays
                    AND Rounded_Value > (Min_Bays - @MinBayFraction) -- Check it doesn't go under min bays
                    AND (Rounded_Value - @MinBayFraction) <= BayRoundingThreshold-- Check you are not rounding down past BRT
                    AND Rounded_Value > (@MinBayFraction * 2) -- Check Rounded_Value is not at bottom
                    AND Bays < Rounded_Value -- Check it has been rounded up
                    ORDER BY Fractional_Part ASC
                )
                UPDATE sr
                SET 
                    sr.Rounded_Value = sr.Rounded_Value - @MinBayFraction,
                    sr.Adj = COALESCE(sr.Adj, 0) - @MinBayFraction
                FROM Sys_Rounded_Recc sr
                JOIN targets tgt
                ON sr.UserID = tgt.UserID
                AND sr.ReportID = tgt.ReportID
                AND sr.Category_Code = tgt.Category_Code
                AND sr.Hierarchy = tgt.Hierarchy
                AND sr.Hierarchy_Code = tgt.Hierarchy_Code
                AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE sr.Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);
            END
            ELSE
            BEGIN
                WITH targets AS (
                    SELECT TOP (@TopCount)
                        ReportID,
                        UserID,
                        Category_Code,
                        Hierarchy,
                        Hierarchy_Code
                    FROM Sys_Rounded_Recc
                    WHERE UserID = @UserID AND ReportID = @ReportID  AND Hierarchy = @Hierarchy
                    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END)
                    AND Rounded_Value - FLOOR(Rounded_Value) <> 0 -- Check for half-bays
                    AND Rounded_Value < (Max_Bays + @MinBayFraction) -- Check it doesn't exceed max bays
                    AND Rounded_Value > @MinBayFraction -- Check Rounded_Value is not at bottom
                    AND Bays > Rounded_Value -- Check it has been rounded down
                    AND Rounded_Value + @MinBayFraction <= BayRoundingThreshold -- Check it will not exceed BRT
                    ORDER BY Fractional_Part DESC
                )
                UPDATE sr
                SET 
                    sr.Rounded_Value = sr.Rounded_Value + @MinBayFraction,
                    sr.Adj = COALESCE(sr.Adj, 0) + @MinBayFraction
                FROM Sys_Rounded_Recc sr
                JOIN targets tgt 
                ON sr.UserID = tgt.UserID
                AND sr.ReportID = tgt.ReportID
                AND sr.Category_Code = tgt.Category_Code
                AND sr.Hierarchy = tgt.Hierarchy
                AND sr.Hierarchy_Code = tgt.Hierarchy_Code
                AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE sr.Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);
            END;

    SELECT
    @SumMade = SUM(Rounded_Value)
    FROM Sys_Rounded_Recc
    WHERE UserID = @UserID AND ReportID = @ReportID AND Hierarchy = @Hierarchy
    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);

    SET @Diff = @SumMade - @SumReqd;
    SET @TopCount = ABS(@Diff);
    SET @SortOrder = CASE WHEN @Diff < 0 THEN 'DESC' ELSE 'ASC' END;

    --Whole Bays
    IF @TopCount <> 0
        IF @SortOrder = 'ASC'
            BEGIN
                WITH targets AS (
                    SELECT TOP (@TopCount)
                        ReportID,
                        UserID,
                        Category_Code,
                        Hierarchy,
                        Hierarchy_Code
                    FROM Sys_Rounded_Recc
                    WHERE UserID = @UserID AND ReportID = @ReportID  AND Hierarchy = @Hierarchy
                    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END)
                    AND Rounded_Value - FLOOR(Rounded_Value) = 0 -- Check for whole bays
                    AND Rounded_Value > (Min_Bays - 1)
                    AND Rounded_Value - 1 >= BayRoundingThreshold -- Check you are not rounding down past BRT
                    AND Rounded_Value > 1 -- Check Rounded_Value is not at bottom
                    AND Bays < Rounded_Value -- Check it has been rounded up
                    ORDER BY Fractional_Part ASC
                )
                UPDATE sr
                SET 
                    sr.Rounded_Value = sr.Rounded_Value - 1,
                    sr.Adj = COALESCE(sr.Adj, 0) - 1
                FROM Sys_Rounded_Recc sr
                JOIN targets tgt 
                ON sr.UserID = tgt.UserID
                AND sr.ReportID = tgt.ReportID
                AND sr.Category_Code = tgt.Category_Code
                AND sr.Hierarchy = tgt.Hierarchy
                AND sr.Hierarchy_Code = tgt.Hierarchy_Code
                AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE sr.Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);
            END
            ELSE
            BEGIN
                WITH targets AS (
                    SELECT TOP (@TopCount)
                        ReportID,
                        UserID,
                        Category_Code,
                        Hierarchy,
                        Hierarchy_Code
                    FROM Sys_Rounded_Recc
                    WHERE UserID = @UserID AND ReportID = @ReportID  AND Hierarchy = @Hierarchy
                    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END)
                    AND Rounded_Value - FLOOR(Rounded_Value) = 0 -- Check for whole bays
                    AND Rounded_Value < (Max_Bays + 1)
                    AND Bays > Rounded_Value -- Check it has been rounded down
                    AND Rounded_Value + 1 >= BayRoundingThreshold -- Check it is at BRT
                    ORDER BY Fractional_Part DESC
                )
                UPDATE sr
                SET 
                    sr.Rounded_Value = sr.Rounded_Value + 1,
                    sr.Adj = COALESCE(sr.Adj, 0) + 1
                FROM Sys_Rounded_Recc sr
                JOIN targets tgt
                ON sr.UserID = tgt.UserID
                AND sr.ReportID = tgt.ReportID
                AND sr.Category_Code = tgt.Category_Code
                AND sr.Hierarchy = tgt.Hierarchy
                AND sr.Hierarchy_Code = tgt.Hierarchy_Code
                AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE sr.Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);
            END;

    
    SELECT
    @SumMade = SUM(Rounded_Value)
    FROM Sys_Rounded_Recc
    WHERE UserID = @UserID AND ReportID = @ReportID AND Hierarchy = @Hierarchy
    AND (CASE WHEN @Hierarchy = 3 THEN 1 ELSE Hierarchy_Code END) = (CASE WHEN @Hierarchy = 3 THEN 1 ELSE @Hierarchy_Code END);
    
    --PRINT 'Sum acheieved for hierarchy ' + CAST(@Hierarchy AS NVARCHAR(1)) + ' with code ' + CAST(@Hierarchy_Code AS NVARCHAR(100)) + ' is ' + CAST(@SumMade AS NVARCHAR(255));
    --SET @SQL_Success = 1;
    --SET @SQL_Message = @SortOrder + ' for Hier ' + CAST(@Hierarchy AS NVARCHAR(50)) + ' code ' + CAST(@Hierarchy_Code AS NVARCHAR(50)) + ' Required: ' + CAST(@SumReqd AS NVARCHAR(50)) + ' Made: ' + CAST(@SumMade AS NVARCHAR(50));
    SET NOCOUNT OFF;
END;

GO

