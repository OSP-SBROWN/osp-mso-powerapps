CREATE PROCEDURE [ui].[DuplicateReportVersionAttribute2]
    @OldReportID INT,
    @NewReportName NVARCHAR(MAX),
    @NewOwnerID NVARCHAR(4),
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Initialize outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'Procedure failed to complete.';

    DECLARE @NewReportID INT;

    BEGIN TRY
        -- Generate a new ReportID safely
        BEGIN TRAN;

        SELECT @NewReportID = ISNULL(MAX(ReportID), 0) + 1
        FROM dbo.ReportVersionAttributes WITH (TABLOCKX, HOLDLOCK);

        -- Insert new row with the generated ReportID
        INSERT INTO dbo.ReportVersionAttributes (
            ReportID,
            ReportOwner,
            BranchNumber,
            ReportName,
            PerfStartDate,
            PerfEndDate,
            MacroSpaceDate,
            Cohort,
            CohortStores,
            BranchName,
            FullBaySize,
            RoundBaySize,
            UnitOfMeasure,
            DaysTrading,
            ViewbyStoreTempcatDept,
            MinBaysforMaxRange,
            UseProductCube,
            UseTrend,
            UseMinLMtr,
            UseMaxLMtr,
            IncNumberofProducts,
            PotentialSalesAdjustment,
            CubeFlex,
            TopHighlight,
            BottomHighlight,
            UnitSalesMix_UserSet,
            ValueSalesMix_UserSet,
            ProfitSalesMix_UserSet,
            SalesLessWaste_UserSet,
            SalesProfitMix_UserSet,
            SalesMixCube_UserSet,
            DOSCasePack_UserSet,
            FixtureDensity_UserSet,
            MixIncCohort_UserSet,
            SpaceAdjustment,
            ElasticitySalesDiff,
            DensityMetric,
            UMDID,
            DoSDefault,
            CasesDefault,
            BayRoundingThreshold,
            PerfDateExclusions,
            ExcludeCategories,
            RefreshTypeNeeded,
            BayRulesCount,
            LastRefreshed,
            CoreTablesCreated,
            Status,
            Cluster_ID
        )
        SELECT
            @NewReportID,
            @NewOwnerID,
            BranchNumber,
            @NewReportName,
            PerfStartDate,
            PerfEndDate,
            MacroSpaceDate,
            Cohort,
            CohortStores,
            BranchName,
            FullBaySize,
            RoundBaySize,
            UnitOfMeasure,
            DaysTrading,
            ViewbyStoreTempcatDept,
            MinBaysforMaxRange,
            UseProductCube,
            UseTrend,
            UseMinLMtr,
            UseMaxLMtr,
            IncNumberofProducts,
            PotentialSalesAdjustment,
            CubeFlex,
            TopHighlight,
            BottomHighlight,
            UnitSalesMix_UserSet,
            ValueSalesMix_UserSet,
            ProfitSalesMix_UserSet,
            SalesLessWaste_UserSet,
            SalesProfitMix_UserSet,
            SalesMixCube_UserSet,
            DOSCasePack_UserSet,
            FixtureDensity_UserSet,
            MixIncCohort_UserSet,
            SpaceAdjustment,
            ElasticitySalesDiff,
            DensityMetric,
            UMDID,
            DoSDefault,
            CasesDefault,
            BayRoundingThreshold,
            PerfDateExclusions,
            ExcludeCategories,
            RefreshTypeNeeded,
            BayRulesCount,
            LastRefreshed,
            CoreTablesCreated,
            Status,
            Cluster_ID
        FROM dbo.ReportVersionAttributes
        WHERE ReportID = @OldReportID;

        -- Copy BayRules from old report to new
        INSERT INTO dbo.BayRules (ReportID, Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
        SELECT 
            @NewReportID,
            Granularity, 
            Gran_Code, 
            ApplyColumn, 
            ValueToSet, 
            Var_or_Col, 
            Group_Key
        FROM dbo.BayRules
        WHERE ReportID = @OldReportID
          AND Group_Key IN ('Drivers', 'Metrics', 'Rounding', 'Resize');

        COMMIT;

        SET @SQL_Success = 1;
        SET @SQL_Message = N'Procedure completed successfully. New ReportID: ' + CONVERT(NVARCHAR(10), @NewReportID);
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();
    END CATCH
END

GO

