CREATE TABLE [dbo].[User Managed Data] (
    [UMDID]                 VARCHAR (255) NULL,
    [Branch_Number]         INT           NULL,
    [Branch_Name]           VARCHAR (255) NULL,
    [Layout_Group_Code]     INT           NULL,
    [Layout_Group_Name]     VARCHAR (255) NULL,
    [Cohort]                VARCHAR (255) NULL,
    [SML]                   VARCHAR (255) NULL,
    [Max_Lines]             FLOAT (53)    NULL,
    [Full_Range_Bays]       FLOAT (53)    NULL,
    [DoS_Target]            FLOAT (53)    NULL,
    [Cases_Target]          FLOAT (53)    NULL,
    [Include_In_Rebalance]  VARCHAR (255) NULL,
    [Department_Number]     INT           NULL,
    [Department_Sub]        VARCHAR (255) NULL,
    [Flow_Number]           FLOAT (53)    NULL,
    [Department_Name]       VARCHAR (255) NULL,
    [Temp_Category_Number]  INT           NULL,
    [Temp_Category_Name]    VARCHAR (255) NULL,
    [Min_Bays]              FLOAT (53)    NULL,
    [Max_Bays]              FLOAT (53)    NULL,
    [Trend]                 FLOAT (53)    NULL,
    [Exclude_from_analysis] VARCHAR (255) NULL
);


GO

