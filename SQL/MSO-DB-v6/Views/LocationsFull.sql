CREATE VIEW LocationsFull AS
SELECT 
    l.Location_ID,
    l.Location_Code,
    l.Location_Name,
    l.Location_ClusterID,
    c.Cluster_Name
FROM 
    Locations l
JOIN 
    Clusters c
ON 
    l.Location_ClusterID = c.Cluster_ID;

GO

