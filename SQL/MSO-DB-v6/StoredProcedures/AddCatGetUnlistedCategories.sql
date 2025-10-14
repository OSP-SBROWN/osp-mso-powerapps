CREATE   PROCEDURE [ui].[AddCatGetUnlistedCategories]
    @ReportID INT,
    @SQL_Success INT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = 'Sorry, there was a problem, it looks like you haven''t created core tables for this report yet. Please execute the report and try again.';

    -- Declare the output table structure
    DECLARE @OutputTable TABLE (
        Hierarchy1_ID INT,
        Hierarchy1_Code NVARCHAR(50),
        Hierarchy1_Name NVARCHAR(255),
        Hierarchy2_ID INT,
        Hierarchy2_Code NVARCHAR(50),
        Hierarchy2_Name NVARCHAR(255),
        Hierarchy3_ID INT,
        Hierarchy3_Code INT,
        Hierarchy3_Name NVARCHAR(255)
    );



    BEGIN
       --Insert into output table from HierarchyFull where Hierarchy3_Code is not in the Category_Code list
        INSERT INTO @OutputTable
        SELECT 
            hf.Hierarchy1_ID,
            hf.Hierarchy1_Code,
            hf.Hierarchy1_Name,
            hf.Hierarchy2_ID,
            hf.Hierarchy2_Code,
            hf.Hierarchy2_Name,
            hf.Hierarchy3_ID,
            hf.Hierarchy3_Code,
            hf.Hierarchy3_Name
        FROM 
            HierarchyFull hf
        WHERE 
            hf.Hierarchy3_Code NOT IN (
                SELECT DISTINCT Category_Code
FROM MSO_Reports
WHERE ReportID=@ReportID
            );

        -- Get the row count
        DECLARE @RowCount INT;
        SET @RowCount = (SELECT COUNT(*) FROM @OutputTable);

        -- Check if any rows were returned
        IF @RowCount > 0
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = 'Success, ' + CAST(@RowCount AS NVARCHAR(10)) + ' unlisted categories returned.';
        END
        ELSE
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'No unlisted categories found.';
        END
    END

    -- Return the result
    SELECT * FROM @OutputTable;
END

GO

