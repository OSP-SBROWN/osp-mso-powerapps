CREATE PROCEDURE [ui].[NEWGetReportData]
    @ReportID INT,
    @Granularity NVARCHAR(1), -- 'D' = Dept, 'T' = Temp, 'S' = Store
    @SQL_Success BIT OUTPUT,
    @SQL_Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Initialize outputs
    SET @SQL_Success = 0;
    SET @SQL_Message = 'Processing started';

    -- Validate the input Granularity
    IF @Granularity NOT IN ('D', 'T', 'S')
    BEGIN
        SET @SQL_Message = 'Invalid Granularity. Use D, T, or S.';
        RETURN;
    END

    -- Check if ReportID exists
    IF NOT EXISTS (SELECT 1 FROM dbo.MSO_Reports WHERE ReportID = @ReportID)
    BEGIN
        SET @SQL_Message = 'ReportID not found in the table.';
        RETURN;
    END

    -- Select based on Granularity
    BEGIN TRY
        IF @Granularity = 'S'
        BEGIN
            SELECT 
                Location_Code,
                Category_Code,
                Category_Name,
                CAST(Department_Number AS INT) AS Department_Number,
                Department_Name,
                CAST(Temp_Category_Number AS INT) AS Temp_Category_Number,
                Temp_Category_Name,
                Flow_Number,
                Exclude_from_analysis,
                Org_Bays AS Bays,
                Store_BaysPerfMix AS BaysPerfMix,
                Store_BaysFlex_PerfMix AS BaysFlex_PerfMix,
                Store_DOSCOS_Bays AS DOSCOS_Bays,
                Store_Bays_Recc AS Bays_Recc,
                Org_Store_Bays_Recc AS Org_Bays_Rec,
                CASE WHEN CAST(Store_Projected_Sales_Quantity AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Store_Projected_Sales_Quantity AS FLOAT) - Sales_Quantity, 2) 
                END AS SalesUnits,
                CASE WHEN CAST(Store_Projected_Sales_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Store_Projected_Sales_Value AS FLOAT) - Sales_Value, 2) 
                END AS SalesValue,
                CASE WHEN CAST(Store_Projected_Profit_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Store_Projected_Profit_Value AS FLOAT) - Profit_Value, 2) 
                END AS Profit,
                CASE WHEN CAST(Store_Projected_Sales_Less_Waste AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Store_Projected_Sales_Less_Waste AS FLOAT) - Sales_Less_Waste, 2) 
                END AS SLW,
                DoS_Target,
                Cases_Target AS Cos_Target,
                Org_Bays_Req_Target AS DoS_Target_Bays
            FROM dbo.MSO_Reports
            WHERE ReportID = @ReportID;
        END
        ELSE IF @Granularity = 'T'
        BEGIN
            SELECT 
                Location_Code,
                Category_Code,
                Category_Name,
                CAST(Department_Number AS INT) AS Department_Number,
                Department_Name,
                CAST(Temp_Category_Number AS INT) AS Temp_Category_Number,
                Temp_Category_Name,
                Flow_Number,
                Exclude_from_analysis,
                Org_Bays AS Bays,
                Temp_BaysPerfMix AS BaysPerfMix,
                Temp_BaysFlex_PerfMix AS BaysFlex_PerfMix,
                Temp_DOSCOS_Bays AS DOSCOS_Bays,
                Temp_Bays_Recc AS Bays_Recc,
                Org_Temp_Bays_Recc AS Org_Bays_Rec,
                CASE WHEN CAST(Temp_Projected_Sales_Quantity AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Temp_Projected_Sales_Quantity AS FLOAT) - Sales_Quantity, 2) 
                END AS SalesUnits,
                CASE WHEN CAST(Temp_Projected_Sales_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Temp_Projected_Sales_Value AS FLOAT) - Sales_Value, 2) 
                END AS SalesValue,
                CASE WHEN CAST(Temp_Projected_Profit_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Temp_Projected_Profit_Value AS FLOAT) - Profit_Value, 2) 
                END AS Profit,
                CASE WHEN CAST(Temp_Projected_Sales_Less_Waste AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Temp_Projected_Sales_Less_Waste AS FLOAT) - Sales_Less_Waste, 2) 
                END AS SLW,
                DoS_Target,
                Cases_Target AS Cos_Target,
                Org_Bays_Req_Target AS DoS_Target_Bays
            FROM dbo.MSO_Reports
            WHERE ReportID = @ReportID;
        END
        ELSE IF @Granularity = 'D'
        BEGIN
            SELECT 
                Location_Code,
                Category_Code,
                Category_Name,
                CAST(Department_Number AS INT) AS Department_Number,
                Department_Name,
                CAST(Temp_Category_Number AS INT) AS Temp_Category_Number,
                Temp_Category_Name,
                Flow_Number,
                Exclude_from_analysis,
                Org_Bays AS Bays,
                Dept_BaysPerfMix AS BaysPerfMix,
                Dept_BaysFlex_PerfMix AS BaysFlex_PerfMix,
                Dept_DOSCOS_Bays AS DOSCOS_Bays,
                Dept_Bays_Recc AS Bays_Recc,
                Org_Dept_Bays_Recc AS Org_Bays_Rec,
                CASE WHEN CAST(Dept_Projected_Sales_Quantity AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Dept_Projected_Sales_Quantity AS FLOAT) - Sales_Quantity, 2) 
                END AS SalesUnits,
                CASE WHEN CAST(Dept_Projected_Sales_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Dept_Projected_Sales_Value AS FLOAT) - Sales_Value, 2) 
                END AS SalesValue,
                CASE WHEN CAST(Dept_Projected_Profit_Value AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Dept_Projected_Profit_Value AS FLOAT) - Profit_Value, 2) 
                END AS Profit,
                CASE WHEN CAST(Dept_Projected_Sales_Less_Waste AS FLOAT) = 0 
                     THEN NULL 
                     ELSE ROUND(CAST(Dept_Projected_Sales_Less_Waste AS FLOAT) - Sales_Less_Waste, 2) 
                END AS SLW,
                DoS_Target,
                Cases_Target AS Cos_Target,
                Org_Bays_Req_Target AS DoS_Target_Bays
            FROM dbo.MSO_Reports
            WHERE ReportID = @ReportID;
        END;

        -- Set success message
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Report data returned successfully.';
    END TRY
    BEGIN CATCH
        -- Handle any errors
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();
    END CATCH
END;

GO

