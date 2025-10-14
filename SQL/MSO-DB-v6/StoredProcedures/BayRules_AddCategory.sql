CREATE   PROCEDURE [ui].[BayRules_AddCategory]
    @ReportID INT,
    @New_Category_Code INT,
    @BaysForNewCategory DECIMAL(5, 1) -- Ensure correct data type here
AS
BEGIN
    -- Convert the decimal value to a string
    DECLARE @BaysForNewCategoryStr VARCHAR(10);
    SET @BaysForNewCategoryStr = CAST(@BaysForNewCategory AS VARCHAR(10));

    -- Check if the row already exists
    IF EXISTS (SELECT 1 
               FROM BayRules
               WHERE ReportID = @ReportID
                 AND Granularity = 'C'
                 AND Gran_Code = @New_Category_Code
                 AND ApplyColumn = 'Bays'
                 AND Var_or_Col = 'C'
                 AND Group_Key = 'AddCategory')
    BEGIN
        -- Update the existing row with the new ValueToSet
        UPDATE BayRules
        SET ValueToSet = @BaysForNewCategoryStr
        WHERE ReportID = @ReportID
          AND Granularity = 'C'
          AND Gran_Code = @New_Category_Code
          AND ApplyColumn = 'Bays'
          AND Var_or_Col = 'C'
          AND Group_Key = 'AddCategory';
    END
    ELSE
    BEGIN
        -- Insert a new row
        INSERT INTO BayRules(ReportID, Granularity, Gran_Code, ApplyColumn, ValueToSet, Var_or_Col, Group_Key)
        VALUES (@ReportID, 'C', @New_Category_Code, 'Bays', @BaysForNewCategoryStr, 'C', 'AddCategory');
    END
END

GO

