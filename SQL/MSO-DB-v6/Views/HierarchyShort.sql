CREATE VIEW [dbo].[HierarchyShort] AS
SELECT 
    h3.Hierarchy3_ID, 
    h3.Hierarchy3_Code, 
    h3.Hierarchy3_Name,
    h2.Hierarchy2_Code, 
    h2.Hierarchy2_Name,
    h1.Hierarchy1_Code, h1.Hierarchy1_Name
FROM Hierarchy1 h1
LEFT JOIN Hierarchy2 h2 ON h1.Hierarchy1_ID = h2.ParentHierarchy_ID
LEFT JOIN Hierarchy3 h3 ON h2.Hierarchy2_ID = h3.ParentHierarchy_ID;

GO

