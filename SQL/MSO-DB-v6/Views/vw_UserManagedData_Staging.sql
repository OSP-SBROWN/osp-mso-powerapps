
-- =============================================
-- UPDATED Staging View (after table changes)
-- =============================================

CREATE   VIEW [dbo].[vw_UserManagedData_Staging]
AS
SELECT 
    -- Generate UMDID - set to 'dob-v1' for all records
    'dob-v1' AS UMDID,
    
    -- Location/Branch Information - now NVARCHAR(10) in target table
    CAST(l.Location_Code AS NVARCHAR(10)) AS Branch_Number,
    l.Location_Name AS Branch_Name,
    
    -- Layout Group (now stores actual codes as NVARCHAR)
    CAST(hd.Hierarchy1_Code AS NVARCHAR(10)) AS Layout_Group_Code,
    hd.Hierarchy1_Name AS Layout_Group_Name,
    
    -- Default values for missing columns
    'All Stores' AS Cohort,
    'M' AS SML,
    NULL AS Max_Lines,
    NULL AS Full_Range_Bays,
    'Y' AS Include_In_Rebalance,
    
    -- Department Information (now stores actual codes as NVARCHAR)
    CAST(hd.Hierarchy2_Code AS NVARCHAR(10)) AS Department_Number,
    NULL AS Department_Sub,
    
    -- Flow Number with defaults and ordering
    COALESCE(hd.FlowNumber, 
        ROW_NUMBER() OVER (
            ORDER BY hd.Hierarchy1_Code, hd.Hierarchy2_Code, hd.Hierarchy3_Code
        )
    ) AS Flow_Number,
    
    hd.Hierarchy2_Name AS Department_Name,
    
    -- Category Information (now stores actual codes as NVARCHAR)
    CAST(hd.Hierarchy3_Code AS NVARCHAR(10)) AS Temp_Category_Number,
    hd.Hierarchy3_Name AS Temp_Category_Name,
    
    -- Numeric fields with defaults
    COALESCE(hd.MinBays, 0) AS Min_Bays,
    COALESCE(hd.MaxBays, 99) AS Max_Bays,
    COALESCE(hd.Trend, 0) AS Trend,
    COALESCE(hd.Exclude_From_Analysis, 'N') AS Exclude_from_analysis,
    
    -- Target fields
    COALESCE(hd.DOS, 7) AS DoS_Target,
    COALESCE(hd.COS, 1.5) AS Cases_Target
    
FROM [dbo].[Locations] l
CROSS JOIN [dbo].[HierarchyDetail] hd
WHERE l.Location_Code IS NOT NULL
  AND hd.Hierarchy3_Code IS NOT NULL;

GO

