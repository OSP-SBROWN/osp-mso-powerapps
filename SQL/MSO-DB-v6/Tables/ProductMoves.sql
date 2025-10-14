CREATE TABLE [dbo].[ProductMoves] (
    [MoveID]              INT IDENTITY (1, 1) NOT NULL,
    [ProductCode]         INT NOT NULL,
    [SourceCategory]      INT NOT NULL,
    [DestinationCategory] INT NOT NULL,
    [ReportID]            INT NOT NULL,
    [UserID]              INT NOT NULL
);


GO

