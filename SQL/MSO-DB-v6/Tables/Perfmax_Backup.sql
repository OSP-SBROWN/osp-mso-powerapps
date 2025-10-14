CREATE TABLE [dbo].[Perfmax_Backup] (
    [Location_Code]    NUMERIC (4)     NOT NULL,
    [Date_ID]          NUMERIC (6)     NOT NULL,
    [Product_Code]     NUMERIC (10)    NOT NULL,
    [Sales_Quantity]   INT             NOT NULL,
    [Sales_Value]      DECIMAL (18, 2) NULL,
    [Profit_Value]     DECIMAL (18, 2) NULL,
    [Sales_Less_Waste] DECIMAL (18, 2) NULL
);


GO

