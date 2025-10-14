CREATE TABLE [Ver_001].[RVA_UserSettings] (
    [ReportID]           INT            NOT NULL,
    [UserID]             INT            NOT NULL,
    [ParamID]            INT            NOT NULL,
    [BranchNumber]       INT            NULL,
    [ReportName]         NVARCHAR (MAX) NULL,
    [PerfStartDate]      INT            NULL,
    [PerfEndDate]        INT            NULL,
    [MacroSpaceDate]     TEXT           NULL,
    [DisplayGranularity] VARCHAR (5)    NOT NULL,
    [UMDID]              CHAR (15)      NULL
);


GO

