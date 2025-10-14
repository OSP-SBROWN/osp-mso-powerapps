
CREATE VIEW [dbo].[vw_UserManagedData_Staging_WithBothCodes]
AS
SELECT 
    -- UMDID groups this entire dataset as 'dob-v2' 
    'dob-v3' AS UMDID,
    
    -- Location information
    CAST(l.Location_Code AS INT) AS Branch_Number,
    l.Location_Name AS Branch_Name,
    
    -- Generate Layout_Group_Code from Hierarchy3 (CORRECTED!)
    CASE 
        WHEN ISNUMERIC(hd.Hierarchy3_Code) = 1 
        THEN CAST(hd.Hierarchy3_Code AS INT)
        ELSE (ABS(CHECKSUM(hd.Hierarchy3_Code)) % 8999) + 1000
    END AS Layout_Group_Code,
    
    CAST(hd.Hierarchy3_Code AS NVARCHAR(50)) AS Layout_Group_Code_Original,
    hd.Hierarchy3_Name AS Layout_Group_Name,
    
    -- Cohort from Clusters lookup
    COALESCE(c.Cluster_Name, 'All Stores') AS Cohort,
    
    -- Default values
    NULL AS SML,
    CAST(NULL AS INT) AS Max_Lines,
    CAST(NULL AS FLOAT) AS Full_Range_Bays,
    'Y' AS Include_In_Rebalance,
    
    -- Department fields (Hierarchy2)
    CASE 
        WHEN ISNUMERIC(hd.Hierarchy2_Code) = 1 
        THEN CAST(hd.Hierarchy2_Code AS INT)
        ELSE (ABS(CHECKSUM(hd.Hierarchy2_Code)) % 8999) + 1000
    END AS Department_Number,
    
    CAST(hd.Hierarchy2_Code AS NVARCHAR(50)) AS Department_Number_Original,
    NULL AS Department_Sub,
    
    COALESCE(
        CAST(hd.FlowNumber AS INT), 
        ROW_NUMBER() OVER (
            PARTITION BY l.Location_Code 
            ORDER BY hd.Hierarchy1_Code, hd.Hierarchy2_Code, hd.Hierarchy3_Code
        )
    ) AS Flow_Number,
    
    hd.Hierarchy2_Name AS Department_Name,
    
    -- Temperature Category fields (Hierarchy1)
    CASE 
        WHEN ISNUMERIC(hd.Hierarchy1_Code) = 1 
        THEN CAST(hd.Hierarchy1_Code AS INT)
        ELSE (ABS(CHECKSUM(hd.Hierarchy1_Code)) % 8999) + 1000
    END AS Temp_Category_Number,
    
    CAST(hd.Hierarchy1_Code AS NVARCHAR(50)) AS Temp_Category_Number_Original,
    hd.Hierarchy1_Name AS Temp_Category_Name,
    
    -- Target values
    CAST(COALESCE(hd.MinBays, 1) AS FLOAT) AS Min_Bays,
    CAST(COALESCE(hd.MaxBays, 10) AS FLOAT) AS Max_Bays,
    CAST(COALESCE(hd.Trend, 0.0) AS FLOAT) AS Trend,
    COALESCE(hd.Exclude_From_Analysis, 'N') AS Exclude_from_analysis,
    CAST(COALESCE(hd.DOS, 7.0) AS FLOAT) AS DoS_Target,
    CAST(COALESCE(hd.COS, 1.5) AS FLOAT) AS Cases_Target
    
FROM [dbo].[Locations] l
LEFT JOIN [dbo].[Clusters] c ON l.Location_ClusterID = c.Cluster_ID
CROSS JOIN [dbo].[HierarchyDetail] hd
WHERE l.Location_Code IS NOT NULL
  AND hd.Hierarchy3_Code IS NOT NULL;
  -- NO LOCATION FILTER - ALL 69 LOCATIONS INCLUDED!

GO

