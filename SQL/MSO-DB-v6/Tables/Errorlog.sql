CREATE TABLE [dbo].[Errorlog] (
    [Import_Type]   VARCHAR (30)  NULL,
    [Error_Subject] VARCHAR (20)  NULL,
    [Error_Message] VARCHAR (255) NULL,
    [Table_Name]    VARCHAR (50)  NULL,
    [File_Name]     VARCHAR (50)  NULL,
    [Header]        VARCHAR (50)  NULL,
    [Required]      VARCHAR (50)  NULL,
    [Found]         VARCHAR (50)  NULL,
    [Row]           INT           NULL,
    [Value]         VARCHAR (50)  NULL
);


GO

