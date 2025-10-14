
CREATE   PROCEDURE [ui].[New_GetPerfAndMacroDatesForLocation]
(
    @LocationCode INT,
    @SQL_Success  BIT           OUTPUT,
    @SQL_Message  VARCHAR(200)  OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ----------------------------------------------------------------------------
        -- 1) First result set: PerfMax data
        ----------------------------------------------------------------------------
        SELECT DISTINCT
             CAST(Date_ID AS INT) AS Date_ID,
             CONCAT(
                SUBSTRING(CAST(Date_ID AS VARCHAR(10)), 1, 4),  -- First 4 chars = Year
                ', Wk ',
                SUBSTRING(
                    CAST(Date_ID AS VARCHAR(10)), 
                    5, 
                    LEN(CAST(Date_ID AS VARCHAR(10))) - 4         -- Remainder = Week number
                )
             ) AS PerfDateTxt
        FROM dbo.PerfMax
        WHERE Location_Code = @LocationCode
        ORDER BY CAST(Date_ID AS INT) DESC;


        ----------------------------------------------------------------------------
        -- 2) Second result set: MacroSnapShot joined to the vw_Calendar
        --    We return it as (MacroDate, MacroDateINT, MacroDateTxt)
        ----------------------------------------------------------------------------
        SELECT DISTINCT
            ms.Create_Date                         AS MacroDate,
            c.SQL_Date_YYYYMMDD                    AS SQLDate,
            c.DateTxtMed                          AS TextDate
        FROM dbo.MacroSnapShot  AS ms
        JOIN dbo.vw_Calendar    AS c
            ON ms.Create_Date = c.CalendarDate
        WHERE ms.Location_Code = @LocationCode
        ORDER BY ms.Create_Date DESC;


        ----------------------------------------------------------------------------
        -- Indicate success via output parameters
        ----------------------------------------------------------------------------
        SET @SQL_Success = 1;
        SET @SQL_Message = 'Dates retrieved successfully.';

    END TRY
    BEGIN CATCH

        ----------------------------------------------------------------------------
        -- Return placeholder rows for BOTH result sets if an error occurs
        ----------------------------------------------------------------------------

        -- Placeholder for PerfMax result set
        SELECT 
             CAST(NULL AS INT)   AS Date_ID,
             CAST(NULL AS VARCHAR(50)) AS PerfDateTxt;

        -- Placeholder for MacroSnapShot result set
        SELECT
             CAST(NULL AS DATETIME) AS MacroDate,
             CAST(NULL AS INT)      AS SQLDate,
             CAST(NULL AS VARCHAR(50)) AS TextDate;

        ----------------------------------------------------------------------------
        -- Indicate failure and capture the SQL error message
        ----------------------------------------------------------------------------
        SET @SQL_Success = 0;
        SET @SQL_Message = ERROR_MESSAGE();

    END CATCH;
END;

GO

