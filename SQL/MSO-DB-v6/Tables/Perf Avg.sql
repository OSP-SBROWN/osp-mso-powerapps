CREATE TABLE [dbo].[Perf Avg] (
    [Location_Code]    NUMERIC (4)      NOT NULL,
    [Product_Code]     NUMERIC (10)     NOT NULL,
    [Weeks_On_Sale]    INT              NULL,
    [Sales_Quantity]   NUMERIC (24, 12) NULL,
    [Sales_Value]      NUMERIC (38, 6)  NULL,
    [Profit_Value]     NUMERIC (38, 6)  NULL,
    [Sales_Less_Waste] NUMERIC (38, 6)  NULL
);


GO

