CREATE TABLE [dbo].[sb_Hierarchy3_Backup] (
    [Hierarchy3_ID]         INT            IDENTITY (1, 1) NOT NULL,
    [Hierarchy3_Code]       VARCHAR (255)  NULL,
    [Hierarchy3_Name]       VARCHAR (255)  NULL,
    [ParentHierarchy_ID]    INT            NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [MinBays]               DECIMAL (5, 1) NULL,
    [MaxBays]               DECIMAL (5, 1) NULL,
    [DOS]                   DECIMAL (5, 1) NULL,
    [COS]                   DECIMAL (5, 1) NULL,
    [Exclude_From_Analysis] VARCHAR (1)    NULL,
    [FlowNumber]            INT            NULL,
    [BayRoundingThreshold]  DECIMAL (5, 1) NULL,
    [HierarchyVersion_ID]   INT            NOT NULL
);


GO

