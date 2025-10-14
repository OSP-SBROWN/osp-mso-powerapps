CREATE   PROCEDURE [ui].[HierMan2_Delete2]
    @Hier2_ID INT,
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

        SELECT @ChildCount = Child_H3
        FROM Hierarchy2_Child
        WHERE Hierarchy2_ID = @Hier2_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        IF @ChildCount IS NULL
        BEGIN
            SET @SQL_Message = 'Failure: Entry not found with the provided ID and version.';
            RETURN;
        END

        IF @ChildCount > 0
        BEGIN
            SET @SQL_Message = 'Deletion aborted: This Hierarchy2 record has associated Hierarchy3 child records.';
            RETURN;
        END

        DELETE FROM Hierarchy2
        WHERE Hierarchy2_ID = @Hier2_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        SET @SQL_Success = 1;
        SET @SQL_Message = 'Success: Entry deleted successfully.';
    END TRY
    BEGIN CATCH
        SET @SQL_Message = 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;

GO

