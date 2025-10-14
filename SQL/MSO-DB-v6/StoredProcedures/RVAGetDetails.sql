CREATE   PROCEDURE [ui].[RVAGetDetails]
    @ReportID INT,
    @RVA_ReportID INT OUTPUT,
    @RVA_ReportOwner VARCHAR(2) OUTPUT,
    @RVA_BranchNumber INT OUTPUT,
    @RVA_ReportName VARCHAR(MAX) OUTPUT,
    @RVA_PerfStartDate INT OUTPUT,
    @RVA_PerfEndDate INT OUTPUT,
    @RVA_MacroSpaceDate VARCHAR(8) OUTPUT,
    @RVA_Cohort VARCHAR(MAX) OUTPUT,
    @RVA_CohortStores SMALLINT OUTPUT,
    @RVA_BranchName VARCHAR(MAX) OUTPUT,
    @RVA_FullBaySize DECIMAL(18, 2) OUTPUT,
    @RVA_RoundBaySize DECIMAL(18, 2) OUTPUT,
    @RVA_UnitOfMeasure VARCHAR(MAX) OUTPUT,
    @RVA_DaysTrading INT OUTPUT,
    @RVA_ViewbyStoreTempcatDept VARCHAR(MAX) OUTPUT,
    @RVA_MinBaysforMaxRange CHAR(1) OUTPUT,
    @RVA_UseProductCube CHAR(1) OUTPUT,
    @RVA_UseTrend CHAR(1) OUTPUT,
    @RVA_UseMinLMtr CHAR(1) OUTPUT,
    @RVA_UseMaxLMtr CHAR(1) OUTPUT,
    @RVA_IncNumberofProducts CHAR(1) OUTPUT,
    @RVA_PotentialSalesAdjustment DECIMAL(18, 2) OUTPUT,
    @RVA_CubeFlex DECIMAL(18, 2) OUTPUT,
    @RVA_TopHighlight DECIMAL(18, 2) OUTPUT,
    @RVA_BottomHighlight DECIMAL(18, 2) OUTPUT,
    @RVA_UnitSalesMix_UserSet FLOAT OUTPUT,
    @RVA_ValueSalesMix_UserSet FLOAT OUTPUT,
    @RVA_ProfitSalesMix_UserSet FLOAT OUTPUT,
    @RVA_SalesLessWaste_UserSet FLOAT OUTPUT,
    @RVA_SalesProfitMix_UserSet FLOAT OUTPUT,
    @RVA_SalesMixCube_UserSet FLOAT OUTPUT,
    @RVA_DOSCasePack_UserSet FLOAT OUTPUT,
    @RVA_FixtureDensity_UserSet FLOAT OUTPUT,
    @RVA_MixIncCohort_UserSet FLOAT OUTPUT,
    @RVA_SpaceAdjustment DECIMAL(18, 2) OUTPUT,
    @RVA_ElasticitySalesDiff DECIMAL(18, 2) OUTPUT,
    @RVA_DensityMetric VARCHAR(MAX) OUTPUT,
    @RVA_UMDID CHAR(15) OUTPUT,
    @RVA_DoSDefault FLOAT OUTPUT,
    @RVA_CasesDefault FLOAT OUTPUT,
    @RVA_BayRoundingThreshold FLOAT OUTPUT,
    @RVA_PerfDateExclusions NVARCHAR(MAX) OUTPUT,
    @RVA_ExcludeCategories VARCHAR(MAX) OUTPUT,
    @RVA_RefreshTypeNeeded VARCHAR(MAX) OUTPUT,
    @RVA_BayRulesCount INT OUTPUT,
    @RVA_LastRefreshed NVARCHAR(50) OUTPUT,
    @RVA_CoreTablesCreated INT OUTPUT,
    @RVA_Status VARCHAR(25) OUTPUT,
    @RVA_Cluster_ID INT OUTPUT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message VARCHAR(255) OUTPUT
AS
BEGIN
    -- Initialize success and message output
    SET @SQL_Success = 0; -- Assume failure initially
    SET @SQL_Message = 'Procedure started.';

    BEGIN TRY
        -- Fetch all columns from ReportVersionAttributes based on the ReportID
        SELECT
            @RVA_ReportID = ReportID,
            @RVA_ReportOwner = RIGHT('00' + CAST(ReportOwner AS VARCHAR(2)), 2),
            @RVA_BranchNumber = BranchNumber,
            @RVA_ReportName = ReportName,
            @RVA_PerfStartDate = PerfStartDate,
            @RVA_PerfEndDate = PerfEndDate,
            @RVA_MacroSpaceDate = MacroSpaceDate,
            @RVA_Cohort = Cohort,
            @RVA_CohortStores = CohortStores,
            @RVA_BranchName = BranchName,
            @RVA_FullBaySize = FullBaySize,
            @RVA_RoundBaySize = RoundBaySize,
            @RVA_UnitOfMeasure = UnitOfMeasure,
            @RVA_DaysTrading = DaysTrading,
            @RVA_ViewbyStoreTempcatDept = ViewbyStoreTempcatDept,
            @RVA_MinBaysforMaxRange = MinBaysforMaxRange,
            @RVA_UseProductCube = UseProductCube,
            @RVA_UseTrend = UseTrend,
            @RVA_UseMinLMtr = UseMinLMtr,
            @RVA_UseMaxLMtr = UseMaxLMtr,
            @RVA_IncNumberofProducts = IncNumberofProducts,
            @RVA_PotentialSalesAdjustment = PotentialSalesAdjustment,
            @RVA_CubeFlex = CubeFlex,
            @RVA_TopHighlight = TopHighlight,
            @RVA_BottomHighlight = BottomHighlight,
            @RVA_UnitSalesMix_UserSet = UnitSalesMix_UserSet,
            @RVA_ValueSalesMix_UserSet = ValueSalesMix_UserSet,
            @RVA_ProfitSalesMix_UserSet = ProfitSalesMix_UserSet,
            @RVA_SalesLessWaste_UserSet = SalesLessWaste_UserSet
,
            @RVA_SalesProfitMix_UserSet = SalesProfitMix_UserSet,
            @RVA_SalesMixCube_UserSet = SalesMixCube_UserSet,
            @RVA_DOSCasePack_UserSet = DOSCasePack_UserSet,
            @RVA_FixtureDensity_UserSet = FixtureDensity_UserSet,
            @RVA_MixIncCohort_UserSet = MixIncCohort_UserSet,
            @RVA_SpaceAdjustment = SpaceAdjustment,
            @RVA_ElasticitySalesDiff = ElasticitySalesDiff,
            @RVA_DensityMetric = DensityMetric,
            @RVA_UMDID = UMDID,
            @RVA_DoSDefault = DoSDefault,
            @RVA_CasesDefault = CasesDefault,
            @RVA_BayRoundingThreshold = BayRoundingThreshold,
            @RVA_PerfDateExclusions = PerfDateExclusions,
            @RVA_ExcludeCategories = ExcludeCategories,
            @RVA_RefreshTypeNeeded = RefreshTypeNeeded,
            @RVA_BayRulesCount = BayRulesCount,
            @RVA_LastRefreshed = LastRefreshed,
            @RVA_CoreTablesCreated = CoreTablesCreated,
            @RVA_Status = Status,
            @RVA_Cluster_ID = Cluster_ID
        FROM ReportVersionAttributes
        WHERE ReportID = @ReportID;

        -- Check if a record was found
        IF @@ROWCOUNT = 0
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'No record found for the given ReportID.';
            RETURN;
        END

        -- Success
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Report details successfully retreived.';
    END TRY
    BEGIN CATCH
        -- Handle any errors
        SET @SQL_Success = 0;
        SET @SQL_Message = 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;

GO

