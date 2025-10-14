CREATE TABLE [dbo].[Sys_Rounded_Recc] (
    [UserID]               INT        NOT NULL,
    [ReportID]             INT        NOT NULL,
    [Category_Code]        INT        NULL,
    [Hierarchy]            INT        NULL,
    [Hierarchy_Code]       INT        NULL,
    [Bays]                 FLOAT (53) NULL,
    [Recc_Bays]            FLOAT (53) NULL,
    [Original_Bays]        FLOAT (53) NULL,
    [Fractional_Part]      FLOAT (53) NULL,
    [Max_Bays]             FLOAT (53) NULL,
    [Min_Bays]             FLOAT (53) NULL,
    [BayRoundingThreshold] FLOAT (53) NULL,
    [Rounded_Value]        FLOAT (53) NULL,
    [Adj]                  FLOAT (53) NULL
);


GO

