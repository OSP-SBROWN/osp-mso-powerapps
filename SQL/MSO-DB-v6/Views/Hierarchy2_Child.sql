CREATE VIEW dbo.Hierarchy2_Child AS
SELECT
    h2.Hierarchy2_ID,
    h2.Hierarchy2_Code,
    h2.Hierarchy2_Name,
    h2.ParentHierarchy_ID,
    COUNT(h3.Hierarchy3_ID) AS Child_H3,
    h2.HierarchyVersion_ID
FROM dbo.Hierarchy2 h2
LEFT JOIN dbo.Hierarchy3 h3 ON h3.ParentHierarchy_ID = h2.Hierarchy2_ID
GROUP BY h2.Hierarchy2_ID, h2.Hierarchy2_Code, h2.Hierarchy2_Name, h2.ParentHierarchy_ID, h2.HierarchyVersion_ID;

GO

