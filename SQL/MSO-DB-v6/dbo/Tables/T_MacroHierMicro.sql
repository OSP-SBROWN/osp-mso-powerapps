CREATE TABLE [dbo].[T_MacroHierMicro] (
    [Category_Code]         INT            NOT NULL,
    [Product_Code]          INT            NOT NULL,
    [Position_TotalUnits]   INT            NULL,
    [Product_Cube]          FLOAT (53)     NULL,
    [Product_CasePackUnits] INT            NULL,
    [Position_FacingsWide]  INT            NULL,
    [TotalUnits]            INT            NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [DoS_Target]            DECIMAL (5, 1) NULL,
    [Cases_Target]          DECIMAL (5, 1) NULL,
    [pct_ptu]               FLOAT (53)     NULL
);
GO

