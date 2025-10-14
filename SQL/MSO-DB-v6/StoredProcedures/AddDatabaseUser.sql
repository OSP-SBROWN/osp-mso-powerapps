
CREATE   PROCEDURE [ui].[AddDatabaseUser]
    @UserName NVARCHAR(255),
    -- Username (e.g., 'olly.jelly.waitrose@NETORG5905186.onmicrosoft.com')
    @SQL_Success BIT OUTPUT,
    -- 1 for success, 0 for failure
    @SQL_Message NVARCHAR(4000) OUTPUT
-- Success or error message
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);

    BEGIN TRY
        -- Initialize output parameters
        SET @SQL_Success = 0;
        SET @SQL_Message = 'Starting user creation process. ';

        -- Check if user exists and drop if necessary
        IF EXISTS (SELECT 1
    FROM sys.database_principals
    WHERE name = @UserName)
        BEGIN
        DECLARE @DropUserSQL NVARCHAR(MAX);
        SET @DropUserSQL = N'DROP USER [' + @UserName + N']';
        EXEC sp_executesql @DropUserSQL;
        SET @SQL_Message = @SQL_Message + 'Existing user dropped successfully. ';
    END

        -- Create the new user
        DECLARE @CreateUserSQL NVARCHAR(MAX);
        SET @CreateUserSQL = N'CREATE USER [' + @UserName + N'] FROM EXTERNAL PROVIDER WITH DEFAULT_SCHEMA=[dbo]';
        EXEC sp_executesql @CreateUserSQL;
        SET @SQL_Message = @SQL_Message + 'User created successfully. ';

        -- Assign user to db_datareader
        DECLARE @AddReaderRoleSQL NVARCHAR(MAX);
        SET @AddReaderRoleSQL = N'ALTER ROLE db_datareader ADD MEMBER [' + @UserName + N']';
        EXEC sp_executesql @AddReaderRoleSQL;
        SET @SQL_Message = @SQL_Message + 'User added to db_datareader role. ';

        -- Assign user to db_datawriter
        DECLARE @AddWriterRoleSQL NVARCHAR(MAX);
        SET @AddWriterRoleSQL = N'ALTER ROLE db_datawriter ADD MEMBER [' + @UserName + N']';
        EXEC sp_executesql @AddWriterRoleSQL;
        SET @SQL_Message = @SQL_Message + 'User added to db_datawriter role. ';

        -- Grant EXECUTE permission on all stored procedures
        DECLARE @GrantExecSQL NVARCHAR(MAX);
        SET @GrantExecSQL = N'GRANT EXECUTE TO [' + @UserName + N']';
        EXEC sp_executesql @GrantExecSQL;
        SET @SQL_Message = @SQL_Message + 'User granted EXECUTE permission successfully.';

        -- Set success flag
        SET @SQL_Success = 1;
    END TRY

    BEGIN CATCH
        -- Capture and return error details
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @SQL_Success = 0;
        SET @SQL_Message = 'Error: ' + @ErrorMessage;
    END CATCH
END;

GO

