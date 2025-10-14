
CREATE PROCEDURE [ui].[UserManUpdateUser]
    @UserID INT,  -- Required: The ID of the user to update
    @FunctionalUserStatus INT = NULL,
    @DisplayName VARCHAR(255) = NULL,
    @Email VARCHAR(255) = NULL,
    @IsOSPAdmin BIT = NULL,
    @Status VARCHAR(24) = NULL,
    @AdminUser INT = NULL,
    @BlockAccess INT = NULL,
    @O365Email NVARCHAR(MAX) = NULL,
    @MFA_Mobile VARCHAR(24) = NULL,
    @ColourMode CHAR(1) = 'L',
    @HierarchyMaintenance BIT = NULL,
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = 'There was a problem, user not updated.';

    -- Check if the user exists
    IF NOT EXISTS (SELECT 1 FROM Users WHERE MyID = @UserID)
    BEGIN
        SET @SQL_Message = 'User not found.';
        RETURN;
    END

    -- Validate ColourMode (optional validation rule)
    IF @ColourMode NOT IN ('L', 'D')
    BEGIN
        SET @SQL_Success = 0;
        SET @SQL_Message = 'Invalid ColourMode. Allowed values are ''L'' for Light or ''D'' for Dark.';
        RETURN;
    END

    -- Prepare update statement with dynamic field updates
    UPDATE Users
    SET
        DisplayName = COALESCE(@DisplayName, DisplayName),  -- Update if provided
        Email = COALESCE(@Email, Email),                    -- Update if provided
        IsOSPAdmin = COALESCE(@IsOSPAdmin, IsOSPAdmin),      -- Update if provided
        Status = COALESCE(@Status, Status),                 -- Update if provided
        FunctionalUser = COALESCE(@FunctionalUserStatus, FunctionalUser),  -- Update if provided
        AdminUser = COALESCE(@AdminUser, AdminUser),         -- Update if provided
        BlockAccess = COALESCE(@BlockAccess, BlockAccess),   -- Update if provided
        O365Email = COALESCE(@O365Email, O365Email),        -- Update if provided
        MFA_Mobile = COALESCE(@MFA_Mobile, MFA_Mobile),      -- Update if provided
        ColourMode = COALESCE(@ColourMode, ColourMode),      -- Update if provided
        HierarchyMaintenance = COALESCE(@HierarchyMaintenance, HierarchyMaintenance)  -- Update if provided
    WHERE MyID = @UserID;

    -- Check if the update was successful
    IF @@ROWCOUNT > 0
    BEGIN
        SET @SQL_Success = 1;
        SET @SQL_Message = 'User updated successfully.';
    END
    ELSE
    BEGIN
        SET @SQL_Success = 0;
        SET @SQL_Message = 'No changes were made to the user.';
    END
END;

GO

