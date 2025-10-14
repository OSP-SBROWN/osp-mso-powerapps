CREATE TABLE [dbo].[SqlTemplates] (
    [Version]   INT            NOT NULL,
    [Iteration] INT            NOT NULL,
    [QueryName] NVARCHAR (510) NOT NULL,
    [QueryText] NVARCHAR (MAX) NOT NULL
);


GO

