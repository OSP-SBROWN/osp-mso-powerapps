CREATE TABLE [dbo].[sb_HierarchyCodeMapping] (
    [Original_Code]       NVARCHAR (50)  NOT NULL,
    [New_Integer_Code]    INT            NOT NULL,
    [Hierarchy_Level]     INT            NOT NULL,
    [Hierarchy_ID]        INT            NOT NULL,
    [Parent_Integer_Code] INT            NULL,
    [Description]         NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([Original_Code] ASC),
    UNIQUE NONCLUSTERED ([New_Integer_Code] ASC)
);


GO

