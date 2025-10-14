CREATE VIEW [dbo].[UMD_Summary] AS
SELECT 
    uvd.UMDVersionName, 
    uvd.UMDID,
    u.DisplayName,
    UMD.UMDRowCount
FROM 
    dbo.UserManagedDataVersion uvd
INNER JOIN 
    dbo.Users u ON uvd.Owner = u.MyID
OUTER APPLY
    (SELECT COUNT(*) AS UMDRowCount
     FROM dbo.[User Managed Data] umd 
     WHERE umd.UMDID = uvd.UMDID) UMD
WHERE 
    UMD.UMDRowCount > 0
GROUP BY 
    uvd.UMDVersionName, 
    uvd.UMDID,
    u.DisplayName,
    UMD.UMDRowCount;

GO

