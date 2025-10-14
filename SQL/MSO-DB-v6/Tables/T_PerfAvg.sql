CREATE TABLE [dbo].[T_PerfAvg] (
    [Location_Code]    INT              NOT NULL,
    [Product_Code]     INT              NOT NULL,
    [Weeks_On_Sale]    INT              NULL,
    [Sales_Quantity]   NUMERIC (24, 12) NULL,
    [Sales_Value]      NUMERIC (38, 6)  NULL,
    [Profit_Value]     NUMERIC (38, 6)  NULL,
    [Sales_Less_Waste] NUMERIC (38, 6)  NULL
);
GO

