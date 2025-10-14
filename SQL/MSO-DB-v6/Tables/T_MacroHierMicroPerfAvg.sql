CREATE TABLE [dbo].[T_MacroHierMicroPerfAvg] (
    [Location_Code]         INT            NOT NULL,
    [Category_Code]         INT            NOT NULL,
    [Product_Code]          INT            NOT NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [DoS_Target]            DECIMAL (5, 1) NULL,
    [Cases_Target]          DECIMAL (5, 1) NULL,
    [Sales_Quantity]        FLOAT (53)     NULL,
    [Sales_Value]           FLOAT (53)     NULL,
    [Profit_Value]          FLOAT (53)     NULL,
    [Sales_Less_Waste]      FLOAT (53)     NULL,
    [Position_TotalUnits]   INT            NULL,
    [Product_Cube]          FLOAT (53)     NULL,
    [Product_CasePackUnits] INT            NULL,
    [Position_FacingsWide]  INT            NULL
);
GO

