CREATE TABLE [Ver_001].[BayRules_Archive] (
    [DTS]         DATETIME      NULL,
    [ReportID]    INT           NULL,
    [Granularity] CHAR (1)      NULL,
    [Gran_Code]   INT           NULL,
    [ApplyColumn] VARCHAR (MAX) NULL,
    [ValueToSet]  VARCHAR (MAX) NULL,
    [Var_or_Col]  CHAR (1)      NULL,
    [Group_Key]   VARCHAR (50)  NULL
);
GO

