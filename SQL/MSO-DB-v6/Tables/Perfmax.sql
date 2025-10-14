CREATE TABLE [dbo].[Perfmax] (
    [Date_ID]          INT             NOT NULL,
    [Location_Code]    INT             NOT NULL,
    [Product_Code]     INT             NOT NULL,
    [Sales_Quantity]   INT             NOT NULL,
    [Sales_Value]      NUMERIC (18, 2) NULL,
    [Profit_Value]     NUMERIC (18, 2) NULL,
    [Sales_Less_Waste] NUMERIC (18, 2) NULL
);


GO

CREATE NONCLUSTERED INDEX [IX_Perfmax_DateLocation]
    ON [dbo].[Perfmax]([Date_ID] ASC, [Location_Code] ASC);


GO

CREATE NONCLUSTERED INDEX [IX_Perfmax_Location]
    ON [dbo].[Perfmax]([Location_Code] ASC);


GO

CREATE NONCLUSTERED INDEX [IX_Perfmax_Product]
    ON [dbo].[Perfmax]([Product_Code] ASC);


GO

