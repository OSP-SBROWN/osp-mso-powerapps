CREATE   PROCEDURE [ui].[HierMan2_UpdateHierarchyVersion]
    @HierarchyVersion_ID  INT,
    @VersionName          NVARCHAR(255) = NULL,   -- Pass NULL to keep existing value
    @Status               VARCHAR(32)    = NULL,  -- Pass NULL to keep existing value
    @SQL_Success          BIT            OUT,
    @SQL_Message          NVARCHAR(4000) OUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- 1) Check if the hierarchy version exists
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.HierarchyVersion
            WHERE HierarchyVersion_ID = @HierarchyVersion_ID
        )
        BEGIN
            SET @SQL_Success = 0;
            SET @SQL_Message = CONCAT('HierarchyVersion_ID ', @HierarchyVersion_ID, ' was not found.');
            RETURN;
        END

        -- 2) Update only provided fields
        UPDATE dbo.HierarchyVersion
        SET
            HierarchyVersion_Name = COALESCE(@VersionName, HierarchyVersion_Name),
            HierarchyVersion_Status = COALESCE(@Status, HierarchyVersion_Status)
        WHERE HierarchyVersion_ID = @HierarchyVersion_ID;

        -- 3) Return success message
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Success, hierarchy version updated.';
    END TRY
    BEGIN CATCH
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            'Error ', ERROR_NUMBER(), ': ', ERROR_MESSAGE()
        );
    END CATCH
END

GO

