CREATE VIEW Cluster_Details AS
SELECT 
    Cluster_ID, 
    Cluster_Name, 
    COUNT(Location_Code) AS Stores_In_Cluster
FROM Clusters
JOIN Locations ON Location_ClusterID = Cluster_ID
GROUP BY 
    Cluster_ID, 
    Cluster_Name;

GO

