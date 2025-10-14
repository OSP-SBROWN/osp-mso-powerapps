
-- ============================================================================
-- Procedure:    ReportsUpsertRVARow
-- Description:  Checks if a row exists for the given @ReportID in 
--               ReportVersionAttributes. If it does, Update; otherwise Insert.
--               Also creates a backup of ReportVersionAttributes named 
--               T_ReportVersionAttributes_YYYYMMDDHHMMSS upon success.
-- ============================================================================
CREATE   PROCEDURE [ui].[ReportsUpsertRVARow]
    @ReportID                 INT,
    @ReportOwnerID            INT = NULL,
    @BranchNumber             INT = NULL,
    @PerfStartDate            INT = NULL,
    @PerfEndDate              INT = NULL,
    @MacroSpaceDate           INT = 0,
    @Cohort                   NVARCHAR(MAX) = NULL,
    @CohortStores             INT = NULL,
    @BranchName               NVARCHAR(MAX) = '',
    @FullBaySize              DECIMAL(18, 2) = NULL,
    @RoundBaySize             DECIMAL(18, 2) = NULL,
    @DaysTrading              FLOAT = NULL,
    @UseTrend                 CHAR(1) = '',
    @PotentialSalesAdjustment DECIMAL(18, 2) = NULL,
    @CubeFlex                 DECIMAL(18, 2) = NULL,
    @UnitSalesMix_UserSet     FLOAT = NULL,
    @ValueSalesMix_UserSet    FLOAT = NULL,
    @ProfitSalesMix_UserSet   FLOAT = NULL,
    @SalesLessWaste_UserSet   FLOAT = NULL,
    @SalesProfitMix_UserSet   FLOAT = NULL,
    @SalesMixCube_UserSet     FLOAT = NULL,
    @DOSCasePack_UserSet      FLOAT = 0,
    @FixtureDensity_UserSet   FLOAT = NULL,
    @MixIncCohort_UserSet     FLOAT = NULL,
    @SpaceAdjustment          DECIMAL(18, 2) = NULL,
    @ElasticitySalesDiff      DECIMAL(18, 2) = NULL,
    @DoSDefault               FLOAT = NULL,
    @CasesDefault             FLOAT = NULL,
    @BayRoundingThreshold     FLOAT = NULL,
    @PerfDateExclusions       NVARCHAR(MAX) = '',
    @ExcludeCategories        NVARCHAR(MAX) = '',
    @ReportName               NVARCHAR(MAX) = '',
    @Status                   NVARCHAR(128) = '',
    @UMDID                    CHAR(15) = '',
    @RefreshTypeNeeded        NVARCHAR(128) = '',
    @DisplayGranularity       NVARCHAR(1),
    @SQL_Success              BIT            OUTPUT,
    @SQL_Message              NVARCHAR(255)  OUTPUT,
    @GeneratedReportID        INT            OUTPUT
AS
BEGIN

    -- DECLARE @BackupTableName SYSNAME;
    -- -- For example, T_ReportVersionAttributes_20250402123045
    -- SET @BackupTableName = 'T_ReportVersionAttributes_' 
    --     + CONVERT(VARCHAR(8), GETDATE(), 112)  -- YYYYMMDD
    --     + '_'
    --     + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');  -- HHMMSS

    -- DECLARE @SQLString NVARCHAR(MAX) = 
    --     N'SELECT * INTO ' + QUOTENAME(@BackupTableName)
    --     + N' FROM ReportVersionAttributes;';

    -- EXEC sp_executesql @SQLString;

    DECLARE @BackupColumnName VARCHAR(50);
    SET @BackupColumnName = CONVERT(VARCHAR(8), GETDATE(), 112)  + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
    
    INSERT INTO Rva_Archive SELECT @BackupColumnName, * FROM ReportVersionAttributes WHERE ReportID = @ReportID AND ReportOwner = @ReportOwnerID;

    BEGIN TRY
        BEGIN TRANSACTION;

        ------------------------------------------------------------------
        -- 1) Check if the given @ReportID already exists in the table
        ------------------------------------------------------------------
        IF EXISTS (
            SELECT 1
            FROM ReportVersionAttributes
            WHERE ReportID = @ReportID
        )
        BEGIN
            ------------------------------------------------------------------
            -- 2) Row exists → perform the UPDATE
            ------------------------------------------------------------------
            UPDATE ReportVersionAttributes
            SET 
                ReportOwner       
      = @ReportOwnerID,
                BranchNumber            = @BranchNumber,
                PerfStartDate           = @PerfStartDate,
                PerfEndDate             = @PerfEndDate,
                MacroSpaceDate          = CAST(@MacroSpaceDate AS NVARCHAR(8)),
                ViewbyStoreTempcatDept  = @DisplayGranularity,
                Cohort                  = @Cohort,
                CohortStores            = @CohortStores,
                BranchName              = @BranchName,
                FullBaySize             = @FullBaySize,
                RoundBaySize            = @RoundBaySize,
                DaysTrading             = @DaysTrading,
                UseTrend                = @UseTrend,
                PotentialSalesAdjustment= @PotentialSalesAdjustment,
                CubeFlex                = @CubeFlex,
                UnitSalesMix_UserSet    = @UnitSalesMix_UserSet,
                ValueSalesMix_UserSet   = @ValueSalesMix_UserSet,
                ProfitSalesMix_UserSet  = @ProfitSalesMix_UserSet,
                SalesLessWaste_UserSet  = @SalesLessWaste_UserSet,
                SalesProfitMix_UserSet  = @SalesProfitMix_UserSet,
                SalesMixCube_UserSet    = @SalesMixCube_UserSet,
                DOSCasePack_UserSet     = @DOSCasePack_UserSet,
                FixtureDensity_UserSet  = 0,
                MixIncCohort_UserSet    = @MixIncCohort_UserSet,
                SpaceAdjustment         = @SpaceAdjustment,
                ElasticitySalesDiff     = @ElasticitySalesDiff,
                DoSDefault              = @DoSDefault,
                CasesDefault            = @CasesDefault,
                BayRoundingThreshold    = @BayRoundingThreshold,
                PerfDateExclusions      = @PerfDateExclusions,
                ExcludeCategories       = @ExcludeCategories,
                ReportName              = @ReportName,
                [Status]                = @Status,
                UMDID                   = @UMDID,
                RefreshTypeNeeded       = @RefreshTypeNeeded
            WHERE ReportID = @ReportID;

            -- Return values for an UPDATE
            SET @SQL_Success       = 1;
            SET @SQL_Message       = N'UPDATE successful.';
            SET @GeneratedReportID = @ReportID;  -- The same ID (updated row)
        END
        ELSE
        BEGIN
            PRINT 'INSERT code triggered...';
            ------------------------------------------------------------------
            -- 3) Row does NOT exist → perform the INSERT
            ------------------------------------------------------------------
            SET @GeneratedReportID = ISNULL(
                (
                    SELECT TOP 1 ReportID
                    FROM ReportVersionAttributes
                    ORDER BY ReportID DESC
                ),
                0
            ) + 1;

            INSERT INTO ReportVersionAttributes
            (
                ReportID,
                ReportOwner,
                BranchNumber,
                PerfStartDate,
                PerfEndDate,
                MacroSpaceDate,
                Cohort,
                CohortStores,
                BranchName,
                ViewbyStoreTempcatDept,
                FullBaySize,
                RoundBaySize,
                DaysTrading,
                UseTrend,
                PotentialSalesAdjustment,
                CubeFlex,
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
                DoSDefault,
                CasesDefault,
               
 BayRoundingThreshold,
                PerfDateExclusions,
                ExcludeCategories,
                ReportName,
                [Status],
                UMDID,
                RefreshTypeNeeded
            )
            VALUES
            (
                @GeneratedReportID,
                @ReportOwnerID,
                @BranchNumber,
                @PerfStartDate,
                @PerfEndDate,
                CAST(@MacroSpaceDate AS NVARCHAR(8)),
                @Cohort,
                @CohortStores,
                @BranchName,
                @DisplayGranularity,
                @FullBaySize,
                @RoundBaySize,
                @DaysTrading,
                @UseTrend,
                @PotentialSalesAdjustment,
                @CubeFlex,
                @UnitSalesMix_UserSet,
                @ValueSalesMix_UserSet,
                @ProfitSalesMix_UserSet,
                @SalesLessWaste_UserSet,
                @SalesProfitMix_UserSet,
                @SalesMixCube_UserSet,
                @DOSCasePack_UserSet,
                @FixtureDensity_UserSet,
                @MixIncCohort_UserSet,
                @SpaceAdjustment,
                @ElasticitySalesDiff,
                @DoSDefault,
                @CasesDefault,
                @BayRoundingThreshold,
                @PerfDateExclusions,
                @ExcludeCategories,
                @ReportName,
                @Status,
                @UMDID,
                @RefreshTypeNeeded
            );

            -- Return values for an INSERT
            SET @SQL_Success = 1;
            SET @SQL_Message = 'INSERT successful.';
        END;

        COMMIT TRANSACTION;

        ----------------------------------------------------------------------
        -- 4) Create the backup table IF the Upsert was successful
        ----------------------------------------------------------------------

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        SET @SQL_Success       = 0;
        SET @SQL_Message       = ERROR_MESSAGE();
        SET @GeneratedReportID = NULL;
    END CATCH;
END;

GO

