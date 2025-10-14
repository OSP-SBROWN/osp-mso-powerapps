
CREATE PROCEDURE [ui].[ReportsGetDetails]
    @ReportOwnerID VARCHAR(50),
    @IncludeArchived INT,
    @ClusterFilterID INT = 0,
    @LocationFilterID INT = 0,
    @FreetextSearch VARCHAR(255) = NULL,  -- Optional
    @Filter_ReportName VARCHAR(255) = NULL,  -- New filter
    @Filter_ReportOwnerName VARCHAR(255) = NULL,  -- New filter
    @Filter_LocCode INT = NULL,  -- New filter
    @Filter_LocName VARCHAR(255) = NULL,  -- New filter
    @ReportID INT = NULL, -- New filter
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = 'There was an issue retrieving report details.';

    -- Create a table variable to store the results
    DECLARE @ReportResults TABLE (
ReportID INT,
        ReportOwner VARCHAR(50),
        BranchNumber INT,
        ReportName VARCHAR(255),
        ReportOwnerName VARCHAR(255),
        LocationName VARCHAR(255),
        Granularity VARCHAR(32),          -- moved before Status and widened
        Status VARCHAR(25),
        LastRefreshed NVARCHAR(10),
        CoreRowCount INT
    );

    -- Dynamic SQL query
    DECLARE @Sql NVARCHAR(MAX) = N'
    SELECT 
        r.ReportID,
        r.ReportOwner,
        r.BranchNumber,
        r.ReportName,
        u.DisplayName AS ReportOwnerName,
        l.Location_Name AS LocationName,
        r.ViewbyStoreTempcatDept AS Granularity,
        r.Status,
        CONVERT(NVARCHAR(10), r.LastRefreshed, 103) AS LastRefreshed,
        (SELECT COUNT(*) 
         FROM sys.tables 
         WHERE name = ''C_StoreCategory_'' + CAST(r.ReportID AS NVARCHAR(10))) AS CoreRowCount
    FROM 
        ReportVersionAttributes r
    JOIN 
        Users u ON r.ReportOwner = u.MyID
    JOIN
        Locations l ON r.BranchNumber = l.Location_Code
    WHERE 1 = 1';

    -- Apply filters dynamically
    IF @ReportOwnerID <> 'All'
        SET @Sql = @Sql + ' AND r.ReportOwner = @ReportOwnerID';

    IF @IncludeArchived = 0
        SET @Sql = @Sql + ' AND r.Status <> ''Archive''';

    IF @ClusterFilterID <> 0
        SET @Sql = @Sql + ' AND l.Location_ClusterID = @ClusterFilterID';

    IF @LocationFilterID <> 0
        SET @Sql = @Sql + ' AND l.Location_ID = @LocationFilterID';

    IF @ReportID IS NOT NULL
        SET @Sql = @Sql + ' AND r.ReportID = @ReportID';

    IF ISNULL(@FreetextSearch, '') <> ''
        SET @Sql = @Sql + ' AND r.ReportName COLLATE SQL_Latin1_General_CP1_CI_AS LIKE ''%'' + @FreetextSearch + ''%''';

    IF ISNULL(@Filter_ReportName, '') <> ''
        SET @Sql = @Sql + ' AND r.ReportName COLLATE SQL_Latin1_General_CP1_CI_AS LIKE ''%'' + @Filter_ReportName + ''%''';

    IF ISNULL(@Filter_ReportOwnerName, '') <> ''
        SET @Sql = @Sql + ' AND u.DisplayName COLLATE SQL_Latin1_General_CP1_CI_AS LIKE ''%'' + @Filter_ReportOwnerName + ''%''';

    IF @Filter_LocCode IS NOT NULL
        SET @Sql = @Sql + ' AND l.Location_Code = @Filter_LocCode';

    IF ISNULL(@Filter_LocName, '') <> ''
        SET @Sql = @Sql + ' AND l.Location_Name COLLATE SQL_Latin1_General_CP1_CI_AS LIKE ''%'' + @Filter_LocName + ''%''';

    -- Execute the SQL
    INSERT INTO @ReportResults
    EXEC sp_executesql @Sql,
        N'@ReportOwnerID VARCHAR(50), 
          @ClusterFilterID INT, 
          @LocationFilterID INT, 
          @FreetextSearch VARCHAR(255), 
          @Filter_ReportName VARCHAR(255), 
          @Filter_ReportOwnerName VARCHAR(255), 
          @Filter_LocCode INT, 
          @Filter_LocName VARCHAR(255),
          @ReportID INT',
        @ReportOwnerID, 
        @ClusterFilterID, 
        @LocationFilterID, 
        @FreetextSearch, 
        @Filter_ReportName, 
        @Filter_ReportOwnerName, 
        @Filter_LocCode, 
        @Filter_LocName,
        @ReportID;

    -- Check the results
    IF EXISTS (SELECT 1 FROM @ReportResults)
    BEGIN
        SET @SQL_Success = 1;
        SET @SQL_Message = CAST((SELECT COUNT(*) FROM @ReportResults) AS NVARCHAR(10)) + ' reports retrieved successfully.';
        SELECT * FROM @ReportResults;
    END
    ELSE
    BEGIN
        SET @SQL_Success = 0;
        SET @SQL_Message = 'No reports found with the specified criteria.';
    END

    SET NOCOUNT OFF;
END;

GO

