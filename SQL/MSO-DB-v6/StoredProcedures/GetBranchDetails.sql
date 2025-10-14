
CREATE   PROCEDURE [ui].[GetBranchDetails]
    @SQL_Success BIT OUTPUT,
    @SQL_Message VARCHAR(255) OUTPUT
AS
BEGIN
    BEGIN TRY
        DECLARE @BranchCount INT;
        DECLARE @OutputTable TABLE (
            Branch_Number INT,
            Branch_Name VARCHAR(255),
            Cohort VARCHAR(255),
            BranchCountInCohort INT
        );
        
        INSERT INTO @OutputTable
    SELECT 
        Location_Code AS Branch_Number,
        Location_Name AS Branch_Name,
        Cluster_Name AS Cohort,
        1 AS BranchCountInCohort
     FROM LocationsFull;

        
        SET @BranchCount = (SELECT COUNT(*) FROM @OutputTable);
        
        -- Set SQL_Success and SQL_Message output parameters
        IF @BranchCount > 0
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = CONCAT('Success: ', @BranchCount, ' branch(es) included in the output.');
        END
        ELSE
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = 'No branches found for the given UMDID.';
        END

        -- Return the result set
        SELECT * FROM @OutputTable;
    END TRY
    BEGIN CATCH
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();
    END CATCH
END

GO

