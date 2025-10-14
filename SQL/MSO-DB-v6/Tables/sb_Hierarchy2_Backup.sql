CREATE TABLE [dbo].[sb_Hierarchy2_Backup] (
    [Hierarchy2_ID]         INT            IDENTITY (1, 1) NOT NULL,
    [Hierarchy2_Code]       VARCHAR (255)  NULL,
    [Hierarchy2_Name]       VARCHAR (255)  NULL,
    [ParentHierarchy_ID]    INT            NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [MinBays]               DECIMAL (5, 1) NULL,
    [MaxBays]               DECIMAL (5, 1) NULL,
    [DOS]                   DECIMAL (5, 1) NULL,
    [COS]                   DECIMAL (5, 1) NULL,
    [Exclude_From_Analysis] VARCHAR (1)    NULL,
    [BayRoundingThreshold]  DECIMAL (5, 1) NULL,
    [HierarchyVersion_ID]   INT            NOT NULL
);


GO

