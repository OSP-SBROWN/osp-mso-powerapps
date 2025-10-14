SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ui].[HierMan2_DeleteH3]
    @Hierarchy3_ID            INT,
    @HierarchyVersion_ID      INT,
    @SQL_Success              BIT             OUTPUT,
    @SQL_Message              NVARCHAR(4000)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- init outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = N'';

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------
    IF @Hierarchy3_ID IS NULL OR @Hierarchy3_ID <= 0
    BEGIN
        SET @SQL_Message = N'Hierarchy3_ID must be a positive INT.';
        RETURN;
    END;

    IF @HierarchyVersion_ID IS NULL OR @HierarchyVersion_ID <= 0
    BEGIN
        SET @SQL_Message = N'HierarchyVersion_ID must be a positive INT.';
        RETURN;
    END;

    -- Check if H3 record exists
    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Hierarchy3
        WHERE Hierarchy3_ID = @Hierarchy3_ID
          AND HierarchyVersion_ID = @HierarchyVersion_ID
    )
    BEGIN
        SET @SQL_Message = N'No H3 record found for ID=' + CAST(@Hierarchy3_ID AS NVARCHAR(20)) + N' in version=' + CAST(@HierarchyVersion_ID AS NVARCHAR(20)) + N'.';
        RETURN;
    END;

    ------------------------------------------------------------
    -- Get info for informational message
    ------------------------------------------------------------
    DECLARE @H3Name NVARCHAR(255), @H3Code INT;
    
    SELECT 
        @H3Name = Hierarchy3_Name,
        @H3Code = Hierarchy3_Code
    FROM dbo.Hierarchy3 
    WHERE Hierarchy3_ID = @Hierarchy3_ID 
      AND HierarchyVersion_ID = @HierarchyVersion_ID;

    ------------------------------------------------------------
    -- Delete H3 (no children to cascade)
    ------------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        -- Delete H3 record (leaf node - no children)
        DELETE FROM dbo.Hierarchy3 
        WHERE Hierarchy3_ID = @Hierarchy3_ID 
          AND HierarchyVersion_ID = @HierarchyVersion_ID;

        COMMIT TRAN;

        SET @SQL_Success = 1;
        SET @SQL_Message = 
            N'H3 record deleted successfully. '
          + N'H3="' + ISNULL(@H3Name, N'<NULL>') + N'" (Code=' + CAST(ISNULL(@H3Code, -1) AS NVARCHAR(20)) + N') removed.';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        SET @SQL_Success = 0;
        SET @SQL_Message =
            N'Error ' + CAST(ERROR_NUMBER() AS NVARCHAR(10))
          + N' in ' + ISNULL(ERROR_PROCEDURE(), N'<unknown>')
          + N' at line ' + CAST(ERROR_LINE() AS NVARCHAR(10))
          + N': ' + ERROR_MESSAGE();
    END CATCH

END

GO