CREATE TABLE [dbo].[T_1069] (
    [ReportID]           INT            NOT NULL,
    [UMDID]              CHAR (15)      NULL,
    [Cohort]             NVARCHAR (MAX) NULL,
    [MacroSpaceDate]     TEXT           NULL,
    [DoSDefault]         FLOAT (53)     NULL,
    [CasesDefault]       FLOAT (53)     NULL,
    [PerfDateExclusions] NVARCHAR (MAX) NULL,
    [PerfStartDate]      INT            NULL,
    [PerfEndDate]        INT            NULL,
    [UseTrend]           CHAR (1)       NULL,
    [BranchNumber]       INT            NULL,
    [DaysTrading]        INT            NULL
);
GO

