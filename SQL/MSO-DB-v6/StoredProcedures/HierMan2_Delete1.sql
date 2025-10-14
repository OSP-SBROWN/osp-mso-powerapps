CREATE   PROCEDURE [ui].[HierMan2_Delete1]
    @Hier1_ID INT,
    @HierarchyVersion_ID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @SQL_Success = 0;
    SET @SQL_Message = '';

    BEGIN TRY
        DECLARE @ChildCount INT;

        SELECT @ChildCount = Child_H2
        FROM Hierarchy1_Child
        WHERE Hierarchy1_ID = @Hier1_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        IF @ChildCount IS NULL
        BEGIN
            SET @SQL_Message = 'Failure: Entry not found with the provided ID and version.';
            RETURN;
        END

        IF @ChildCount > 0
        BEGIN
            SET @SQL_Message = 'Deletion aborted: This Hierarchy1 record has associated Hierarchy2 child records.';
            RETURN;
        END

        DELETE FROM Hierarchy1 
        WHERE Hierarchy1_ID = @Hier1_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        SET @SQL_Success = 1;
        SET @SQL_Message = 'Success: Entry deleted successfully.';
    END TRY
    BEGIN CATCH
        SET @SQL_Message = 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;

GO

