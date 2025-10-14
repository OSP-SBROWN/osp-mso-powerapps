
CREATE PROCEDURE [ui].[StoreGenerateStore-NHV1]
    @UserID INT = NULL,
    @ReportID INT = NULL,
    @SQL_Success BIT OUTPUT,
    @SQL_Message VARCHAR(255) OUTPUT,
    @Output_Report NVARCHAR(MAX) OUTPUT
    
AS
BEGIN
    SET NOCOUNT ON;

    SET @SQL_Success = 0;  -- Set as Failure
    SET @SQL_Message = 'This report belongs to another user.  Please duplicate report to your own account and try again';
    SET @Output_Report = '';

    DECLARE @SQL NVARCHAR(MAX) = NULL;
    DECLARE @Template NVARCHAR(MAX);
    DECLARE @Iteration INT = 1;
    DECLARE @Resize_Success BIT;
    DECLARE @Rounding_Success BIT;

    IF @ReportID IS NOT NULL AND (SELECT COUNT(*) FROM ReportVersionAttributes WHERE ReportOwner = @UserID AND ReportID = @ReportID) > 0
    BEGIN
        -- Get & Set variables from ReportVersionAttributes
        DECLARE 
            @UnitSalesMix_UserSet FLOAT = NULL, 
            @ValueSalesMix_UserSet FLOAT = NULL, 
            @ProfitSalesMix_UserSet FLOAT = NULL, 
            @SalesLessWaste_UserSet FLOAT = NULL, 
            @SalesProfitMix_UserSet FLOAT = NULL, 
            @SalesMixCube_UserSet FLOAT = NULL, 
            @DOSCasePack_UserSet FLOAT = NULL, 
            @FixtureDensity_UserSet FLOAT = NULL, 
            @MixIncCohort_UserSet FLOAT = NULL, 
            @ExcludeCategories NVARCHAR(MAX) = NULL,
            @DaysTrading INT = NULL,
            @CubeFlex FLOAT = NULL,
            @MinBayFraction FLOAT = NULL,
            @PotentialSalesAdjustment FLOAT = NULL;
        

        DECLARE @Defaults TABLE (
            UnitSalesMix_UserSet FLOAT, 
            ValueSalesMix_UserSet FLOAT, 
            ProfitSalesMix_UserSet FLOAT, 
            SalesLessWaste_UserSet FLOAT, 
            SalesProfitMix_UserSet FLOAT, 
            SalesMixCube_UserSet FLOAT, 
            DOSCasePack_UserSet FLOAT, 
            FixtureDensity_UserSet FLOAT, 
            MixIncCohort_UserSet FLOAT, 
            ExcludeCategories NVARCHAR(MAX),
            DaysTrading INT,
            CubeFlex FLOAT,
            MinBayFraction FLOAT,
            PotentialSalesAdjustment FLOAT
        );
 
        INSERT INTO @Defaults
        SELECT 
        UnitSalesMix_UserSet, 
        ValueSalesMix_UserSet, 
        ProfitSalesMix_UserSet, 
        SalesLessWaste_UserSet, 
        SalesProfitMix_UserSet, 
        SalesMixCube_UserSet, 
        DOSCasePack_UserSet, 
        FixtureDensity_UserSet, 
        MixIncCohort_UserSet, 
        CASE 
            WHEN ExcludeCategories NOT LIKE '(%)' THEN '(0)'
            ELSE ExcludeCategories 
        END AS ExcludeCategories,
        DaysTrading,
        CubeFlex,
        (RoundBaySize / FullBaySize) AS MinBayFraction,
        PotentialSalesAdjustment
        FROM ReportVersionAttributes
        WHERE ReportID = @ReportID;
 
        SELECT
        @UnitSalesMix_UserSet  = UnitSalesMix_UserSet, 
        @ValueSalesMix_UserSet  = ValueSalesMix_UserSet, 
        @ProfitSalesMix_UserSet  = ProfitSalesMix_UserSet, 
        @SalesLessWaste_UserSet  = SalesLessWaste_UserSet, 
        @SalesProfitMix_UserSet  = SalesProfitMix_UserSet, 
        @SalesMixCube_UserSet  = SalesMixCube_UserSet, 
        @DOSCasePack_UserSet  = DOSCasePack_UserSet, 
        @FixtureDensity_UserSet  = FixtureDensity_UserSet, 
        @MixIncCohort_UserSet  = MixIncCohort_UserSet, 
        @ExcludeCategories = ExcludeCategories,
        @DaysTrading =  DaysTrading,
        @CubeFlex = CubeFlex,
        @MinBayFraction = MinBayFraction,
        @PotentialSalesAdjustment = PotentialSalesAdjustment
        FROM @Defaults;


        --Set start condition by returning Bays to their start value
        UPDATE MSO_Reports
        SET Bays = Org_Bays
        WHERE UserID = @UserID AND ReportID = @ReportID;

        UPDATE MSO_Reports
        SET Exclude_from_analysis = 
            CASE 
                WHEN Exclude_from_analysis > 1 THEN 0
                ELSE Exclude_from_analysis
            END
        WHERE UserID = @UserID 
        AND ReportID = @ReportID;


        --Set RVA variables
        UPDATE MSO_Reports
        SET
        UnitSalesMix_UserSet = @UnitSalesMix_UserSet,
        ValueSalesMix_UserSet = @ValueSalesMix_UserSet,
        ProfitSalesMix_UserSet = @ProfitSalesMix_UserSet,
        SalesLessWaste_UserSet  = @SalesLessWaste_UserSet,
        SalesProfitMix_UserSet  = @SalesProfitMix_UserSet,
        SalesMixCube_UserSet  = @SalesMixCube_UserSet,
        DOSCasePack_UserSet  = @DOSCasePack_UserSet,
        FixtureDensity_UserSet = @FixtureDensity_UserSet,
        MixIncCohort_UserSet = @MixIncCohort_UserSet
        WHERE UserID = @UserID AND ReportID = @ReportID AND Exclude_from_analysis = 0;

        -- Fetch and Apply override values from BayRules
        DECLARE @OverrideRules TABLE (
            Granularity NVARCHAR(10),
            Gran_Code NVARCHAR(50),
            ApplyColumn NVARCHAR(50),
            ValueToSet NVARCHAR(MAX),
            Var_or_Col NVARCHAR(50),
            Group_Key NVARCHAR(50)
        );

        -- Populate the override rules
        INSERT INTO @OverrideRules
        SELECT 
            Granularity, 
            Gran_Code, 
            ApplyColumn, 
            CASE 
                WHEN Group_Key = 'Exclude' THEN '3' -- Set ValueToSet to 1 if Group_Key is 'Exclude'
                ELSE ValueToSet 
            END AS ValueToSet,
            Var_or_Col, 
            Group_Key 
        FROM BayRules 
        WHERE ReportID = @ReportID 
        AND Group_Key IN ('Drivers', 'Driver', 'Metrics', 'Exclude', 'Rounding', 'InputOverrides', 'AddCategory');

        -- Variables for cursor processing
        DECLARE @Granularity NVARCHAR(10);
        DECLARE @Gran_Code NVARCHAR(50);
        DECLARE @ApplyColumn NVARCHAR(50);
        DECLARE @ValueToSet NVARCHAR(MAX);

        -- Check if there are override rules to process
        IF (SELECT COUNT(*) FROM @OverrideRules) > 0
        BEGIN
            -- Cursor to iterate over each override rule
            DECLARE OverrideCursor CURSOR FOR
            SELECT Granularity, Gran_Code, ApplyColumn, ValueToSet
            FROM @OverrideRules;

            OPEN OverrideCursor;

            FETCH NEXT FROM OverrideCursor INTO @Granularity, @Gran_Code, @ApplyColumn, @ValueToSet;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Build the dynamic SQL for the current rule
                SET @SQL = 
                    'UPDATE MSO_Reports SET ' + QUOTENAME(@ApplyColumn) + ' = ' + 
                    CASE 
                        WHEN @ApplyColumn = 'Exclude_from_analysis' THEN QUOTENAME(@ValueToSet, '''') 
                        ELSE @ValueToSet 
                    END +
                    ' WHERE UserID = @UserID AND ReportID = @ReportID AND ' +
                    CASE 
                        WHEN @Granularity = 'C' THEN 'Category_Code' 
                        WHEN @Granularity = 'D' THEN 'Department_Number' 
                        WHEN @Granularity = 'T' THEN 'Temp_Category_Number' 
                    END + ' = ' + @Gran_Code + ';';

                -- Execute the generated SQL
                EXEC sp_executesql @SQL, N'@UserID INT, @ReportID INT', @UserID = @UserID, @ReportID = @ReportID;


                -- Move to the next rule
                FETCH NEXT FROM OverrideCursor INTO @Granularity, @Gran_Code, @ApplyColumn, @ValueToSet;
            END

            CLOSE OverrideCursor;
            DEALLOCATE OverrideCursor;

            -- Update the output report
            SET @Output_Report = @Output_Report + 'Overrides applied;';
        END
        ELSE
        BEGIN
            -- No overrides to process
            SET @Output_Report = @Output_Report + 'No Overrides requested;';
        END

       -- Test if any Bay resize have been set and execute them
        IF (SELECT COUNT(*) FROM BayRules WHERE ReportID = @ReportID AND Group_Key = 'Resize') > 0
        BEGIN
            EXEC dbo.StoreResizeLogic
                @UserID = @UserID,
                @ReportID = @ReportID,
                @Resize_Success = @Resize_Success OUTPUT;
            IF @Resize_Success = 0
            BEGIN
                SET @Output_Report = @Output_Report + ' Store Resize Failed;';
            END
            ELSE
            BEGIN
                SET @Output_Report = @Output_Report + ' Store Resizes applied;';            
            END
        END
        ELSE
        BEGIN
            SET @Output_Report = @Output_Report + ' No Resizes requested;';       
        END
        
        -- Check and correct format of ExcludeCategories value from RVA
        IF @ExcludeCategories = '()' 
        OR @ExcludeCategories = '0' 
        OR @ExcludeCategories = '' 
        OR @ExcludeCategories IS NULL
        BEGIN
            SET @ExcludeCategories = '(0)'
        END

        IF @ExcludeCategories NOT LIKE'(%)'
        BEGIN
            SET @ExcludeCategories = '(' + @ExcludeCategories + ')'
        END

        DECLARE sql_cursor CURSOR FOR 
        SELECT Iteration, QueryText 
        FROM SqlTemplates 
        WHERE QueryName NOT LIKE 'project%'
        AND [Version] = 2
        ORDER BY Iteration;

        OPEN sql_cursor;
        FETCH NEXT FROM sql_cursor INTO @Iteration, @Template;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = REPLACE(@Template, 'EXCLUDE_CATEGORIES_PLACEHOLDER', @ExcludeCategories);

            EXEC sp_executesql @SQL, 
                N'
                @UserID INT, @ReportID INT,@UnitSalesMix_UserSet FLOAT,@ValueSalesMix_UserSet FLOAT,@ProfitSalesMix_UserSet FLOAT,@SalesLessWaste_UserSet FLOAT,@SalesProfitMix_UserSet FLOAT,
                @SalesMixCube_UserSet FLOAT,@DOSCasePack_UserSet FLOAT,@FixtureDensity_UserSet FLOAT,@MixIncCohort_UserSet FLOAT,@DaysTrading INT,@CubeFlex FLOAT',
                @UserID,@ReportID,@UnitSalesMix_UserSet,@ValueSalesMix_UserSet,@ProfitSalesMix_UserSet,@SalesLessWaste_UserSet,@SalesProfitMix_UserSet, 
                @SalesMixCube_UserSet,@DOSCasePack_UserSet,@FixtureDensity_UserSet,@MixIncCohort_UserSet,@DaysTrading,@CubeFlex;
            
            FETCH NEXT FROM sql_cursor INTO @Iteration, @Template;
        END
        CLOSE sql_cursor;
        DEALLOCATE sql_cursor;


        EXEC [dbo].[StoreRounding]
            @ReportID,
            @UserID,
            @MinBayFraction,
            @Rounding_Success = @Rounding_Success OUTPUT;

        IF @Rounding_Success = 1
        BEGIN
            SET @Output_Report = @Output_Report + ' Rounding succeeded;';
        END
        ELSE
        BEGIN
            SET @Output_Report = @Output_Report + ' Rounding failed;';
        END;

        
        WITH storeRecc AS (
        SELECT
        Category_Code,
        Rounded_Value
        FROM
        Sys_Rounded_Recc 
        WHERE Hierarchy = 3 AND ReportID = @ReportID AND UserID = @UserID
        ),
        deptRecc AS (
        SELECT
        Category_Code,
        Rounded_Value
        FROM
        Sys_Rounded_Recc 
        WHERE Hierarchy = 2 AND ReportID = @ReportID AND UserID = @UserID    
        ),
        tempRecc AS (
        SELECT
        Category_Code,
        Rounded_Value
        FROM
        Sys_Rounded_Recc 
        WHERE Hierarchy = 1 AND ReportID = @ReportID AND UserID = @UserID
        )
        UPDATE mr
        SET
            Store_Bays_Recc = sr.Rounded_Value,
            Dept_Bays_Recc = dr.Rounded_Value,
            Temp_Bays_Recc = tr.Rounded_Value
        FROM MSO_Reports mr
        JOIN storeRecc sr ON mr.Category_Code = sr.Category_Code
        JOIN deptRecc dr ON mr.Category_Code = dr.Category_Code
        JOIN tempRecc tr ON mr.Category_Code = tr.Category_Code
        WHERE UserID = @UserID AND ReportID = @ReportID;

        DECLARE sql_cursor CURSOR FOR 
        SELECT Iteration, QueryText 
        FROM SqlTemplates 
        WHERE QueryName LIKE 'project%'
        AND [Version] = 2
        ORDER BY Iteration;

        OPEN sql_cursor;
        FETCH NEXT FROM sql_cursor INTO @Iteration, @Template;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Assign the fetched query text to @SQL
            SET @SQL = @Template;

            -- Execute the current SQL statement
            EXEC sp_executesql @SQL, 
                N'@UserID INT, @ReportID INT, @PotentialSalesAdjustment FLOAT', 
                @UserID, @ReportID, @PotentialSalesAdjustment;

            -- Fetch the next query
            FETCH NEXT FROM sql_cursor INTO @Iteration, @Template;
        END

        CLOSE sql_cursor;
        DEALLOCATE sql_cursor;

    SET @SQL_Success = 1;
    SET @SQL_Message = 'Store build completed succesfully';
    SET NOCOUNT OFF;
    END
END

GO

