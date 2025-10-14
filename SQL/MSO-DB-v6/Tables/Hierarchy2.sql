CREATE TABLE [dbo].[Hierarchy2] (
    [Hierarchy2_ID]         INT            NOT NULL,
    [Hierarchy2_Code]       INT            NULL,
    [Hierarchy2_Name]       VARCHAR (255)  NULL,
    [ParentHierarchy_ID]    INT            NULL,
    [Trend]                 DECIMAL (5, 3) NULL,
    [MinBays]               DECIMAL (5, 1) NULL,
    [MaxBays]               DECIMAL (5, 1) NULL,
    [DOS]                   DECIMAL (5, 1) NULL,
    [COS]                   DECIMAL (5, 1) NULL,
    [Exclude_From_Analysis] VARCHAR (1)    NULL,
    [BayRoundingThreshold]  DECIMAL (5, 1) NULL,
    [HierarchyVersion_ID]   INT            NOT NULL,
    [Metric1]               INT            NULL,
    [Metric2]               INT            NULL,
    [Metric3]               INT            NULL,
    [Metric4]               INT            NULL,
    [Driver1]               INT            NULL,
    [Driver2]               INT            NULL,
    [Driver3]               INT            NULL,
    [Driver4]               INT            NULL,
    PRIMARY KEY CLUSTERED ([Hierarchy2_ID] ASC),
    CHECK ([Driver1]>=(0) AND [Driver1]<=(100)),
    CHECK ([Driver2]>=(0) AND [Driver2]<=(100)),
    CHECK ([Driver3]>=(0) AND [Driver3]<=(100)),
    CHECK ([Driver4]>=(0) AND [Driver4]<=(100)),
    CHECK ([Metric1]>=(0) AND [Metric1]<=(100)),
    CHECK ([Metric2]>=(0) AND [Metric2]<=(100)),
    CHECK ([Metric3]>=(0) AND [Metric3]<=(100)),
    CHECK ([Metric4]>=(0) AND [Metric4]<=(100)),
    CONSTRAINT [CK_Hierarchy2_Drivers_Sum] CHECK ([Driver1] IS NULL AND [Driver2] IS NULL AND [Driver3] IS NULL AND [Driver4] IS NULL OR [Driver1] IS NOT NULL AND [Driver2] IS NOT NULL AND [Driver3] IS NOT NULL AND [Driver4] IS NOT NULL AND ((([Driver1]+[Driver2])+[Driver3])+[Driver4])=(100)),
    CONSTRAINT [CK_Hierarchy2_Metrics_Sum] CHECK ([Metric1] IS NULL AND [Metric2] IS NULL AND [Metric3] IS NULL AND [Metric4] IS NULL OR [Metric1] IS NOT NULL AND [Metric2] IS NOT NULL AND [Metric3] IS NOT NULL AND [Metric4] IS NOT NULL AND ((([Metric1]+[Metric2])+[Metric3])+[Metric4])=(100)),
    FOREIGN KEY ([ParentHierarchy_ID]) REFERENCES [dbo].[Hierarchy1] ([Hierarchy1_ID])
);


GO

