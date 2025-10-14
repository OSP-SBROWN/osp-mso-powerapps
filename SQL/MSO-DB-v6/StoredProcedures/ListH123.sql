CREATE   PROCEDURE [ui].[ListH123]
    @HierVer INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    -- Initialize output parameters
    SET @SQL_Success = 0
    SET @SQL_Message = ''

    BEGIN TRY
        -- Select distinct Temp_Category_Number and Temp_Category_Name
        SELECT DISTINCT
            Hierarchy1_Code AS Temp_Category_Number, 
            Hierarchy1_Name AS Temp_Category_Name
        FROM Hierarchy1
        WHERE HierarchyVersion_ID = @HierVer

        -- Select distinct Department_Number and Department_Name
        SELECT DISTINCT
            Hierarchy2_Code AS Department_Number, 
            Hierarchy2_Name AS Department_Name
        FROM Hierarchy2
        WHERE HierarchyVersion_ID = @HierVer

        -- Select distinct Layout_Group_Code and Layout_Group_Name
        SELECT DISTINCT
            Hierarchy3_Code AS Layout_Group_Code, 
            Hierarchy3_Name AS Layout_Group_Name
        FROM Hierarchy3
        WHERE HierarchyVersion_ID = @HierVer 

        -- Set success output parameters
        SET @SQL_Success = 1
        SET @SQL_Message = 'Procedure executed successfully'

    END TRY
    BEGIN CATCH
        -- Set failure output parameters
        SET @SQL_Success = 0
        SET @SQL_Message = 'Error: ' + ERROR_MESSAGE()
        
        -- Optional: You might want to re-throw the error or log it
        -- THROW;
    END CATCH
END

GO

