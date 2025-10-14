CREATE TABLE [dbo].[UseLog] (
    [UseID]             INT           IDENTITY (1, 1) NOT NULL,
    [UserID]            VARCHAR (2)   NULL,
    [Timestamp]         DATETIME      NULL,
    [Status]            VARCHAR (MAX) NULL,
    [BranchNumber]      INT           NULL,
    [ActionType]        TEXT          NULL,
    [IsOSPUser]         BIT           NULL,
    [ReportID]          INT           NULL,
    [FullStatusMessage] VARCHAR (MAX) NULL,
    [FlowRunTime]       VARCHAR (50)  NULL
);


GO

