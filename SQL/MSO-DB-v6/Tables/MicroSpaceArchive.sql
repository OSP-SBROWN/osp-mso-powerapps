CREATE TABLE [dbo].[MicroSpaceArchive] (
    [Location_Code]               INT            NOT NULL,
    [Category_Code]               INT            NOT NULL,
    [Product_Gtin]                INT            NOT NULL,
    [Product_Name]                NVARCHAR (510) NOT NULL,
    [Product_Cube]                FLOAT (53)     NULL,
    [Position_MerchandisingStyle] NVARCHAR (64)  NOT NULL,
    [Product_CasePackUnits]       INT            NULL,
    [Position_FacingsWide]        INT            NULL,
    [Position_TotalUnits]         INT            NULL,
    [Create_Date]                 DATE           NULL
);


GO

