CREATE TABLE [dbo].[BugReports] (
    [BugID]          INT           IDENTITY (1, 1) NOT NULL,
    [UserIDReported] VARCHAR (255) NULL,
    [OSP_OwnerID]    VARCHAR (255) NULL,
    [BugStatus]      VARCHAR (255) NULL,
    [BugSummary]     VARCHAR (255) NULL,
    [BugNotes]       TEXT          NULL,
    [BugCreated]     DATETIME      NULL,
    [BugAssigned]    DATETIME      NULL,
    [BugInProgress]  DATETIME      NULL,
    [BugComplete]    DATETIME      NULL,
    [CaseAge]        INT           NULL
);


GO

