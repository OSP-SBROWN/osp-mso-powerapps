CREATE   PROCEDURE [ui].[HierMan2_Delete3]
    @Hier3_ID INT,
    @HierarchyVersion_ID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @SQL_Success = 0;
    SET @SQL_Message = '';

    BEGIN TRY
        IF EXISTS (
            SELECT 1 
            FROM Hierarchy3 
            WHERE Hierarchy3_ID = @Hier3_ID
              AND HierarchyVersion_ID = @HierarchyVersion_ID
        )
        BEGIN
            DELETE FROM Hierarchy3 
            WHERE Hierarchy3_ID = @Hier3_ID
              AND HierarchyVersion_ID = @HierarchyVersion_ID;

            SET @SQL_Success = 1;
            SET @SQL_Message = 'Success: Entry deleted successfully.';
        END
        ELSE
        BEGIN
            SET @SQL_Message = 'Failure: Entry not found with the provided ID and version.';
        END
    END TRY
    BEGIN CATCH
        SET @SQL_Message = 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;

GO

