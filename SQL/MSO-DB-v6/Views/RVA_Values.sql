CREATE VIEW [Ver_001].[RVA_Values] AS
SELECT
us.ReportID,
us.UserID, 
us.BranchNumber,
us.ReportName,
us.PerfStartDate,
us.PerfEndDate,
us.MacroSpaceDate,
us.DisplayGranularity,
us.UMDID,
pa.*
FROM RVA_UserSettings us
JOIN
RVA_Params pa
ON us.ParamID = pa.ParamID

GO

