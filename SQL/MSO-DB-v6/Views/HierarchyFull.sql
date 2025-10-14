CREATE VIEW HierarchyFull AS
SELECT 
    h1.Hierarchy1_ID, h1.Hierarchy1_Code, h1.Hierarchy1_Name,
    h2.Hierarchy2_ID, h2.Hierarchy2_Code, h2.Hierarchy2_Name,
    h3.Hierarchy3_ID, h3.Hierarchy3_Code, h3.Hierarchy3_Name
FROM Hierarchy1 h1
LEFT JOIN Hierarchy2 h2 ON h1.Hierarchy1_ID = h2.ParentHierarchy_ID
LEFT JOIN Hierarchy3 h3 ON h2.Hierarchy2_ID = h3.ParentHierarchy_ID;

GO

