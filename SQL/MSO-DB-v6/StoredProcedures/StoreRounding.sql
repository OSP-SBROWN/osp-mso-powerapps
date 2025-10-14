
CREATE PROCEDURE [dbo].[StoreRounding]
    @ReportID INT,
    @UserID INT,
    @MinBayFraction FLOAT,
    @Rounding_Success BIT OUTPUT


AS
BEGIN
    SET NOCOUNT ON;

    --SET @ResultCode = 0;  -- Default to success
    SET @Rounding_Success = 0;

    DECLARE @SumReqd FLOAT;
    DECLARE @SumMade FLOAT;
    DECLARE @Diff FLOAT;
    DECLARE @SortOrder VARCHAR(4);
    DECLARE @TopCount INT;
    DECLARE @Hierarchy INT;
    DECLARE @Hierarchy_Code INT;
    DECLARE @Hierarchy_Name VARCHAR(255);
    DECLARE @ReccBay VARCHAR(255);
    DECLARE @OrgReccBays VARCHAR(255);
    DECLARE @SRRcount INT;

    DECLARE @Iteration INT = 1; -- Example loop counter

    WHILE @Iteration <= 3
    BEGIN
        -- Update variables for this iteration
        IF @Iteration = 1 
        BEGIN
            SET @Hierarchy = 3;
            SET @Hierarchy_Code = 0;
            SET @Hierarchy_Name = 'Category_Code';
            SET @ReccBay = 'Store_Bays_Recc';
            SET @OrgReccBays = 'Org_Store_Bays_Recc';
        END
        ELSE IF @Iteration = 2
        BEGIN
            SET @Hierarchy = 2;
            SET @Hierarchy_Name = 'Department_Number';
            SET @ReccBay = 'Dept_Bays_Recc';
            SET @OrgReccBays = 'Org_Dept_Bays_Recc';
        END
        ELSE IF @Iteration = 3
        BEGIN
            SET @Hierarchy = 1;
            SET @Hierarchy_Name = 'Temp_Category_Number';
            SET @ReccBay = 'Temp_Bays_Recc';
            SET @OrgReccBays = 'Org_Temp_Bays_Recc';
        END;

        -- Create the SQL template
        DECLARE @SQLTemplate NVARCHAR(MAX) = '
        SELECT
            UserID,
            ReportID,
            Category_Code,
            Department_Number,
            Temp_Category_Number,
            Bays,
            Min_Bays,
            Max_Bays,
            BayRoundingThreshold,
            ' + QUOTENAME(@OrgReccBays) + N' AS Original_Bays,
            ' + QUOTENAME(@ReccBay) + N' AS Recc_Bays
        INTO #ReccBays
        FROM MSO_Reports
        WHERE UserID = @UserID AND ReportID = @ReportID AND Exclude_from_analysis = 0;

        DELETE FROM Sys_Rounded_Recc
        WHERE UserID = @UserID AND ReportID = @ReportID AND Hierarchy = @Hierarchy;

        WITH wholePart AS (
            SELECT
                Category_Code,
                CAST(Original_Bays AS INT) AS whole_part
            FROM #ReccBays
        ),
        fractionalPart AS (
            SELECT
                rb.Category_Code,
                (Original_Bays - wp.whole_part) AS fractional_part
            FROM #ReccBays rb
            JOIN wholePart wp
            ON rb.Category_Code = wp.Category_Code
        )
        INSERT INTO Sys_Rounded_Recc (
            UserID,
            ReportID,
            Category_Code,
            Hierarchy,
            Hierarchy_Code,
            Bays,
            Recc_Bays,
            Original_Bays,
            Fractional_Part,
            Max_Bays,
            Min_Bays,
            BayRoundingThreshold,
            Rounded_Value
        )
        SELECT
            @UserID AS UserID,
            @ReportID AS ReportID,
            rb.Category_Code,
            @Hierarchy AS Hierarchy,
            rb.' + @Hierarchy_Name + N' AS Hierarchy_Code,
            Bays,
            Recc_Bays,
            Original_Bays,
            fp.fractional_part AS Fractional_Part,
            Max_Bays,
            Min_Bays,
            BayRoundingThreshold,
            CASE
                WHEN Original_Bays < BayRoundingThreshold THEN
                    FLOOR(Original_Bays / @MinBayFraction) * @MinBayFraction +
                    CASE
                        WHEN (Original_Bays - FLOOR(Original_Bays / @MinBayFraction) * @MinBayFraction) >= (@MinBayFraction / 2)
                        THEN @MinBayFraction
                        ELSE 0
                    END
                ELSE
                    CASE
                        WHEN fp.fractional_part >= @MinBayFraction THEN
                            CAST((wp.whole_part + 1) AS FLOAT)
                        ELSE
                            CAST(wp.whole_part AS FLOAT)
                    END
            END AS Rounded_Value
        FROM #ReccBays rb
        JOIN wholePart wp
        ON rb.Category_Code = wp.Category_Code
        JOIN fractionalPart fp
        ON rb.Category_Code = fp.Category_Code;
        ';

        -- Execute the SQL template
        EXEC sp_executesql 
            @SQLTemplate,
            N'@UserID INT, 
            @ReportID INT, 
            @MinBayFraction FLOAT, 
            @Hierarchy INT,
            @ReccBay VARCHAR(255),
            @OrgReccBays VARCHAR(255),
            @Hierarchy_Name VARCHAR(255)', 
            @UserID = @UserID, 
            @ReportID = @ReportID, 
            @MinBayFraction = @MinBayFraction, 
            @Hierarchy = @Hierarchy,
            @ReccBay = @ReccBay,
            @OrgReccBays = @OrgReccBays,
            @Hierarchy_Name = @Hierarchy_Name;

        IF @Iteration = 1
        BEGIN
            --PRINT 'OUTBOUND StoreRounding is calling with Hierarchy: ' + CAST(@Hierarchy AS NVARCHAR(1)) + ' USING code: ' + CAST(@Hierarchy_Code AS NVARCHAR(100)) + ' the iteration is ' + CAST(@Iteration AS NVARCHAR(1))
                EXEC [dbo].[StoreRoundingFunction]
                @ReportID,
                @UserID,           -- Replace with the actual UserID
                @MinBayFraction, -- Replace with the desired min_bay_fraction
                @Hierarchy_Code,
                @Hierarchy;
                --@SQL_Success = @SQL_Success OUTPUT,
                --@SQL_Message = @SQL_Message OUTPUT;
           
        END
        ELSE --IF @Iteration = 2 OR 3
        BEGIN
            DECLARE dept_cursor CURSOR FOR
            SELECT DISTINCT Hierarchy_Code
            FROM Sys_Rounded_Recc
            WHERE ReportID = @ReportID
            AND UserID = @UserID
            AND Hierarchy = @Hierarchy;
            
            OPEN dept_cursor;

            FETCH NEXT FROM dept_cursor INTO @Hierarchy_Code;
            --PRINT 'OUTBOUND StoreRounding is calling with Hierarchy: ' + CAST(@Hierarchy AS NVARCHAR(1)) + ' USING code: ' + CAST(@Hierarchy_Code AS NVARCHAR(100)) + ' the iteration is ' + CAST(@Iteration AS NVARCHAR(1))
            WHILE @@FETCH_STATUS = 0
                BEGIN
                EXEC [dbo].[StoreRoundingFunction]
                        @ReportID,
                        @UserID,           -- Replace with the actual UserID
                        @MinBayFraction, -- Replace with the desired min_bay_fraction
                        @Hierarchy_Code,
                        @Hierarchy;
                        --@SQL_Success = @SQL_Success OUTPUT,
                        --@SQL_Message = @SQL_Message OUTPUT;

                FETCH NEXT FROM dept_cursor INTO @Hierarchy_Code;
                END

            CLOSE dept_cursor;
            DEALLOCATE dept_cursor;
        END;
        
        -- Increment the iteration counter
        SET @Iteration += 1;
    END;

    SELECT @SRRcount = COUNT(*)
    FROM Sys_Rounded_Recc
    WHERE UserID = @UserID AND ReportID = @ReportID;
    --PRINT @SRRcount;

    IF @SRRcount > 0
        SET @Rounding_Success = 1;
    ELSE
        SET @Rounding_Success = 0;
    SET NOCOUNT OFF;
END;

GO

