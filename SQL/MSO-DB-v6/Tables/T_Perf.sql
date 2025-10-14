CREATE TABLE [dbo].[T_Perf] (
    [Date_ID]          INT             NOT NULL,
    [Location_Code]    INT             NOT NULL,
    [Product_Code]     INT             NOT NULL,
    [Sales_Quantity]   INT             NOT NULL,
    [Sales_Value]      NUMERIC (18, 2) NULL,
    [Profit_Value]     NUMERIC (18, 2) NULL,
    [Sales_Less_Waste] NUMERIC (18, 2) NULL
);
GO

