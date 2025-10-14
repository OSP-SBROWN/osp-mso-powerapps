CREATE TABLE [dbo].[Sys_Rounding] (
    [UserID]               INT        NULL,
    [ReportID]             INT        NULL,
    [Category_Code]        FLOAT (53) NULL,
    [Bays]                 FLOAT (53) NULL,
    [Original_Bays]        FLOAT (53) NULL,
    [Fractional_Part]      FLOAT (53) NULL,
    [Max_Bays]             FLOAT (53) NULL,
    [Min_Bays]             FLOAT (53) NULL,
    [BayRoundingThreshold] FLOAT (53) NULL,
    [Rounded_Value]        FLOAT (53) NULL
);


GO

