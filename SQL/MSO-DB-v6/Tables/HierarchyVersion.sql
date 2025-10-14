CREATE TABLE [dbo].[HierarchyVersion] (
    [HierarchyVersion_ID]         INT           IDENTITY (1, 1) NOT NULL,
    [HierarchyVersion_Name]       VARCHAR (255) NULL,
    [HierarchyVersion_CreatedBy]  VARCHAR (255) NULL,
    [HierarchyVersionCreatedDate] DATETIME      NULL,
    [HierarchyVersion_Status]     VARCHAR (50)  NULL
);


GO

