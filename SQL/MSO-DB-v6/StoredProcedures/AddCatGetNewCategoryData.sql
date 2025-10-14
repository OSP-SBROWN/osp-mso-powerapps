CREATE   PROCEDURE [ui].[AddCatGetNewCategoryData]
    @CategoryCode INT,
    @ClusterNumber INT,
    @SQL_Message NVARCHAR(255) OUTPUT,  -- Output parameter to return the success/failure message
    @SQL_Success INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @SQL_Success = 1;

    -- Declare variables
    DECLARE @ResultCode INT = 0;  -- Default to success
    DECLARE @ClusterID NVARCHAR(2);
    DECLARE @ProjTable NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RowCount INT;  -- Variable to store the number of rows returned

    -- Create a table variable to store the result set
    DECLARE @CategoryDataResults TABLE (
        Location_Name NVARCHAR(255),
        Location_Code INT,
        Category_Code INT,
        Bays INT,
        Sales_Quantity INT,
        Sales_Value DECIMAL(18, 2),
        Profit_Value DECIMAL(18, 2),
        Sales_Less_Waste DECIMAL(18, 2)
    );

    -- Get the max Create_Date and Cluster information
    WITH MaxDate AS (
        SELECT MAX(Create_Date) AS MaxCreateDate
        FROM MacroSnapShot
    ),
    LocData AS (
        SELECT ss.Location_Code
        FROM MacroSnapShot ss
        JOIN MaxDate md
            ON ss.Create_Date = md.MaxCreateDate
        WHERE ss.Category_Code = @CategoryCode
    ),
    ClusData AS (
        SELECT ld.Location_Code, ls.Location_ClusterID
        FROM Locations ls
        JOIN LocData ld
            ON ld.Location_Code = ls.Location_Code
    ),
    ClusterRank AS (
        SELECT 
            Location_ClusterID,
            COUNT(Location_ClusterID) AS Cluster_Cnt
        FROM ClusData
        GROUP BY Location_ClusterID
    )
    
    -- Assign the ClusterID based on the existence of @ClusterNumber
    SELECT TOP 1 @ClusterID = CAST(Location_ClusterID AS NVARCHAR(2))
    FROM ClusterRank
    WHERE Location_ClusterID = @ClusterNumber
    OR (Location_ClusterID = (SELECT TOP 1 Location_ClusterID FROM ClusterRank ORDER BY Cluster_Cnt DESC) AND @ClusterNumber = 0);

    -- Build the table name dynamically
    SET @ProjTable = 'ProjBaysLocs_' + @ClusterID;

    -- Check if the table exists
    IF OBJECT_ID(@ProjTable, 'U') IS NOT NULL
    BEGIN
        -- Build the dynamic SQL query
        SET @SQL = N'
        SELECT
            l.Location_Name,
            c.Location_Code,
            c.Category_Code,
            c.Bays,
            c.Sales_Quantity,
            c.Sales_Value,
            c.Profit_Value,
            c.Sales_Less_Waste
        FROM ' + @ProjTable + ' c
        JOIN Locations l
        ON c.Location_Code = l.Location_Code
        WHERE c.Category_Code = @CategoryCode' 
        + CASE WHEN @ClusterNumber <> 0 THEN ' AND l.Location_ClusterID = @ClusterNumber' ELSE '' END + '
        ORDER BY Location_Name;
        ';

        -- Execute the dynamic SQL and insert the result into the table variable
        INSERT INTO @CategoryDataResults (Location_Name, Location_Code, Category_Code, Bays, Sales_Quantity, Sales_Value, Profit_Value, Sales_Less_Waste)
        EXEC sp_executesql @SQL, N'@CategoryCode INT, @ClusterNumber INT', @CategoryCode = @CategoryCode, @ClusterNumber = @ClusterNumber;

        -- Get the row count
        SET @RowCount = @@ROWCOUNT;

        -- Check if any rows were returned
        IF @RowCount > 0
        BEGIN
            -- Set the output message to indicate success with the row count
            SET @SQL_Message = 'Success: ' + CAST(@RowCount AS NVARCHAR(10)) + ' rows found.';
        END
        ELSE
        BEGIN
            -- If no rows were returned, set the output message
            SET @SQL_Message = 'No data found for the given CategoryCode.';
            SET @SQL_Success = 0;
        END
    END
    ELSE
    BEGIN
        -- If the table does not exist, set a failure message
        SET @ResultCode = 200;  -- Indicate failure
        SET @SQL_Message = 'There were no locations found with 
space for that category. Please widen your search, or try a different category.';
        SET @SQL_Success = 1;
    END

    -- Select the results to return to the user
    SELECT * FROM @CategoryDataResults;

    SET NOCOUNT OFF;
END;

GO

