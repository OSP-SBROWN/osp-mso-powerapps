CREATE VIEW dbo.Hierarchy1_Child AS
SELECT
    h1.Hierarchy1_ID,
    h1.Hierarchy1_Code,
    h1.Hierarchy1_Name,
    COUNT(DISTINCT h2.Hierarchy2_ID) AS Child_H2,
    COUNT(DISTINCT h3.Hierarchy3_ID) AS Child_H3,
    h1.HierarchyVersion_ID
FROM dbo.Hierarchy1 h1
LEFT JOIN dbo.Hierarchy2 h2 ON h2.ParentHierarchy_ID = h1.Hierarchy1_ID
LEFT JOIN dbo.Hierarchy3 h3 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
GROUP BY h1.Hierarchy1_ID, h1.Hierarchy1_Code, h1.Hierarchy1_Name, h1.HierarchyVersion_ID;

GO

