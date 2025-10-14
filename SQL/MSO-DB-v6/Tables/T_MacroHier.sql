CREATE TABLE [dbo].[T_MacroHier] (
    [Location_Code]         INT            NULL,
    [Category_Code]         INT            NULL,
    [Category_Name]         VARCHAR (255)  NULL,
    [Department_Number]     INT            NULL,
    [Department_Name]       VARCHAR (255)  NULL,
    [Flow_Number]           INT            NULL,
    [Temp_Category_Number]  INT            NULL,
    [Temp_Category_Name]    VARCHAR (255)  NULL,
    [DoS_Target]            DECIMAL (5, 1) NULL,
    [Cases_Target]          DECIMAL (5, 1) NULL,
    [Min_Bays]              DECIMAL (5, 1) NULL,
    [Max_Bays]              DECIMAL (5, 1) NULL,
    [BayRoundingThreshold]  DECIMAL (5, 1) NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [Exclude_from_analysis] INT            NOT NULL,
    [Bays]                  FLOAT (53)     NULL
);
GO

