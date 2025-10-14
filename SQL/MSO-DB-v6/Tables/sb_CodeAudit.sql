CREATE TABLE [dbo].[sb_CodeAudit] (
    [Table_Name]     NVARCHAR (50) NULL,
    [Column_Name]    NVARCHAR (50) NULL,
    [Code_Value]     NVARCHAR (50) NULL,
    [Record_Count]   INT           NULL,
    [In_Mapping]     BIT           NULL,
    [Mapped_Integer] INT           NULL
);


GO

