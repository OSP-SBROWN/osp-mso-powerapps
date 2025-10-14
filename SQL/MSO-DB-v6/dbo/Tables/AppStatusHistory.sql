CREATE TABLE [dbo].[AppStatusHistory] (
    [StatusID]   INT            IDENTITY (1, 1) NOT NULL,
    [ReportID]   INT            NOT NULL,
    [StatusType] INT            NOT NULL,
    [StatusText] NVARCHAR (MAX) NULL,
    [UserID]     INT            NULL,
    [DateStamp]  DATE           NULL,
    [TimeStamp]  TIME (7)       NULL
);
GO

