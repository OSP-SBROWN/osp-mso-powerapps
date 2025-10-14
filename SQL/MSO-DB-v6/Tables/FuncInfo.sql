CREATE TABLE [dbo].[FuncInfo] (
    [Key]      INT           IDENTITY (1, 1) NOT NULL,
    [UserID]   VARCHAR (2)   NOT NULL,
    [ReportID] INT           NOT NULL,
    [Date]     DATE          NOT NULL,
    [Time]     TIME (7)      NOT NULL,
    [Publish]  INT           NOT NULL,
    [FuncApp]  VARCHAR (50)  NULL,
    [Func]     VARCHAR (50)  NULL,
    [Message]  VARCHAR (249) NULL
);


GO

