CREATE VIEW [dbo].[HierarchyDetail] AS
SELECT
    h1.Hierarchy1_Code,
    h1.Hierarchy1_Name,
    h2.Hierarchy2_Code,
    h2.Hierarchy2_Name,
    h3.Hierarchy3_Code,
    h3.Hierarchy3_Name,
    h3.Trend,
    h3.MinBays,
    h3.MaxBays,
    h3.DOS,
    h3.COS,
    h3.Exclude_From_Analysis,
    h3.FlowNumber,
    h3.BayRoundingThreshold,
    h3.HierarchyVersion_ID
FROM dbo.Hierarchy3 h3
JOIN dbo.Hierarchy2 h2 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
JOIN dbo.Hierarchy1 h1 ON h2.ParentHierarchy_ID = h1.Hierarchy1_ID;

GO

