
CREATE PROCEDURE [ui].[AddCatToCore]
    @UserID INT = NULL,
    @ReportID INT = NULL,
    @NewCategoryCode INT,
    @SourceBranchNumber INT,
    @ResultCode INT OUTPUT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT

AS
BEGIN
    SET NOCOUNT ON;

    SET @ResultCode = 0;  -- Default to success
    Set @SQL_Success=1;

    BEGIN TRY
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
            @BranchNumber INT = NULL,
            @DaysTrading INT = NULL;

        DECLARE @Defaults TABLE (
            Cohort NVARCHAR(50),
            MacroSpaceDate DATE,
            DoSDefault FLOAT,
            CasesDefault FLOAT,
            PerfDateExclusions NVARCHAR(MAX),
            PerfStartDate INT,
            PerfEndDate INT,
            UseTrend NVARCHAR(1),
            BranchNumber INT,
            DaysTrading INT
        );

        -- Populate defaults from ReportVersionAttributes table
        INSERT INTO @Defaults
        SELECT 
            Cohort,
            CAST(CAST(MacroSpaceDate AS NVARCHAR(MAX)) AS DATE) AS MacroSpaceDate,
            DoSDefault,
            CasesDefault,
            PerfDateExclusions,
            PerfStartDate,
            PerfEndDate,
            UseTrend,
            BranchNumber,
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
            @BranchNumber = BranchNumber,
            @DaysTrading = DaysTrading
        FROM @Defaults;
    END
    ELSE
    BEGIN
        -- If ReportID is NULL, return an error code
        SET @SQL_Message = 'This Report cannot be found.';
        SET @ResultCode = -1;  -- Error: No ReportID provided
        RETURN @ResultCode;
    END

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

    SELECT Date_ID, Location_Code, Product_Code, Sales_Quantity, Sales_Value, Profit_Value, Sales_Less_Waste 
    INTO #Perf
    FROM Perfmax
    WHERE 
    Location_Code = @SourceBranchNumber
    AND Date_ID NOT IN (SELECT value FROM STRING_SPLIT(@DateString, ','))
    AND Date_ID BETWEEN @PerfStartDate AND @PerfEndDate;


    -- Calculate weekly performance averages and store in #PerfAvg
    SELECT Location_Code, Product_Code, COUNT(DISTINCT Date_ID) AS Weeks_On_Sale,
        SUM(Sales_Quantity) / COUNT(DISTINCT Date_ID) AS Sales_Quantity,
        SUM(Sales_Value) / COUNT(DISTINCT Date_ID) AS Sales_Value,
        SUM(Profit_Value) / COUNT(DISTINCT Date_ID) AS Profit_Value,
        SUM(Sales_Less_Waste) / COUNT(DISTINCT Date_ID) AS Sales_Less_Waste
    INTO #PerfAvg
    FROM #Perf
    GROUP BY Location_Code, Product_Code;

    -- Populate #Micro table
    SELECT * INTO #Micro FROM [Micro Space] WHERE Location_Code = @SourceBranchNumber AND Category_Code = @NewCategoryCode;

    -- Populate #Macro table
    SELECT [Location_Code], [Category_Code], CAST([Bays] AS FLOAT) AS [Bays], [Create_Date]
    INTO #Macro
    FROM MacroSnapShot
    WHERE Create_Date = @MacroSpaceDate AND Location_Code = @SourceBranchNumber AND Category_Code = @NewCategoryCode;

    -- Populate #MacroHier
    SELECT m.Location_Code, m.Category_Code, h.Hierarchy3_Name AS Category_Name, h.Hierarchy2_Code AS Department_Number,
        h.Hierarchy2_Name AS Department_Name, h.FlowNumber AS Flow_Number, h.Hierarchy1_Code AS Temp_Category_Number, 
        h.Hierarchy1_Name AS Temp_Category_Name,
        h.DOS AS Dos_Target, h.COS AS Cases_Target, h.MinBays AS Min_Bays, h.MaxBays as Max_Bays, h.Trend, h.Exclude_from_analysis, m.Bays AS Bays
    INTO #MacroHier
    FROM HierarchyDetail h
    JOIN #Macro m 
    ON h.Hierarchy3_Code = m.Category_Code;

    -- Calculate and populate #MacroHierMicro
    WITH CTE_Tptu AS (
        SELECT ms.Product_Gtin, SUM(ms.Position_TotalUnits) AS TotalUnits
        FROM #Micro ms
        JOIN #MacroHier mh ON ms.Category_Code = mh.Category_Code
        GROUP BY ms.Product_Gtin
    ),
    CTE_Gtin AS (
        SELECT 
        ms.Category_Code, 
        ms.Product_Gtin, 
        ms.Position_TotalUnits, 
        ms.Product_Cube, 
        ms.Product_CasePackUnits,  
        ms.Position_FacingsWide,
        mh.Category_Name,
        mh.Department_Number,
        mh.Department_Name,
        mh.Temp_Category_Number,
        mh.Temp_Category_Name,
        mh.Trend, 
        mh.Dos_Target, 
        mh.Cases_Target
        FROM #Micro ms
        JOIN #MacroHier mh ON ms.Category_Code = mh.Category_Code
    )
    SELECT 
    g.Category_Code, 
    g.Product_Gtin AS Product_Code, 
    g.Position_TotalUnits, 
    g.Product_Cube, 
    g.Product_CasePackUnits,
    g.Position_FacingsWide, 
    t.TotalUnits,
    g.Category_Name,
    g.Department_Number,
    g.Department_Name,
    g.Temp_Category_Number,
    g.Temp_Category_Name,
    g.Trend, 
    g.Dos_Target, 
    g.Cases_Target, 
    (CAST(g.Position_TotalUnits AS FLOAT) / CAST(t.TotalUnits AS FLOAT)) AS pct_ptu
    INTO #MacroHierMicro
    FROM CTE_Gtin g
    JOIN CTE_Tptu t ON g.Product_Gtin = t.Product_Gtin;

    SELECT
        p.Location_Code,
        u.Product_Code,
        u.Category_Code,
        u.Category_Name,
        u.Department_Number,
        u.Department_Name,
        u.Temp_Category_Number,
        u.Temp_Category_Name,
        u.Trend,
        u.Dos_Target,
        u.Cases_Target,
        (p.Sales_Quantity * u.pct_ptu) AS Sales_Quantity,
        (p.Sales_Value * u.pct_ptu) AS Sales_Value,
        (p.Profit_Value * u.pct_ptu) AS Profit_Value,
        (p.Sales_Less_Waste * u.pct_ptu) AS Sales_Less_Waste,
        u.Position_TotalUnits,
        u.Product_Cube,
        u.Product_CasePackUnits,
        u.Position_FacingsWide
    INTO 
        #MacroHierMicroPerfAvg
    FROM
        #PerfAvg p
    JOIN 
        #MacroHierMicro u
    ON 
        p.Product_Code = u.Product_Code;

    SELECT * INTO #Products FROM #MacroHierMicroPerfAvg;

    ALTER TABLE #Products
    ADD 
        DOS FLOAT, 
        Dos_Target_Units FLOAT, 
        Cases_Target_Units FLOAT, 
        Units_Required INT,
        Dos_Units_Required INT,
        Facings_Required FLOAT;

    UPDATE #Products
    SET 
        DOS = CASE WHEN Sales_Quantity = 0 
        THEN 0 ELSE Position_TotalUnits / (CAST(Sales_Quantity AS FLOAT) / @DaysTrading) END;

    UPDATE #Products
    SET Dos_Target_Units = CASE WHEN Sales_Quantity = 0 THEN 0 
    ELSE (Sales_Quantity / @DaysTrading) * Dos_Target END;


    UPDATE #Products 
    SET 
        Cases_Target_Units = Product_CasePackUnits * Cases_Target;

    SELECT
        Location_Code,
        Category_Code,
        SUM(Sales_Quantity) * CASE WHEN @UseTrend = 'Y' THEN (1 + AVG(Trend)) ELSE 1 END AS Sales_Quantity,
        SUM(Sales_Value) * CASE WHEN @UseTrend = 'Y' THEN (1 + AVG(Trend)) ELSE 1 END AS Sales_Value,
        SUM(Profit_Value) * CASE WHEN @UseTrend = 'Y' THEN (1 + AVG(Trend)) ELSE 1 END AS Profit_Value,
        SUM(Sales_Less_Waste) * CASE WHEN @UseTrend = 'Y' THEN (1 + AVG(Trend)) ELSE 1 END AS Sales_Less_Waste,
        SUM(Sales_Quantity) AS Org_Sales_Quantity,
        SUM(Sales_Value) AS Org_Sales_Value,
        SUM(Profit_Value) AS Org_Profit_Value,
        SUM(Sales_Less_Waste) AS Org_Sales_Less_Waste,
        AVG(Trend) AS Avg_Trend
    INTO 
        #MacroHierMicroPerfAvgSumGrp
    FROM 
        #MacroHierMicroPerfAvg
    GROUP BY 
        Location_Code, Category_Code;

    SELECT
        mh.Location_Code,
        mh.Category_Code,
        mh.Category_Name,
        mh.Department_Number,
        'a' AS Department_Sub,
        mh.Flow_Number,
        mh.Department_Name,
        mh.Temp_Category_Number,
        mh.Temp_Category_Name,
        ps.Avg_Trend,
        (ps.Sales_Quantity / Bays) * 0.001 AS Sales_Quantity,
        (ps.Sales_Value / Bays) * 0.001 AS Sales_Value,
        (ps.Profit_Value / Bays) * 0.001 AS Profit_Value,
        (ps.Sales_Less_Waste / Bays) * 0.001 AS Sales_Less_Waste,
        (ps.Org_Sales_Quantity / Bays) * 0.001 AS Org_Sales_Quantity,
        (ps.Org_Sales_Value / Bays) * 0.001 AS Org_Sales_Value,
        (ps.Org_Profit_Value / Bays) * 0.001 AS Org_Profit_Value,
        (ps.Org_Sales_Less_Waste / Bays) * 0.001 AS Org_Sales_Less_Waste,
        0.001 AS Bays,
        mh.Min_Bays,
        mh.Max_Bays,
        'N' AS Exclude_from_analysis,
        mh.Dos_Target,
        mh.Cases_Target,
        0.001 AS Org_Bays
    INTO #Category
    FROM #MacroHier mh
    JOIN
    #MacroHierMicroPerfAvgSumGrp ps
    ON mh.Category_Code = ps.Category_Code;

    WITH TargetSums AS (
        SELECT 
            Category_Code, 
            ROUND(AVG(Dos_Target), 2) AS AvgDosTarget, 
            ROUND(AVG(Cases_Target), 2) AS AvgCasesTarget 
        FROM #Products 
        GROUP BY Category_Code
    )
    UPDATE sc
    SET
        sc.Dos_Target = ts.AvgDosTarget,
        sc.Cases_Target = ts.AvgCasesTarget
    FROM #Category sc
    JOIN TargetSums ts ON sc.Category_Code = ts.Category_Code;

    ALTER TABLE #Category
    ADD
    UnitSalesMix_UserSet FLOAT,
    ValueSalesMix_UserSet FLOAT,
    ProfitSalesMix_UserSet FLOAT,
    SalesLessWaste_UserSet  FLOAT,
    SalesProfitMix_UserSet  FLOAT,
    SalesMixCube_UserSet  FLOAT,
    DOSCasePack_UserSet  FLOAT,
    FixtureDensity_UserSet FLOAT,
    MixIncCohort_UserSet FLOAT,
    BayRoundingThreshold FLOAT,
    Category_QuantCont_Pt FLOAT, 
    Depart_QuantCont_Pt FLOAT,
    Temp_QuantCont_Pt FLOAT,
    Category_ValueCont_Pt FLOAT,
    Depart_ValueCont_Pt FLOAT,
    Temp_ValueCont_Pt FLOAT,
    Category_ProfitCont_Pt FLOAT,
    Depart_ProfitCont_Pt FLOAT,
    Temp_ProfitCont_Pt FLOAT,
    Category_WasteCont_Pt FLOAT,
    Depart_WasteCont_Pt FLOAT,
    Temp_WasteCont_Pt FLOAT,
    Store_PerfMix_Pt FLOAT,
    Dept_PerfMix_Pt FLOAT,
    Temp_PerfMix_Pt FLOAT,
    Store_BaysPerfMix FLOAT,
    Dept_BaysPerfMix FLOAT,
    Temp_BaysPerfMix FLOAT,
    Store_Ranking INT,
    Dept_Ranking INT,
    Temp_Ranking INT,
    Sum_Cubes FLOAT,
    Products_Count FLOAT,
    Cat_ProdCube_Avg FLOAT,
    Store_ProdCube_Avg FLOAT,
    Dept_ProdCube_Avg FLOAT,
    Temp_ProdCube_Avg FLOAT,
    Store_ProdCat_Avg FLOAT,
    Dept_ProdCat_Avg FLOAT,
    Temp_ProdCat_Avg FLOAT,
    Store_ProdCubeRatio FLOAT,
    Dept_ProdCubeRatio FLOAT,
    Temp_ProdCubeRatio FLOAT,
    Store_BaysFlex_PerfMix FLOAT,
    Dept_BaysFlex_PerfMix FLOAT,
    Temp_BaysFlex_PerfMix FLOAT,
    Bays_Req_Target FLOAT,
    Org_Bays_Req_Target FLOAT,
    Store_DOSCOS_Bays FLOAT,
    Dept_DOSCOS_Bays FLOAT,
    Temp_DOSCOS_Bays FLOAT,
    Store_Bays_Recc FLOAT,
    Dept_Bays_Recc FLOAT,
    Temp_Bays_Recc FLOAT,
    Org_Store_Bays_Recc FLOAT,
    Org_Dept_Bays_Recc FLOAT,
    Org_Temp_Bays_Recc FLOAT,
    DoSTargetAchieved FLOAT,
    CaseTargetAchieved FLOAT,
    BothTargetAchieved FLOAT,
    Store_Projected_Sales_Quantity FLOAT,
    Store_Projected_Org_Sales_Quantity FLOAT,
    Store_Projected_Sales_Value FLOAT,
    Store_Projected_Org_Sales_Value FLOAT,
    Store_Projected_Profit_Value FLOAT,
    Store_Projected_Org_Profit_Value FLOAT,
    Store_Projected_Sales_Less_Waste FLOAT,
    Store_Projected_Org_Sales_Less_Waste FLOAT,
    Dept_Projected_Sales_Quantity FLOAT,
    Dept_Projected_Org_Sales_Quantity FLOAT,
    Dept_Projected_Sales_Value FLOAT,
    Dept_Projected_Org_Sales_Value FLOAT,
    Dept_Projected_Profit_Value FLOAT,
    Dept_Projected_Org_Profit_Value FLOAT,
    Dept_Projected_Sales_Less_Waste FLOAT,
    Dept_Projected_Org_Sales_Less_Waste FLOAT,
    Temp_Projected_Sales_Quantity FLOAT,
    Temp_Projected_Org_Sales_Quantity FLOAT,
    Temp_Projected_Sales_Value FLOAT,
    Temp_Projected_Org_Sales_Value FLOAT,
    Temp_Projected_Profit_Value FLOAT,
    Temp_Projected_Org_Profit_Value FLOAT,
    Temp_Projected_Sales_Less_Waste FLOAT,
    Temp_Projected_Org_Sales_Less_Waste FLOAT;

    UPDATE #Category
    SET
    UnitSalesMix_UserSet = 0,
    ValueSalesMix_UserSet = 0,
    ProfitSalesMix_UserSet = 0,
    SalesLessWaste_UserSet  = 0,
    SalesProfitMix_UserSet  = 0,
    SalesMixCube_UserSet  = 0,
    DOSCasePack_UserSet  = 0,
    FixtureDensity_UserSet = 0,
    MixIncCohort_UserSet = 0,
    BayRoundingThreshold = 0,
    Category_QuantCont_Pt = 0, 
    Depart_QuantCont_Pt = 0,
    Temp_QuantCont_Pt = 0,
    Category_ValueCont_Pt = 0,
    Depart_ValueCont_Pt = 0,
    Temp_ValueCont_Pt = 0,
    Category_ProfitCont_Pt = 0,
    Depart_ProfitCont_Pt = 0,
    Temp_ProfitCont_Pt = 0,
    Category_WasteCont_Pt = 0,
    Depart_WasteCont_Pt = 0,
    Temp_WasteCont_Pt = 0,
    Store_PerfMix_Pt = 0,
    Dept_PerfMix_Pt = 0,
    Temp_PerfMix_Pt = 0,
    Store_BaysPerfMix = 0,
    Dept_BaysPerfMix = 0,
    Temp_BaysPerfMix = 0,
    Store_Ranking = 0,
    Dept_Ranking = 0,
    Temp_Ranking = 0,
    Sum_Cubes = 0,
    Products_Count = 0,
    Cat_ProdCube_Avg = 0,
    Store_ProdCube_Avg = 0,
    Dept_ProdCube_Avg = 0,
    Temp_ProdCube_Avg = 0,
    Store_ProdCat_Avg = 0,
    Dept_ProdCat_Avg = 0,
    Temp_ProdCat_Avg = 0,
    Store_ProdCubeRatio = 0,
    Dept_ProdCubeRatio = 0,
    Temp_ProdCubeRatio = 0,
    Store_BaysFlex_PerfMix = 0,
    Dept_BaysFlex_PerfMix = 0,
    Temp_BaysFlex_PerfMix = 0,
    Bays_Req_Target = 0,
    Org_Bays_Req_Target = 0,
    Store_DOSCOS_Bays = 0,
    Dept_DOSCOS_Bays = 0,
    Temp_DOSCOS_Bays = 0,
    Store_Bays_Recc = 0,
    Dept_Bays_Recc = 0,
    Temp_Bays_Recc = 0,
    Org_Store_Bays_Recc = 0,
    Org_Dept_Bays_Recc = 0,
    Org_Temp_Bays_Recc = 0,
    DoSTargetAchieved = 0,
    CaseTargetAchieved = 0,
    BothTargetAchieved = 0,
    Store_Projected_Sales_Quantity = 0,
    Store_Projected_Org_Sales_Quantity = 0,
    Store_Projected_Sales_Value = 0,
    Store_Projected_Org_Sales_Value = 0,
    Store_Projected_Profit_Value = 0,
    Store_Projected_Org_Profit_Value = 0,
    Store_Projected_Sales_Less_Waste = 0,
    Store_Projected_Org_Sales_Less_Waste = 0,
    Dept_Projected_Sales_Quantity = 0,
    Dept_Projected_Org_Sales_Quantity = 0,
    Dept_Projected_Sales_Value = 0,
    Dept_Projected_Org_Sales_Value = 0,
    Dept_Projected_Profit_Value = 0,
    Dept_Projected_Org_Profit_Value = 0,
    Dept_Projected_Sales_Less_Waste = 0,
    Dept_Projected_Org_Sales_Less_Waste = 0,
    Temp_Projected_Sales_Quantity = 0,
    Temp_Projected_Org_Sales_Quantity = 0,
    Temp_Projected_Sales_Value = 0,
    Temp_Projected_Org_Sales_Value = 0,
    Temp_Projected_Profit_Value = 0,
    Temp_Projected_Org_Profit_Value = 0,
    Temp_Projected_Sales_Less_Waste = 0,
    Temp_Projected_Org_Sales_Less_Waste = 0;


    UPDATE #category
    SET 
        Exclude_from_analysis = 
        CASE 
            WHEN Exclude_from_analysis = 'Y' THEN 1
            WHEN Exclude_from_analysis = 'N' THEN 0
            ELSE 0 -- Optional: Handle unexpected values if necessary
        END;

    INSERT INTO 
        MSO_Reports 
    SELECT
        @UserID AS UserID, 
        @ReportID AS ReportID, 
        * 
    FROM 
        #Category;

    SELECT * FROM #Category;

    INSERT INTO 
        MSO_Products
    SELECT
        @UserID AS UserID, 
        @ReportID AS ReportID, 
        * 
    FROM 
        #Products;

;




SET @SQL_Success = 1;
        SET @SQL_Message = 'Procedure executed successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        
        SET @SQL_Success = 1;
        SET @SQL_Message = 'An error occurred: ' + @ErrorMessage;
    END CATCH
END;

GO

