CREATE TABLE [Ver_001].[RVA_Params] (
    [ParamID]                  INT            IDENTITY (1, 1) NOT NULL,
    [ParamName]                VARCHAR (7)    NOT NULL,
    [FullBaySize]              DECIMAL (5, 2) NULL,
    [RoundBaySize]             DECIMAL (5, 2) NULL,
    [DaysTrading]              INT            NULL,
    [MinBaysforMaxRange]       CHAR (1)       NULL,
    [UseProductCube]           CHAR (1)       NULL,
    [UseTrend]                 CHAR (1)       NULL,
    [UseMinLMtr]               CHAR (1)       NULL,
    [UseMaxLMtr]               CHAR (1)       NULL,
    [IncNumberofProducts]      CHAR (1)       NULL,
    [PotentialSalesAdjustment] DECIMAL (5, 4) NULL,
    [CubeFlex]                 DECIMAL (5, 4) NULL,
    [UnitSalesMix_UserSet]     FLOAT (53)     NULL,
    [ValueSalesMix_UserSet]    FLOAT (53)     NULL,
    [ProfitSalesMix_UserSet]   FLOAT (53)     NULL,
    [SalesLessWaste_UserSet]   FLOAT (53)     NULL,
    [SalesProfitMix_UserSet]   FLOAT (53)     NULL,
    [SalesMixCube_UserSet]     FLOAT (53)     NULL,
    [DOSCasePack_UserSet]      FLOAT (53)     NULL,
    [FixtureDensity_UserSet]   FLOAT (53)     NULL,
    [MixIncCohort_UserSet]     FLOAT (53)     NULL,
    [SpaceAdjustment]          DECIMAL (5, 4) NULL,
    [ElasticitySalesDiff]      DECIMAL (5, 4) NULL,
    [DoSDefault]               FLOAT (53)     NULL,
    [CasesDefault]             FLOAT (53)     NULL,
    [BayRoundingThreshold]     FLOAT (53)     NULL,
    [RefreshTypeNeeded]        TEXT           NULL
);


GO

