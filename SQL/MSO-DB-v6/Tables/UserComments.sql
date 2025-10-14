CREATE TABLE [dbo].[UserComments] (
    [CommentID]       INT            IDENTITY (1, 1) NOT NULL,
    [Category_Number] INT            NULL,
    [ReportID]        INT            NULL,
    [CommentText]     NVARCHAR (MAX) NULL,
    [OwnerID]         VARCHAR (2)    NULL
);


GO

