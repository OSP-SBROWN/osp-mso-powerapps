CREATE PROCEDURE [ui].[StoreGenerateCore-NHV1]
    @UserID INT = NULL,
    @ReportID INT = NULL,
    @SQL_Success BIT OUTPUT,
    @SQL_Message VARCHAR(255) OUTPUT,
    @Output_Report NVARCHAR(MAX) OUTPUT
AS
-- NEW VERSION WHICH USES A COUNT OF DISTINCT OF WEEKS SPECIFIED IN THE RVA PerfStart PerfEnd VALUES
-- AND NOT THE THE COUNT OF WEEKS ON SALE FOR EACH PRODUCT
BEGIN
    SET NOCOUNT ON;

    -- Initialise outputs
    SET @SQL_Success = 1;
    SET @SQL_Message = 'Generate Core success';
    SET @Output_Report = '';

    -------------------------------------------------------------------------
    -- Load RVA values for the requested ReportID (unchanged pattern)
    -------------------------------------------------------------------------
    IF @ReportID IS NOT NULL AND (SELECT COUNT(*) FROM ReportVersionAttributes WHERE ReportID = @ReportID) > 0
    BEGIN
        DECLARE 
            @UMDID NVARCHAR(50) = NULL,           -- contains HierarchyVersion_ID as text
            @Cohort NVARCHAR(50) = NULL,
            @MacroSpaceDate DATE = NULL,
            @DoSDefault FLOAT = NULL,
            @CasesDefault FLOAT = NULL,
            @PerfDateExclusions NVARCHAR(MAX) = NULL,
            @PerfStartDate INT = NULL,
            @PerfEndDate INT = NULL,
            @UseTrend NVARCHAR(1) = NULL,
            @BranchNumber INT = NULL,
            @DaysTrading INT = NULL,
            @Status NVARCHAR(128),
            @BayRoundingThreshold FLOAT = NULL;

        -- Minimal change: read directly from RVA (no @Defaults temp table needed here)
        SELECT
            @UMDID = UMDID,
            @Cohort = Cohort,
            @MacroSpaceDate = CAST(CAST(MacroSpaceDate AS VARCHAR(MAX)) AS DATE),
            @DoSDefault = DoSDefault,
            @CasesDefault = CasesDefault,
            @PerfDateExclusions = PerfDateExclusions,
            @PerfStartDate = PerfStartDate,
            @PerfEndDate = PerfEndDate,
            @UseTrend = UseTrend,
            @BranchNumber = BranchNumber,
            @DaysTrading = DaysTrading,
            @Status = [Status],
            @BayRoundingThreshold = BayRoundingThreshold
        FROM ReportVersionAttributes
        WHERE ReportID = @ReportID;
---------------------------------------------------------------------
-- NEW (minimal): derive effective HierarchyVersion_ID
-- 1) Use explicit parameter if provided
-- 2) Otherwise TRY_CAST the UMDID (NVARCHAR) to INT
---------------------------------------------------------------------
DECLARE @EffectiveHierarchyVersion_ID INT = NULL;

SET @EffectiveHierarchyVersion_ID = TRY_CAST(@UMDID AS INT);

-- Validate the effective version value exists and is usable
IF @EffectiveHierarchyVersion_ID IS NULL
BEGIN
    SET @SQL_Success = 0;
    SET @SQL_Message = 'Invalid or missing HierarchyVersion_ID (UMDID not an integer and no override provided).';
    RETURN;
END;

-- Validate using HierarchyDetail only (authoritative table for versioning)
IF NOT EXISTS (
    SELECT 1
    FROM dbo.HierarchyDetail
    WHERE HierarchyVersion_ID = @EffectiveHierarchyVersion_ID
)
BEGIN
    SET @SQL_Success = 0;
    SET @SQL_Message = 'No HierarchyDetail rows found for the specified HierarchyVersion_ID.';
    RETURN;
END;

-- Ensure there is data for each level via HierarchyDetail
IF NOT EXISTS (
    SELECT 1
    FROM dbo.HierarchyDetail
    WHERE HierarchyVersion_ID = @EffectiveHierarchyVersion_ID
      AND Hierarchy1_Code IS NOT NULL
)
BEGIN
    SET @SQL_Success = 0;
    SET @SQL_Message = 'No Hierarchy1 data found for the specified HierarchyVersion_ID (via HierarchyDetail).';
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.HierarchyDetail
    WHERE HierarchyVersion_ID = @EffectiveHierarchyVersion_ID
      AND Hierarchy2_Code IS NOT NULL
)
BEGIN
    SET @SQL_Success = 0;
    SET @SQL_Message = 'No Hierarchy2 data found for the specified HierarchyVersion_ID (via HierarchyDetail).';
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.HierarchyDetail
    WHERE HierarchyVersion_ID = @EffectiveHierarchyVersion_ID
      AND Hierarchy3_Code IS NOT NULL
)
BEGIN
    SET @SQL_Success = 0;
    SET @SQL_Message = 'No Hierarchy3 data found for the specified HierarchyVersion_ID (via HierarchyDetail).';
    RETURN;
END;


        ---------------------------------------------------------------------
        -- Existing RVA presence checks
        ---------------------------------------------------------------------
        IF @UMDID IS NULL
        OR @Cohort IS NULL
        OR @MacroSpaceDate IS NULL
        OR @DoSDefault IS NULL
        OR @CasesDefault IS NULL
        OR @PerfStartDate IS NULL
        OR @PerfEndDate IS NULL
        OR @UseTrend IS NULL
        OR @BranchNumber IS NULL
        OR @DaysTrading IS NULL
        OR @BayRoundingThreshold IS NULL
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'Missing values in RVA';
            RETURN;
        END

        IF @Status = 'PerfLock'
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'Master data for this report is no longer available. Please duplicate the report, update the dates and execute.';
            RETURN;
        END

        ---------------------------------------------------------------------
        -- Existing logic continues (unchanged unless commented as NEW)
        ---------------------------------------------------------------------
        DECLARE @sql_string NVARCHAR(MAX);
        DECLARE @DateString NVARCHAR(MAX);

        DECLARE @sql NVARCHAR(MAX);

        DECLARE @ExcludedDates TABLE (Date_ID VARCHAR(50));

        IF (@PerfDateExclusions IS NOT NULL AND @PerfDateExclusions != 'None')
        BEGIN
            SET @DateString = REPLACE(REPLACE(@PerfDateExclusions, '(', ''), ')', '');
            INSERT INTO @ExcludedDates (Date_ID)
            SELECT TRIM(value) FROM STRING_SPLIT(@DateString, ',');
        END
        ELSE
        BEGIN
            INSERT INTO @ExcludedDates (Date_ID) VALUES ('190001');
        END

        SELECT 
            Date_ID, 
            Location_Code, 
            Product_Code, 
            Sales_Quantity, 
            Sales_Value, 
            Profit_Value, 
            Sales_Less_Waste 
        INTO #Perf
        FROM Perfmax
        WHERE Location_Code = @BranchNumber
          AND Date_ID BETWEEN @PerfStartDate AND @PerfEndDate
          AND NOT EXISTS (SELECT 1 FROM @ExcludedDates WHERE Date_ID = Perfmax.Date_ID);

        
        DROP TABLE IF EXISTS T_Perf;
        SELECT * INTO T_Perf FROM #Perf;

        -- Compute weeks count and guard against divide-by-zero (NEW safety)
        DECLARE @CountPerfWks INT = (SELECT COUNT(DISTINCT Date_ID) FROM #Perf);
        IF @CountPerfWks = 0
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'No performance weeks in the selected range after exclusions.';
            RETURN;
        END;

        -- Weekly averages (based on distinct weeks in period, not weeks-on-sale per SKU)
        SELECT Location_Code, Product_Code, COUNT(DISTINCT Date_ID) AS Weeks_On_Sale,
               SUM(Sales_Quantity) * 1.0 / @CountPerfWks AS Sales_Quantity,
               SUM(Sales_Value) * 1.0 / @CountPerfWks AS Sales_Value,
               SUM(Profit_Value) * 1.0 / @CountPerfWks AS Profit_Value,
               SUM(Sales_Less_Waste) * 1.0 / @CountPerfWks AS Sales_Less_Waste
        INTO #PerfAvg
        FROM #Perf
        GROUP BY Location_Code, Product_Code;

        DROP TABLE IF EXISTS T_PerfAvg;
        SELECT * INTO T_PerfAvg FROM #PerfAvg;

        -- Micro
        SELECT * INTO #Micro FROM [Micro Space] WHERE Location_Code = @BranchNumber;

        DROP TABLE IF EXISTS T_Micro;
        SELECT * INTO T_Micro FROM #Micro;

        -- Macro
        SELECT [Location_Code], [Category_Code], CAST([Bays] AS FLOAT) AS [Bays], [Create_Date]
        INTO #Macro
        FROM MacroSnapShot
        WHERE Create_Date = @MacroSpaceDate AND Location_Code = @BranchNumber;

        DROP TABLE IF EXISTS T_Macro;
        SELECT * INTO T_Macro FROM #Macro;

        ---------------------------------------------------------------------
        -- Macro + Hierarchy (VERSION-SCOPED)  *** NEW filter in WHERE ***
        ---------------------------------------------------------------------
        SELECT 
            m.Location_Code, 
            m.Category_Code, 
            h.Hierarchy3_Name AS Category_Name, 
            h.Hierarchy2_Code AS Department_Number,
            h.Hierarchy2_Name AS Department_Name, 
            h.FlowNumber AS Flow_Number, 
            h.Hierarchy1_Code AS Temp_Category_Number, 
            h.Hierarchy1_Name AS Temp_Category_Name,
            h.DOS AS DoS_Target, 
            h.COS AS Cases_Target, 
            h.MinBays AS Min_Bays, 
            h.MaxBays AS Max_Bays,
            ISNULL(h.BayRoundingThreshold, @BayRoundingThreshold) AS BayRoundingThreshold,
            h.Trend, 
            CASE WHEN h.Exclude_From_Analysis = 'Y' THEN 1 ELSE 0 END AS Exclude_From_Analysis,
            m.Bays
        INTO #MacroHier
        FROM dbo.HierarchyDetail h
        JOIN #Macro m 
          ON h.Hierarchy3_Code = m.Category_Code
        WHERE h.HierarchyVersion_ID = @EffectiveHierarchyVersion_ID;  -- NEW

        DROP TABLE IF EXISTS T_MacroHier;
        SELECT * INTO T_MacroHier FROM #MacroHier;

        -- Early fail if Macro categories did not match this version
        IF NOT EXISTS (SELECT 1 FROM #MacroHier)
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'No categories in Macro match the specified HierarchyVersion_ID.';
            RETURN;
        END;

        -- MacroHier + Micro
        WITH CTE_Tptu AS (
            SELECT ms.Product_Gtin, SUM(ms.Position_TotalUnits) AS TotalUnits
            FROM #Micro ms
            JOIN #MacroHier mh ON ms.Category_Code = mh.Category_Code
            GROUP BY ms.Product_Gtin
        ),
        CTE_Gtin AS (
            SELECT ms.Category_Code, ms.Product_Gtin, ms.Position_TotalUnits, ms.Product_Cube,
                   ms.Product_CasePackUnits, ms.Position_FacingsWide, mh.Trend, mh.DoS_Target, mh.Cases_Target
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
            g.Trend, 
            g.DoS_Target, 
            g.Cases_Target, 
            (CAST(g.Position_TotalUnits AS FLOAT) / CAST(t.TotalUnits AS FLOAT)) AS pct_ptu
        INTO #MacroHierMicro
        FROM CTE_Gtin g
        JOIN CTE_Tptu t ON g.Product_Gtin = t.Product_Gtin;

        DROP TABLE IF EXISTS T_MacroHierMicro;
        SELECT * INTO T_MacroHierMicro FROM #MacroHierMicro;

        -- Apply perf averages by product
        SELECT
            p.Location_Code,
            u.Category_Code,
            u.Product_Code,
            u.Trend,
            u.DoS_Target,
            u.Cases_Target,
            (p.Sales_Quantity * u.pct_ptu) AS Sales_Quantity,
            (p.Sales_Value * u.pct_ptu) AS Sales_Value,
            (p.Profit_Value * u.pct_ptu) AS Profit_Value,
            (p.Sales_Less_Waste * u.pct_ptu) AS Sales_Less_Waste,
            u.Position_TotalUnits,
            u.Product_Cube,
            u.Product_CasePackUnits,
            u.Position_FacingsWide
        INTO #MacroHierMicroPerfAvg
        FROM #PerfAvg p
        JOIN #MacroHierMicro u ON p.Product_Code = u.Product_Code;

        DROP TABLE IF EXISTS T_MacroHierMicroPerfAvg;
        SELECT * INTO T_MacroHierMicroPerfAvg FROM #MacroHierMicroPerfAvg;

        DECLARE @AvgCubeGlobal FLOAT = (SELECT AVG(Product_Cube) FROM #MacroHierMicroPerfAvg);

   

        -- Build #Products with version-scoped HierarchyFull (LEFT JOIN)
        SELECT
            p.Location_Code,
            p.Product_Code,
            p.Category_Code,
            h.Hierarchy3_Name AS Category_Name,
            h.Hierarchy2_Code AS Department_Number,
            h.Hierarchy2_Name AS Department_Name,
            h.Hierarchy1_Code AS Temp_Category_Number,
            h.Hierarchy1_Name AS Temp_Category_Name,
            p.Trend,
            p.DoS_Target,
            p.Cases_Target,
            p.Sales_Quantity,
            p.Sales_Value,
            p.Profit_Value,
            p.Sales_Less_Waste,
            p.Position_TotalUnits,
            p.Product_Cube,
            p.Product_CasePackUnits,
            p.Position_FacingsWide
        INTO #Products
        FROM #MacroHierMicroPerfAvg p
        LEFT JOIN dbo.HierarchyFull h
        ON p.Category_Code = h.Hierarchy3_Code;

        -- Product-level calcs
        ALTER TABLE #Products
        ADD 
            DOS FLOAT, 
            DOS_Target_Units FLOAT, 
            Cases_Target_Units FLOAT, 
            Units_Required INT,
            Dos_Units_Required INT,
            Facings_Required FLOAT;

        UPDATE #Products
        SET DOS = CASE WHEN Sales_Quantity = 0 
                       THEN 0 ELSE Position_TotalUnits / (CAST(Sales_Quantity AS FLOAT) / @DaysTrading) END;

        UPDATE #Products
        SET  DOS_Target_Units = CASE WHEN Sales_Quantity = 0 THEN 0 
                                     ELSE (Sales_Quantity / @DaysTrading) * DOS END;

        UPDATE #Products 
        SET Cases_Target_Units = Product_CasePackUnits * Cases_Target;

        -- Sum to category
        SELECT
            Location_Code,
            Category_Code,
            CASE WHEN @UseTrend = 'Y' THEN SUM(Sales_Quantity) * (1 + AVG(Trend))
                 ELSE SUM(Sales_Quantity) END AS Sales_Quantity,
            CASE WHEN @UseTrend = 'Y' THEN SUM(Sales_Value) * (1 + AVG(Trend))
                 ELSE SUM(Sales_Value) END AS Sales_Value,
            CASE WHEN @UseTrend = 'Y' THEN SUM(Profit_Value) * (1 + AVG(Trend))
                 ELSE SUM(Profit_Value) END AS Profit_Value,
            CASE WHEN @UseTrend = 'Y' THEN SUM(Sales_Less_Waste) * (1 + AVG(Trend))
                 ELSE SUM(Sales_Less_Waste) END AS Sales_Less_Waste,
            AVG(Trend) AS Avg_Trend,
            SUM(Sales_Quantity) AS Org_Sales_Quantity,
            SUM(Sales_Value) AS Org_Sales_Value,
            SUM(Profit_Value) AS Org_Profit_Value,
            SUM(Sales_Less_Waste) AS Org_Sales_Less_Waste
        INTO #MacroHierMicroPerfAvgSumGrp
        FROM #MacroHierMicroPerfAvg
        GROUP BY Location_Code, Category_Code;

        -- Combine with MacroHier to form #Category
        SELECT
            mh.Location_Code,
            mh.Category_Code,
            mh.Category_Name,
            mh.Department_Number,
            mh.Department_Name,
            mh.Flow_Number,
            mh.Temp_Category_Number,
            mh.Temp_Category_Name,
            mh.Bays,
            Org_Bays = mh.Bays,
            mh.Min_Bays,
            mh.Max_Bays,
            mh.BayRoundingThreshold,
            mh.DoS_Target,
            mh.Cases_Target,
            mh.Exclude_From_Analysis,
            ps.Sales_Quantity,
            ps.Sales_Value,
            ps.Profit_Value,
            ps.Sales_Less_Waste,
            ps.Avg_Trend,
            ps.Org_Sales_Quantity,
            ps.Org_Sales_Value,
            ps.Org_Profit_Value,
            ps.Org_Sales_Less_Waste
        INTO #Category
        FROM #MacroHier mh
        JOIN #MacroHierMicroPerfAvgSumGrp ps
          ON mh.Category_Code = ps.Category_Code;

        -- Add many calc columns (initialised to 0 per existing pattern)
        ALTER TABLE #Category
        ADD
            Department_Sub VARCHAR(255),
            UnitSalesMix_UserSet FLOAT,
            ValueSalesMix_UserSet FLOAT,
            ProfitSalesMix_UserSet FLOAT,
            SalesLessWaste_UserSet  FLOAT,
            SalesProfitMix_UserSet  FLOAT,
            SalesMixCube_UserSet  FLOAT,
            DOSCasePack_UserSet  FLOAT,
            FixtureDensity_UserSet FLOAT,
            MixIncCohort_UserSet FLOAT,
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
            Department_Sub = NULL,
            UnitSalesMix_UserSet = 0,
            ValueSalesMix_UserSet = 0,
            ProfitSalesMix_UserSet = 0,
            SalesLessWaste_UserSet  = 0,
            SalesProfitMix_UserSet  = 0,
            SalesMixCube_UserSet  = 0,
            DOSCasePack_UserSet  = 0,
            FixtureDensity_UserSet = 0,
            MixIncCohort_UserSet = 0,
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

        -- Push average DoS/Cases down to #Category from #Products
        WITH TargetSums AS (
            SELECT Category_Code, 
                   ROUND(AVG(DoS_Target), 2) AS AvgDosTarget, 
                   ROUND(AVG(Cases_Target), 2) AS AvgCasesTarget 
            FROM #Products 
            GROUP BY Category_Code
        )
        UPDATE cc
           SET cc.DoS_Target = ts.AvgDosTarget,
               cc.Cases_Target = ts.AvgCasesTarget
        FROM #Category cc
        JOIN TargetSums ts ON cc.Category_Code = ts.Category_Code;

        -- Snapshot for output tables
        SELECT @UserID AS UserID, @ReportID AS ReportID, * 
        INTO #Category_final
        FROM #Category;

        -- Refresh MSO_Reports for this user/report
        DELETE FROM MSO_Reports WHERE UserID = @UserID AND ReportID = @ReportID;

        INSERT INTO MSO_Reports (
            UserID, ReportID, Location_Code, Category_Code, Category_Name, Department_Number, Department_Sub,
            Flow_Number, Department_Name, Temp_Category_Number, Temp_Category_Name, Avg_Trend, Sales_Quantity,
            Sales_Value, Profit_Value, Sales_Less_Waste, Org_Sales_Quantity, Org_Sales_Value, Org_Profit_Value,
            Org_Sales_Less_Waste, Bays, Min_Bays, Max_Bays, Exclude_from_analysis, DoS_Target, Cases_Target,
            Org_Bays, UnitSalesMix_UserSet, ValueSalesMix_UserSet, ProfitSalesMix_UserSet, SalesLessWaste_UserSet,
            SalesProfitMix_UserSet, SalesMixCube_UserSet, DOSCasePack_UserSet, FixtureDensity_UserSet,
            MixIncCohort_UserSet, BayRoundingThreshold, Category_QuantCont_Pt, Depart_QuantCont_Pt,
            Temp_QuantCont_Pt, Category_ValueCont_Pt, Depart_ValueCont_Pt, Temp_ValueCont_Pt,
            Category_ProfitCont_Pt, Depart_ProfitCont_Pt, Temp_ProfitCont_Pt, Category_WasteCont_Pt,
            Depart_WasteCont_Pt, Temp_WasteCont_Pt, Store_PerfMix_Pt, Dept_PerfMix_Pt, Temp_PerfMix_Pt,
            Store_BaysPerfMix, Dept_BaysPerfMix, Temp_BaysPerfMix, Store_Ranking, Dept_Ranking, Temp_Ranking,
            Sum_Cubes, Products_Count, Cat_ProdCube_Avg, Store_ProdCube_Avg, Dept_ProdCube_Avg, Temp_ProdCube_Avg,
            Store_ProdCat_Avg, Dept_ProdCat_Avg, Temp_ProdCat_Avg, Store_ProdCubeRatio, Dept_ProdCubeRatio,
            Temp_ProdCubeRatio, Store_BaysFlex_PerfMix, Dept_BaysFlex_PerfMix, Temp_BaysFlex_PerfMix,
            Bays_Req_Target, Org_Bays_Req_Target, Store_DOSCOS_Bays, Dept_DOSCOS_Bays, Temp_DOSCOS_Bays,
            Store_Bays_Recc, Dept_Bays_Recc, Temp_Bays_Recc, Org_Store_Bays_Recc, Org_Dept_Bays_Recc,
            Org_Temp_Bays_Recc, DoSTargetAchieved, CaseTargetAchieved, BothTargetAchieved,
            Store_Projected_Sales_Quantity, Store_Projected_Org_Sales_Quantity, Store_Projected_Sales_Value,
            Store_Projected_Org_Sales_Value, Store_Projected_Profit_Value, Store_Projected_Org_Profit_Value,
            Store_Projected_Sales_Less_Waste, Store_Projected_Org_Sales_Less_Waste,
            Dept_Projected_Sales_Quantity, Dept_Projected_Org_Sales_Quantity, Dept_Projected_Sales_Value,
            Dept_Projected_Org_Sales_Value, Dept_Projected_Profit_Value, Dept_Projected_Org_Profit_Value,
            Dept_Projected_Sales_Less_Waste, Dept_Projected_Org_Sales_Less_Waste,
            Temp_Projected_Sales_Quantity, Temp_Projected_Org_Sales_Quantity, Temp_Projected_Sales_Value,
            Temp_Projected_Org_Sales_Value, Temp_Projected_Profit_Value, Temp_Projected_Org_Profit_Value,
            Temp_Projected_Sales_Less_Waste, Temp_Projected_Org_Sales_Less_Waste
        )
        SELECT
            UserID,
            ReportID,
            CAST(Location_Code AS BIGINT),
            CAST(Category_Code AS BIGINT),
            Category_Name,
            FORMAT(CAST(Department_Number AS BIGINT), '0'),
            Department_Sub,
            Flow_Number,
            Department_Name,
            FORMAT(CAST(Temp_Category_Number AS BIGINT), '0'),
            Temp_Category_Name,
            Avg_Trend,
            Sales_Quantity,
            Sales_Value,
            Profit_Value,
            Sales_Less_Waste,
            Org_Sales_Quantity,
            Org_Sales_Value,
            Org_Profit_Value,
            Org_Sales_Less_Waste,
            Bays,
            Min_Bays,
            Max_Bays,
            Exclude_From_Analysis AS Exclude_from_analysis,
            DoS_Target,
            Cases_Target,
            Org_Bays,
            UnitSalesMix_UserSet,
            ValueSalesMix_UserSet,
            ProfitSalesMix_UserSet,
            SalesLessWaste_UserSet,
            SalesProfitMix_UserSet,
            SalesMixCube_UserSet,
            DOSCasePack_UserSet,
            FixtureDensity_UserSet,
            MixIncCohort_UserSet,
            BayRoundingThreshold,
            Category_QuantCont_Pt,
            Depart_QuantCont_Pt,
            Temp_QuantCont_Pt,
            Category_ValueCont_Pt,
            Depart_ValueCont_Pt,
            Temp_ValueCont_Pt,
            Category_ProfitCont_Pt,
            Depart_ProfitCont_Pt,
            Temp_ProfitCont_Pt,
            Category_WasteCont_Pt,
            Depart_WasteCont_Pt,
            Temp_WasteCont_Pt,
            Store_PerfMix_Pt,
            Dept_PerfMix_Pt,
            Temp_PerfMix_Pt,
            Store_BaysPerfMix,
            Dept_BaysPerfMix,
            Temp_BaysPerfMix,
            Store_Ranking,
            Dept_Ranking,
            Temp_Ranking,
            Sum_Cubes,
            Products_Count,
            Cat_ProdCube_Avg,
            Store_ProdCube_Avg,
            Dept_ProdCube_Avg,
            Temp_ProdCube_Avg,
            Store_ProdCat_Avg,
            Dept_ProdCat_Avg,
            Temp_ProdCat_Avg,
            Store_ProdCubeRatio,
            Dept_ProdCubeRatio,
            Temp_ProdCubeRatio,
            Store_BaysFlex_PerfMix,
            Dept_BaysFlex_PerfMix,
            Temp_BaysFlex_PerfMix,
            Bays_Req_Target,
            Org_Bays_Req_Target,
            Store_DOSCOS_Bays,
            Dept_DOSCOS_Bays,
            Temp_DOSCOS_Bays,
            Store_Bays_Recc,
            Dept_Bays_Recc,
            Temp_Bays_Recc,
            Org_Store_Bays_Recc,
            Org_Dept_Bays_Recc,
            Org_Temp_Bays_Recc,
            DoSTargetAchieved,
            CaseTargetAchieved,
            BothTargetAchieved,
            Store_Projected_Sales_Quantity,
            Store_Projected_Org_Sales_Quantity,
            Store_Projected_Sales_Value,
            Store_Projected_Org_Sales_Value,
            Store_Projected_Profit_Value,
            Store_Projected_Org_Profit_Value,
            Store_Projected_Sales_Less_Waste,
            Store_Projected_Org_Sales_Less_Waste,
            Dept_Projected_Sales_Quantity,
            Dept_Projected_Org_Sales_Quantity,
            Dept_Projected_Sales_Value,
            Dept_Projected_Org_Sales_Value,
            Dept_Projected_Profit_Value,
            Dept_Projected_Org_Profit_Value,
            Dept_Projected_Sales_Less_Waste,
            Dept_Projected_Org_Sales_Less_Waste,
            Temp_Projected_Sales_Quantity,
            Temp_Projected_Org_Sales_Quantity,
            Temp_Projected_Sales_Value,
            Temp_Projected_Org_Sales_Value,
            Temp_Projected_Profit_Value,
            Temp_Projected_Org_Profit_Value,
            Temp_Projected_Sales_Less_Waste,
            Temp_Projected_Org_Sales_Less_Waste
        FROM #Category_final;

        -- Refresh MSO_Products for this user/report
        DELETE FROM MSO_Products WHERE UserID = @UserID AND ReportID = @ReportID;

        INSERT INTO MSO_Products (
            UserID, ReportID, Location_Code, Product_Code, Category_Code, Category_Name, Department_Number,
            Department_Name, Temp_Category_Number, Temp_Category_Name, Trend, DoS_Target, Cases_Target,
            Sales_Quantity, Sales_Value, Profit_Value, Sales_Less_Waste, Position_TotalUnits, Product_Cube,
            Product_CasePackUnits, Position_FacingsWide, DOS, DOS_Target_Units, Cases_Target_Units,
            Units_Required, Dos_Units_Required, Facings_Required
        )
        SELECT
            @UserID AS UserID,
            @ReportID AS ReportID,
            Location_Code,
            Product_Code,
            Category_Code,
            Category_Name,
            Department_Number,
            Department_Name,
            Temp_Category_Number,
            Temp_Category_Name,
            Trend,
            DoS_Target,
            Cases_Target,
            Sales_Quantity,
            Sales_Value,
            Profit_Value,
            Sales_Less_Waste,
            Position_TotalUnits,
            Product_Cube,
            Product_CasePackUnits,
            Position_FacingsWide,
            DOS,
            DOS_Target_Units,
            Cases_Target_Units,
            Units_Required,
            Dos_Units_Required,
            Facings_Required
        FROM #Products;

    END
    ELSE
    BEGIN
        -- ReportID missing or not found in RVA
        PRINT 'Error: Input cannot be NULL.';
        SET @SQL_Success = 0;
        SET @SQL_Message = 'ReportID does not exist in RVA';
        RETURN;
    END

    -- Final outputs (per your pattern)
    SET NOCOUNT OFF;
    SET @SQL_Success = 1;
    SET @SQL_Message = 'Generate Core success';
    SET @Output_Report = '';
END;

GO

