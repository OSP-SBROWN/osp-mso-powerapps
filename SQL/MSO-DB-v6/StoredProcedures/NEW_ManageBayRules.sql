CREATE   PROCEDURE [ui].[NEW_ManageBayRules]
    @ReportID INT,
    @BayRulesLocal NVARCHAR(MAX), -- JSON string containing the rows for BayRules
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Start a transaction
        BEGIN TRANSACTION;

        -- Step 1: Delete rows from BayRules
        DELETE FROM BayRules
        WHERE ReportID = @ReportID;
        --  AND Group_Key IN ('Drivers', 'Metrics', 'Resize', 'Rounding');

        -- Step 2: Parse JSON into a table variable
        DECLARE @BayRulesTable TABLE (
            Granularity NVARCHAR(50),
            Gran_Code INT,
            ApplyColumn NVARCHAR(50),
            ValueToSet NVARCHAR(MAX),
            Var_or_Col NVARCHAR(50),
            Group_Key NVARCHAR(50)
        );

        INSERT INTO @BayRulesTable (Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
        SELECT 
            JSON_VALUE(value, '$.Granularity'),
            JSON_VALUE(value, '$.Gran_Code'),
            JSON_VALUE(value, '$.ApplyColumn'),
            JSON_VALUE(value, '$.ValueToSet'),
            JSON_VALUE(value, '$.Var_or_Col'),
            JSON_VALUE(value, '$.Group_Key')
        FROM OPENJSON(@BayRulesLocal);

        -- Step 3: Insert rows into BayRules
        INSERT INTO BayRules (ReportID, Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
        SELECT 
            @ReportID, 
            Granularity, 
            Gran_Code, 
            ApplyColumn, 
            ValueToSet, 
            Var_or_Col, 
            Group_Key
        FROM @BayRulesTable;

        -- Step 4: Commit the transaction
        COMMIT TRANSACTION;

        -- Set output parameters
        SET @SQL_Success = 1;
        SET @SQL_Message = CONCAT(
            'Success: ', 
            (SELECT COUNT(*) FROM @BayRulesTable), 
            ' rows added to BayRules for ReportID ', @ReportID, '.'
        );

    END TRY
    BEGIN CATCH
        -- Rollback the transaction on error
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capture error message
        SET @SQL_Success = 0;
        SET @SQL_Message = CONCAT(
            'Error: ', 
            ERROR_MESSAGE()
        );
    END CATCH;
END;

GO

