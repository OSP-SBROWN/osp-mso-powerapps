
CREATE PROCEDURE [ui].[AddCatGetProductData]
    @ReportID INT = NULL,
    @BranchNumber INT,
    @CategoryCode INT,
    @SQL_Message NVARCHAR(100) OUTPUT,  -- Output parameter to return the success/failure message
    @SQL_Success INT OUTPUT
    
AS
BEGIN
    SET NOCOUNT ON;
    SET @SQL_Success = 1
    DECLARE @ResultCode INT = 0;  -- Default to success


    IF @ReportID IS NOT NULL
    BEGIN
        DECLARE 
            @Cohort NVARCHAR(50) = NULL,
            @MacroSpaceDate DATE = NULL,
            @DoSDefault FLOAT = NULL,
            @CasesDefault FLOAT = NULL,
            @PerfDateExclusions NVARCHAR(MAX) = NULL,
            @PerfStartDate INT = NULL,
            @PerfEndDate INT = NULL,
            @UseTrend NVARCHAR(1) = NULL,
            @DaysTrading INT = NULL,
            @RowCount INT;

        DECLARE @Defaults TABLE (
            Cohort NVARCHAR(50),
            MacroSpaceDate DATE,
            DoSDefault FLOAT,
            CasesDefault FLOAT,
            PerfDateExclusions NVARCHAR(MAX),
            PerfStartDate INT,
            PerfEndDate INT,
            UseTrend NVARCHAR(1),
            DaysTrading INT
        );

        -- Populate defaults from ReportVersionAttributes table
        INSERT INTO @Defaults
        SELECT 
            Cohort,
            CAST(CAST(MacroSpaceDate AS VARCHAR(MAX)) AS DATE) AS MacroSpaceDate,
            DoSDefault,
            CasesDefault,
            PerfDateExclusions,
            PerfStartDate,
            PerfEndDate,
            UseTrend,
            DaysTrading
        FROM ReportVersionAttributes
        WHERE ReportID = @ReportID;

        -- Assign values from @Defaults table to variables
        SELECT
            @Cohort = Cohort,
            @MacroSpaceDate = MacroSpaceDate,
            @DoSDefault = DoSDefault,
            @CasesDefault = CasesDefault,
            @PerfDateExclusions = PerfDateExclusions,
            @PerfStartDate = PerfStartDate,
            @PerfEndDate = PerfEndDate,
            @UseTrend = UseTrend,
            @DaysTrading = DaysTrading
        FROM @Defaults;
    END

    DECLARE @ProductDataResults TABLE (
        Location_Code INT,
        Category_Code INT,
        Product_Code INT,
        Trend FLOAT,
        DOS_Target FLOAT,
        COS_Target FLOAT,
        Sales_Quantity INT,
        Sales_Value DECIMAL(18, 2),
        Profit_Value DECIMAL(18, 2),
        Sales_Less_Waste DECIMAL(18, 2),
        Position_TotalUnits INT,
        Product_Cube FLOAT,
        Product_CasePackUnits INT,
        Position_FacingsWide INT
    );

    -- Process Date Exclusions
    DECLARE @DateString NVARCHAR(MAX);

    IF (@PerfDateExclusions IS NOT NULL AND @PerfDateExclusions != 'None')
    BEGIN
        SET @DateString = REPLACE(REPLACE(@PerfDateExclusions, '(', ''), ')', '');
    END
    ELSE
    BEGIN
        SET @DateString =  '190001';   
    END

    -- Build dynamic SQL
    IF @ReportID IS NOT NULL
    BEGIN
        WITH perf AS (
            SELECT 
                Date_ID, 
                Location_Code, 
                Product_Code, 
                Sales_Quantity, 
                Sales_Value, 
                Profit_Value, 
                Sales_Less_Waste 
            FROM Perfmax
            WHERE
            Location_Code = @BranchNumber
            AND Date_ID NOT IN (SELECT value FROM STRING_SPLIT(@DateString, ','))
            AND Date_ID BETWEEN @PerfStartDate AND @PerfEndDate
        ),
        perfAvg AS (
            SELECT 
                Location_Code, 
                Product_Code, 
                COUNT(DISTINCT Date_ID) AS Weeks_On_Sale,
                SUM(Sales_Quantity) / COUNT(DISTINCT Date_ID) AS Sales_Quantity,
                SUM(Sales_Value) / COUNT(DISTINCT Date_ID) AS Sales_Value,
                SUM(Profit_Value) / COUNT(DISTINCT Date_ID) AS Profit_Value,
                SUM(Sales_Less_Waste) / COUNT(DISTINCT Date_ID) AS Sales_Less_Waste
            FROM perf
            GROUP BY Location_Code, Product_Code
        ),
        micro AS (
            SELECT * 
            FROM [Micro Space] 
            WHERE Location_Code = @BranchNumber 
            AND Category_Code = @CategoryCode
        ),
        macro AS (
            SELECT 
                [Location_Code], 
                [Category_Code], 
                CAST([Bays] AS FLOAT) AS [Bays], 
                [Create_Date] 
            FROM MacroSnapShot 
            WHERE Create_Date = @MacroSpaceDate 
            AND Location_Code = @BranchNumber 
            AND Category_Code = @CategoryCode
        ),
        hier AS (
            SELECT 
                m.Location_Code, 
                m.Category_Code, 
                h.Hierarchy3_Name AS Category_Name, 
                h.Hierarchy2_Code AS Department_Number,
                h.Hierarchy2_Name AS Department_Name, 
                h.FlowNumber AS Flow_Number, 
                h.Hierarchy1_Code AS Temp_Category_Number, 
                h.Hierarchy1_Name AS Temp_Category_Name,
                h.DOS AS DOS_Target, 
                h.COS AS COS_Target, 
                h.MinBays AS Min_Bays, 
                h.MaxBays AS Max_Bays, 
                h.Trend, 
                h.Exclude_from_analysis, 
                m.Bays AS Bays
            FROM HierarchyDetail h
            JOIN macro m ON m.Category_Code = h.Hierarchy3_Code
        ),
        tptu AS (
            SELECT 
                m.Product_Gtin AS Product_Code, 
                SUM(m.Position_TotalUnits) AS TotalUnits
            FROM micro m
            JOIN hier h ON m.Category_Code = h.Category_Code
            GROUP BY m.Product_Gtin
        ),
        gtin AS (
            SELECT 
                m.Category_Code, 
                m.Product_Gtin AS Product_Code, 
                m.Position_TotalUnits, 
                m.Product_Cube, 
                m.Product_CasePackUnits,  
                m.Position_FacingsWide, 
                h.Trend, 
                h.DOS_Target, 
                h.COS_Target
            FROM micro m
            JOIN hier h ON m.Category_Code = h.Category_Code
        ),
        gtinTptu AS (
            SELECT 
                g.Product_Code, 
                (CAST(g.Position_TotalUnits AS FLOAT) / CAST(t.TotalUnits AS FLOAT)) AS pct_ptu
            FROM gtin g
            JOIN tptu t ON g.Product_Code = t.Product_Code
        )
        SELECT
            p.Location_Code,
            u.Category_Code,
            p.Product_Code,
            u.Trend,
            u.DOS_Target,
            u.COS_Target,
            (p.Sales_Quantity * t.pct_ptu) AS Sales_Quantity,
            (p.Sales_Value * t.pct_ptu) AS Sales_Value,
            (p.Profit_Value * t.pct_ptu) AS Profit_Value,
            (p.Sales_Less_Waste * t.pct_ptu) AS Sales_Less_Waste,
            u.Position_TotalUnits,
            u.Product_Cube,
            u.Product_CasePackUnits,
            u.Position_FacingsWide
        FROM perfAvg p
        JOIN gtinTptu t ON p.Product_Code = t.Product_Code
        JOIN gtin u ON p.Product_Code = u.Product_Code;


            -- Get the row count
        SET @RowCount = @@ROWCOUNT;

        -- Check if any rows were returned
        IF @RowCount > 0
        BEGIN
            -- Set the output message to indicate success with the row count
            SET @SQL_Message = 'Success: ' + CAST(@RowCount AS NVARCHAR(10)) + ' rows found.';
        END
        ELSE
        BEGIN
            -- If no rows were returned, set the output message
            SET @SQL_Message = 'No data found for the given CategoryCode.';
            SET @SQL_Success = 0;
        END
    END
    ELSE
    BEGIN
        -- If the table does not exist, set a failure message
        SET @ResultCode = 200;  -- Indicate failure
        SET @SQL_Message = 'Error: Table does not exist.';
        SET @SQL_Success = 0;
    END;

    -- Select the results to return to the user
    SELECT * FROM @ProductDataResults;

END;

GO

