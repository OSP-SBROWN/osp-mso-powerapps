SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_UpdateHierarchyVersion]
    @HierarchyVersion_ID        INT,                        -- required - which version to update
    @VersionName                NVARCHAR(255)    = NULL,    -- new name (optional)
    @Status                     NVARCHAR(50)     = NULL,    -- new status (optional)
    @SQL_Success                BIT              OUTPUT,
    @SQL_Message                NVARCHAR(4000)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- auto-rollback on error

    -- init outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    ------------------------------------------------------------
    -- Basic validation + normalization
    ------------------------------------------------------------
    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID must be a positive INT.';
        RETURN;
    END;

    -- Check if version exists
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.HierarchyVersions 
        WHERE ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'Hierarchy version with ID=' + CAST(@HierarchyVersion_ID AS NVARCHAR(10)) + N' does not exist.';
        RETURN;
    END;

    -- Normalize parameters
    SET @VersionName = NULLIF(LTRIM(RTRIM(@VersionName)), N'');
    SET @Status = NULLIF(LTRIM(RTRIM(@Status)), N'');

    -- Validate status if provided
    IF @Status IS NOT NULL AND @Status NOT IN (N'Draft', N'Active', N'Archived')
    BEGIN
        SET @SQL_Message = N'Status must be ''Draft'', ''Active'', or ''Archived''.';
        RETURN;
    END;

    -- Check for duplicate name (excluding current record)
    IF @VersionName IS NOT NULL AND EXISTS (
        SELECT 1
        FROM dbo.HierarchyVersions 
        WHERE Name = @VersionName
          AND ID <> @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'A hierarchy version with name "' + @VersionName + N'" already exists.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Update hierarchy version
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @OldName NVARCHAR(255);
        DECLARE @OldStatus NVARCHAR(50);
        
        -- Get current values for comparison
        SELECT 
            @OldName = Name,
            @OldStatus = Status
        FROM dbo.HierarchyVersions
        WHERE ID = @HierarchyVersion_ID;

        -- Build dynamic update statement based on provided parameters
        DECLARE @UpdateFields NVARCHAR(500) = N'';
        DECLARE @Changes NVARCHAR(500) = N'';

        IF @VersionName IS NOT NULL
        BEGIN
            SET @UpdateFields = @UpdateFields + N'Name = @VersionName, ';
            IF @OldName <> @VersionName
                SET @Changes = @Changes + N'Name: "' + @OldName + N'" → "' + @VersionName + N'"; ';
        END;

        IF @Status IS NOT NULL
        BEGIN
            SET @UpdateFields = @UpdateFields + N'Status = @Status, ';
            IF @OldStatus <> @Status
                SET @Changes = @Changes + N'Status: "' + @OldStatus + N'" → "' + @Status + N'"; ';
        END;

        -- Always update ModifiedDate
        SET @UpdateFields = @UpdateFields + N'ModifiedDate = GETDATE()';

        -- If no fields to update, return success with no changes message
        IF @VersionName IS NULL AND @Status IS NULL
        BEGIN
            SET @SQL_Success = 1;
            SET @SQL_Message = N'No changes specified for hierarchy version "' + @OldName + N'".';
            COMMIT TRAN;
            RETURN;
        END;

        -- Perform the update
        UPDATE dbo.HierarchyVersions
        SET 
            Name = COALESCE(@VersionName, Name),
            Status = COALESCE(@Status, Status),
            ModifiedDate = GETDATE()
        WHERE ID = @HierarchyVersion_ID;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        
        -- Build success message
        IF LEN(@Changes) > 0
        BEGIN
            SET @SQL_Message = N'Hierarchy version updated successfully. Changes: ' + LEFT(@Changes, LEN(@Changes) - 2) + N'.';
        END
        ELSE
        BEGIN
            SET @SQL_Message = N'Hierarchy version "' + COALESCE(@VersionName, @OldName) + N'" updated successfully (no changes detected).';
        END;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            N'Error ', ERROR_NUMBER(),
            N' at line ', ERROR_LINE(), N': ',
            ERROR_MESSAGE()
        );
        RETURN;
    END CATCH;
END

GO