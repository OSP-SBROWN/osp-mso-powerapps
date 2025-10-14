CREATE TABLE [dbo].[MSO_Debug] (
    [OrchID]      INT            NOT NULL,
    [DebugID]     INT            IDENTITY (1, 1) NOT NULL,
    [CreateDate]  DATETIME       NULL,
    [Layer]       NVARCHAR (100) NULL,
    [StoredProc]  NVARCHAR (100) NULL,
    [DebugReport] NVARCHAR (MAX) NULL,
    [DebugLine]   INT            NULL
);


GO

