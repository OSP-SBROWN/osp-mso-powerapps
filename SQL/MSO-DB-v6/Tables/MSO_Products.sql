CREATE TABLE [dbo].[MSO_Products] (
    [UserID]                INT           NOT NULL,
    [ReportID]              INT           NOT NULL,
    [Location_Code]         NUMERIC (4)   NOT NULL,
    [Product_Code]          INT           NOT NULL,
    [Category_Code]         INT           NOT NULL,
    [Category_Name]         VARCHAR (255) NULL,
    [Department_Number]     VARCHAR (255) NULL,
    [Department_Name]       VARCHAR (255) NULL,
    [Temp_Category_Number]  VARCHAR (255) NULL,
    [Temp_Category_Name]    VARCHAR (255) NULL,
    [Trend]                 FLOAT (53)    NULL,
    [DoS_Target]            FLOAT (53)    NULL,
    [Cases_Target]          FLOAT (53)    NULL,
    [Sales_Quantity]        FLOAT (53)    NULL,
    [Sales_Value]           FLOAT (53)    NULL,
    [Profit_Value]          FLOAT (53)    NULL,
    [Sales_Less_Waste]      FLOAT (53)    NULL,
    [Position_TotalUnits]   FLOAT (53)    NULL,
    [Product_Cube]          FLOAT (53)    NULL,
    [Product_CasePackUnits] FLOAT (53)    NULL,
    [Position_FacingsWide]  FLOAT (53)    NULL,
    [DOS]                   FLOAT (53)    NULL,
    [DOS_Target_Units]      FLOAT (53)    NULL,
    [Cases_Target_Units]    FLOAT (53)    NULL,
    [Units_Required]        FLOAT (53)    NULL,
    [Dos_Units_Required]    FLOAT (53)    NULL,
    [Facings_Required]      FLOAT (53)    NULL
);


GO

