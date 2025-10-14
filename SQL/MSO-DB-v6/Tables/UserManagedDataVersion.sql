CREATE TABLE [dbo].[UserManagedDataVersion] (
    [UMDID]          VARCHAR (15)  NOT NULL,
    [UMDVersionName] VARCHAR (255) NULL,
    [Owner]          VARCHAR (2)   NULL,
    [Blobfile]       VARCHAR (999) NULL,
    [Upload]         CHAR (1)      NULL,
    [Date]           DATE          NULL
);


GO

