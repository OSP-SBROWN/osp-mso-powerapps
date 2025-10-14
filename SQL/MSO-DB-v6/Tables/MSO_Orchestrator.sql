CREATE TABLE [dbo].[MSO_Orchestrator] (
    [OrchID]            INT           IDENTITY (1, 1) NOT NULL,
    [UserID]            INT           NOT NULL,
    [ReportID]          INT           NOT NULL,
    [IdentID]           INT           NOT NULL,
    [IsValid]           BIT           NULL,
    [IsFetched]         BIT           NULL,
    [IsCalculated]      BIT           NULL,
    [IsDeleted]         BIT           NULL,
    [IsRestored]        BIT           NULL,
    [CreateDate]        DATETIME      NULL,
    [LastFetchdataDate] DATETIME      NULL,
    [DeletedDate]       DATETIME      NULL,
    [RestoredDate]      DATETIME2 (7) NULL
);
GO

