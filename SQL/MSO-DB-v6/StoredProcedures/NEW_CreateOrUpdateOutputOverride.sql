CREATE   PROCEDURE [ui].[NEW_CreateOrUpdateOutputOverride]
    @ReportID INT,
    @H3Code INT,
    @BaysOverrideValue FLOAT = NULL, -- Optional for 'Delete' action
    @Action NVARCHAR(10),           -- Expected values: 'Insert', 'Update', 'Delete'
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = 'Processing started';

    BEGIN TRY
        -- Handle 'Delete' Action
        IF @Action = 'Delete'
        BEGIN
            -- Validate mandatory parameters
            IF @ReportID IS NULL OR @H3Code IS NULL
            BEGIN
                SET @SQL_Message = 'Delete action requires ReportID and H3Code.';
                RETURN;
            END

            -- Check for an existing row
            IF EXISTS (
                SELECT 1
                FROM BayRules
                WHERE ReportID = @ReportID
                  AND Granularity = 'C'
                  AND Gran_Code = @H3Code
                  AND Group_Key = 'OutputOverrides'
            )
            BEGIN
                -- Delete the existing row
                DELETE FROM BayRules
                WHERE ReportID = @ReportID
                  AND Granularity = 'C'
                  AND Gran_Code = @H3Code
                  AND Group_Key = 'OutputOverrides';

                -- Set success message
                SET @SQL_Success = 1;
                SET @SQL_Message = 'Row deleted successfully.';
            END
            ELSE
            BEGIN
                SET @SQL_Success = 1;
                SET @SQL_Message = 'No matching row found to delete.';
            END

            RETURN;
        END

        -- Handle 'Insert' and 'Update' Actions
        IF @Action IN ('Insert', 'Update')
        BEGIN
            -- Validate mandatory parameters
            IF @ReportID IS NULL OR @H3Code IS NULL OR @BaysOverrideValue IS NULL
            BEGIN
                SET @SQL_Message = 'Insert/Update action requires ReportID, H3Code, and BaysOverrideValue.';
                RETURN;
            END

            -- Check for an existing row
            IF EXISTS (
                SELECT 1
                FROM BayRules
                WHERE ReportID = @ReportID
                  AND Granularity = 'C'
                  AND Gran_Code = @H3Code
                  AND Group_Key = 'OutputOverrides'
            )
            BEGIN
                -- Update the row for 'Update' Action
                IF @Action = 'Update'
                BEGIN
                    UPDATE BayRules
                    SET ValueToSet = @BaysOverrideValue
                    WHERE ReportID = @ReportID
                      AND Granularity = 'C'
                      AND Gran_Code = @H3Code
                      AND Group_Key = 'OutputOverrides';

                    SET @SQL_Success = 1;
                    SET @SQL_Message = 'Row updated successfully.';
                END
            END
            ELSE
            BEGIN
                -- Insert the row for 'Insert' Action
                IF @Action = 'Insert'
                BEGIN
                    INSERT INTO BayRules (ReportID, Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
                    VALUES (@ReportID, 'C', @H3Code, 'Bays', @BaysOverrideValue, 'C', 'OutputOverrides');

                    SET @SQL_Success = 1;
                    SET @SQL_Message = 'Row inserted successfully.';
                END
            END
        END
    END TRY
    BEGIN CATCH
        -- Handle any errors
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();
    END CATCH
END;

GO

