
CREATE PROCEDURE [ui].[UserManDelete] -- Corrected bracket here
    @UserID INT,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = 'There was a problem deleting the user.';

    -- Check if there are reports associated with the UserID in ReportVersionAttributes
    DECLARE @ReportCount INT;
    SELECT @ReportCount = COUNT(*)
    FROM ReportVersionAttributes
    WHERE ReportOwner = @UserID;

    IF @ReportCount > 0
    BEGIN
        -- Return message if the user has reports under their ownership
        SET @SQL_Success = 0;
        SET @SQL_Message = 'This user cannot be deleted, as there are live reports under their ownership.';
        RETURN;
    END

    -- Check if the user exists in the Users table
    IF EXISTS (SELECT 1 FROM Users WHERE MyID = @UserID)
    BEGIN
        -- Delete the user
        DELETE FROM Users WHERE MyID = @UserID;

        -- Return success message
        SET @SQL_Success = 1;
        SET @SQL_Message = 'User deleted successfully.';
    END
    ELSE
    BEGIN
        -- Return error message if user not found
        SET @SQL_Success = 0;
        SET @SQL_Message = 'User not found.';
    END
END;

GO

