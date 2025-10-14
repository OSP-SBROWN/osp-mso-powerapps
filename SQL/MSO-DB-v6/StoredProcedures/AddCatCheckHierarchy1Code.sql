CREATE   PROCEDURE [ui].[AddCatCheckHierarchy1Code]
    @ProposedH1Code INT,
    @SQL_Success BIT OUTPUT,
    @CodeValid BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ExistingName NVARCHAR(255);
        DECLARE @NextAvailableCode INT;

        -- Check if the ProposedH3Code already exists in the Hierarchy2 table
        SELECT @ExistingName = Hierarchy1_Name
    FROM Hierarchy1
    WHERE Hierarchy1_Code = @ProposedH1Code;

        IF @ExistingName IS NOT NULL
        BEGIN
        -- Code already exists, set output parameters
        SET @CodeValid = 0;

        -- Find the next available Hierarchy2_Code greater than the proposed code
        SELECT @NextAvailableCode = MIN(h1.Hierarchy1_Code + 1)
        FROM Hierarchy1 h1
        WHERE h1.Hierarchy1_Code >= @ProposedH1Code
            AND NOT EXISTS (
                SELECT 1
            FROM Hierarchy1 h2
            WHERE h2.Hierarchy1_Code = h1.Hierarchy1_Code + 1
            );

        SET @SQL_Message = 'This code is already in use for ' + @ExistingName + ', the next available code is ' + CAST(@NextAvailableCode AS NVARCHAR(10));
    END
        ELSE
        BEGIN
        -- Code is not in use, set output parameters
        SET @CodeValid = 1;
        SET @SQL_Message = 'This code is not currently in use, you may proceed.';
    END

        SET @SQL_Success = 1;
    END TRY
    BEGIN CATCH
        -- Handle errors
        SET @SQL_Success = 0;
        SET @CodeValid = 0;
        SET @SQL_Message = 'An error occurred while checking the code: ' + ERROR_MESSAGE();
    END CATCH
END;

GO

