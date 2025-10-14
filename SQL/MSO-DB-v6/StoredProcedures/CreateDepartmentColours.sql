
CREATE   PROCEDURE [ui].[CreateDepartmentColours]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Step 1: Drop the DepartmentColours table if it exists
        IF OBJECT_ID('[dbo].[DepartmentColours]', 'U') IS NOT NULL
            DROP TABLE [dbo].[DepartmentColours];

        -- Step 2: Create the DepartmentColours table
        CREATE TABLE [dbo].[DepartmentColours] (
            DepartmentNumber INT PRIMARY KEY,
            R INT,
            G INT,
            B INT
        );

        -- Step 3: Insert distinct department numbers and random RGB values into DepartmentColours
        WITH DistinctDepartments AS (
            SELECT DISTINCT Department_Number
            FROM [dbo].[User Managed Data]
        )
        INSERT INTO [dbo].[DepartmentColours] (DepartmentNumber, R, G, B)
        SELECT 
            Department_Number,
            ABS(CHECKSUM(NEWID())) % 255 + 1 AS R,
            ABS(CHECKSUM(NEWID())) % 255 + 1 AS G,
            ABS(CHECKSUM(NEWID())) % 255 + 1 AS B
        FROM 
            DistinctDepartments;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

GO

