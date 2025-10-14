
CREATE PROCEDURE [ui].[UserManAddUser]
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
    @UserID INT OUTPUT,  -- Output parameter for new UserID
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize output parameters
    SET @SQL_Success = 0;
    SET @SQL_Message = 'There was a problem, user not added.';

    DECLARE @InsertedUsers TABLE (MyID INT); -- Table variable to capture inserted MyID

    -- Insert a new user and capture the new MyID into the table variable
    INSERT INTO Users (MyID, DisplayName, Email, IsOSPAdmin, Status, FunctionalUser, AdminUser, BlockAccess, O365Email, MFA_Mobile, ColourMode, HierarchyMaintenance)
    OUTPUT INSERTED.MyID INTO @InsertedUsers(MyID) -- Capture the newly inserted MyID into the table variable
    VALUES (
        (SELECT MAX(CAST(MyID AS INT)) + 1 FROM Users),  -- Auto-generate MyID by incrementing the current maximum
        @DisplayName,
        @Email,
        @IsOSPAdmin,
        @Status,
        ISNULL(@FunctionalUserStatus, 0),  -- Default FunctionalUser to 0 if not provided
        @AdminUser,
        @BlockAccess,
        @O365Email,
        @MFA_Mobile,
        @ColourMode,
        @HierarchyMaintenance
    );

    -- Set the output UserID
    SELECT @UserID = MyID FROM @InsertedUsers;

    -- Set success output parameters for user addition
    SET @SQL_Success = 1;
    SET @SQL_Message = 'New user added successfully with UserID = ' + CAST(@UserID AS NVARCHAR(10));
END;

GO

