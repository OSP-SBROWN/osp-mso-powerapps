CREATE   VIEW dbo.vw_Calendar
AS
WITH
-- Step 1: Create a "numbers" (tally) CTE big enough for ~5 years of days (~1,825 days)
-- We'll generate 2,000 rows by cross joining system objects.
Tally AS
(
    SELECT TOP (2000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM   sys.all_objects AS o1
           CROSS JOIN sys.all_objects AS o2
),

-- Step 2: Determine your start/end boundaries
-- We’ll set the END date to 31-Dec of the current year,
-- and the START date to that same date minus 5 years.
Boundaries AS
(
    SELECT
       EndDate   = CONVERT(date, CONCAT(YEAR(GETDATE()), '-12-31')),
       StartDate = DATEADD(YEAR, -5, CONVERT(date, CONCAT(YEAR(GETDATE()), '-12-31')))
)

-- Step 3: Generate a row per day, then compute columns
SELECT
    /* 
       The "main" date in proper SQL date format 
       (from StartDate + n days, up to EndDate). 
    */
    CalendarDate = DATEADD(DAY, t.n, b.StartDate),

    /* Integer in YYYYMMDD form (e.g. 20250125) */
    SQL_Date_YYYYMMDD = CAST(
        CONVERT(VARCHAR(8), DATEADD(DAY, t.n, b.StartDate), 112) 
        AS INT
    ),

    /* 
       Long date text with ordinal suffix (“st”, “nd”, “rd”, “th”). 
       Example: "25th January 2025" 
    */
    DateTxtLong =
        CAST(DAY(DATEADD(DAY, t.n, b.StartDate)) AS VARCHAR(2))
        + CASE
            WHEN DAY(DATEADD(DAY, t.n, b.StartDate)) IN (11, 12, 13)
                THEN 'th '
            WHEN DAY(DATEADD(DAY, t.n, b.StartDate)) % 10 = 1
                THEN 'st '
            WHEN DAY(DATEADD(DAY, t.n, b.StartDate)) % 10 = 2
                THEN 'nd '
            WHEN DAY(DATEADD(DAY, t.n, b.StartDate)) % 10 = 3
                THEN 'rd '
            ELSE 'th '
          END
        + DATENAME(MONTH, DATEADD(DAY, t.n, b.StartDate)) + ' '
        + CAST(YEAR(DATEADD(DAY, t.n, b.StartDate)) AS VARCHAR(4)),

    /* Medium date text: "25 Jan 2025" */
    DateTxtMed =
          CAST(DAY(DATEADD(DAY, t.n, b.StartDate)) AS VARCHAR(2)) + ' '
        + LEFT(DATENAME(MONTH, DATEADD(DAY, t.n, b.StartDate)), 3) + ' '
        + CAST(YEAR(DATEADD(DAY, t.n, b.StartDate)) AS VARCHAR(4)),

    /* Short date text: "25/01/25" */
    DateTxtShort =
        CONVERT(VARCHAR(8), DATEADD(DAY, t.n, b.StartDate), 3), -- dd/MM/yy

    /* Month name & short version */
    MonthName = DATENAME(MONTH, DATEADD(DAY, t.n, b.StartDate)),
    MonthNameShort = LEFT(DATENAME(MONTH, DATEADD(DAY, t.n, b.StartDate)), 3),
    /* Numeric month (1-12) */
    MonthNumber = MONTH(DATEADD(DAY, t.n, b.StartDate)),

    /* Calendar year (YYYY) */
    CalendarYear = YEAR(DATEADD(DAY, t.n, b.StartDate)),

    /*-------------------------------------------------------------------
      Example: Simple "Financial Year" logic
      - Assume the fiscal year starts in April:
         If Month >= 4 → next fiscal year is CurrentYear+1.
         Otherwise → CurrentYear.
      -------------------------------------------------------------------*/
    FinancialYear = CASE
        WHEN MONTH(DATEADD(DAY, t.n, b.StartDate)) >= 4 
             THEN YEAR(DATEADD(DAY, t.n, b.StartDate)) + 1
        ELSE YEAR(DATEADD(DAY, t.n, b.StartDate))
    END,

    /* Example of a simple "Week Number" for the financial year. 
       Real-world scenarios might shift week counting or define
       "first Monday after date X" etc.  */
    FinancialWeekNumber = DATEPART(WEEK, DATEADD(DAY, t.n, b.StartDate)),

    /* Text version: e.g. "Wk 12" */
    FinancialWeekText = CONCAT('Wk ', DATEPART(WEEK, DATEADD(DAY, t.n, b.StartDate))),

    /* Combined example: "FY2024, Wk 23" */
    CombinedFinYearWeek = CONCAT(
        'FY',
        CASE
            WHEN MONTH(DATEADD(DAY, t.n, b.StartDate)) >= 4 
                THEN YEAR(DATEADD(DAY, t.n, b.StartDate)) + 1
            ELSE YEAR(DATEADD(DAY, t.n, b.StartDate))
        END,
        ', Wk ',
        DATEPART(WEEK, DATEADD(DAY, t.n, b.StartDate))
    )

FROM 
    Tally      AS t
    CROSS JOIN Boundaries AS b
WHERE DATEADD(DAY, t.n, b.StartDate) <= b.EndDate
;
GO

