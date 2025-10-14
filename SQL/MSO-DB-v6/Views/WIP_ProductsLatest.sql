CREATE VIEW WIP_ProductsLatest AS
WITH LatestVersions AS (
    SELECT 
        Product_Code,
        MAX(ProductVersionDate) AS LatestVersionDate
    FROM dbo.WIP_Product
    GROUP BY Product_Code
)
SELECT 
    wp.Product_Code,
    wp.ProductVersionNumber,
    wp.ProductVersionDate,
    wp.Product_Name,
    wp.Unit_Height,
    wp.Unit_Width,
    wp.Unit_Depth,
    wp.Tray_Height,
    wp.Tray_Width,
    wp.Tray_Dept,
    wp.Tray_Units_Total,
    wp.Case_Height,
    wp.Case_Width,
    wp.Case_Dept,
    wp.Case_Units_Total,
    wp.Unit_CostPrice,
    wp.Unit_SellPrice,
    wp.Tray_CostPrice,
    wp.Tray_SellPrice,
    wp.Case_CostPrice,
    wp.Case_SellPrice
FROM dbo.WIP_Product wp
INNER JOIN LatestVersions lv
    ON wp.Product_Code = lv.Product_Code
    AND wp.ProductVersionDate = lv.LatestVersionDate;

GO

